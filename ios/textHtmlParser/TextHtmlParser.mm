#import "TextHtmlParser.h"
#import "AlignmentEntry.h"
#import "EnrichedTextView.h"
#import "HtmlParser.h"
#import "LinkData.h"
#import "MentionParams.h"
#import "StyleHeaders.h"
#import "StyleUtils.h"
#import "ZeroWidthSpaceUtils.h"
#import <React/RCTLog.h>

@implementation TextHtmlParser

- (instancetype)initWithView:(EnrichedTextView *)view {
  self = [super init];
  _view = view;
  return self;
}

- (void)replaceWholeFromHtml:(NSString *_Nonnull)html {
  @try {
    NSString *normalized =
        [HtmlParser initiallyProcessHtml:html
                       useHtmlNormalizer:_view->useHtmlNormalizer];
    if (normalized == nil) {
      [_view->textView.textStorage
          setAttributedString:[[NSAttributedString alloc]
                                  initWithString:html
                                      attributes:_view->
                                                 defaultTypingAttributes]];
      return;
    }

    NSArray *result = [HtmlParser getTextAndStylesFromHtml:normalized];
    NSString *plainText = result[0];
    NSArray *processedStyles = result[1];
    NSArray *alignments = result[2];

    NSMutableAttributedString *body = [[NSMutableAttributedString alloc]
        initWithString:plainText
            attributes:_view->defaultTypingAttributes];
    [_view->textView.textStorage setAttributedString:body];
    [self applyProcessedStyles:processedStyles];
    [self applyProcessedAlignments:alignments];
  } @catch (NSException *exception) {
    RCTLogWarn(@"[EnrichedTextView]: Failed to parse HTML: (%@), falling back "
               @"to raw input.",
               exception.reason);
    [_view->textView.textStorage
        setAttributedString:[[NSAttributedString alloc]
                                initWithString:html
                                    attributes:_view->defaultTypingAttributes]];
  }
}

- (void)applyProcessedStyles:(NSArray *_Nonnull)processedStyles {
  // Some paragraph styles (codeblock, blockquote, etc.) insert \u200B
  // into empty lines, mutating NSTextStorage length. We need to
  // shift subsequent ranges by this offset.
  NSInteger zeroWidthSpaceOffset = 0;

  // Inline styles collected during the first pass so their applyStyling: can
  // be re-run after all paragraph styles have applied their visual attributes.
  // Each entry is @[style, adjustedRange].
  NSMutableArray *pendingInlineApply = [NSMutableArray array];

  // Paragraph styles call applyStyling: immediately; inline styles
  // defer it so that paragraph visual attributes are already in
  // place when inline styles override them.
  for (NSArray *arr in processedStyles) {
    NSNumber *styleType = (NSNumber *)arr[0];
    StylePair *stylePair = (StylePair *)arr[1];
    StyleBase *style = _view->stylesDict[styleType];
    if (style == nullptr)
      continue;

    NSRange parsedRange = [stylePair.rangeValue rangeValue];
    NSUInteger textLengthBeforeStyleApplied =
        _view->textView.textStorage.string.length;

    // Range must be taking zeroWidthSpaceOffset into consideration
    // because processed styles ranges are relative to only the new text while
    // we need absolute ranges relative to the whole existing text
    NSRange styleRange = NSMakeRange(
        zeroWidthSpaceOffset + parsedRange.location, parsedRange.length);

    if (![StyleUtils handleStyleBlocksAndConflicts:[[style class] getType]
                                             range:styleRange
                                           forHost:_view]) {
      continue;
    }

    if ([styleType isEqualToNumber:@([LinkStyle getType])]) {
      LinkData *linkData = (LinkData *)stylePair.styleValue;
      [((LinkStyle *)style) applyLinkMetaWithData:linkData range:styleRange];
    } else if ([styleType isEqualToNumber:@([MentionStyle getType])]) {
      MentionParams *params = (MentionParams *)stylePair.styleValue;
      [((MentionStyle *)style) applyMentionMeta:params range:styleRange];
    } else if ([styleType isEqualToNumber:@([ImageStyle getType])]) {
      ImageData *imgData = (ImageData *)stylePair.styleValue;
      [((ImageStyle *)style) addImageAtRange:styleRange
                                   imageData:imgData
                               withSelection:NO
                              withDirtyRange:NO];
    } else if ([styleType isEqualToNumber:@([CheckboxListStyle getType])]) {
      NSDictionary *checkboxStates = (NSDictionary *)stylePair.styleValue;
      CheckboxListStyle *cbStyle = (CheckboxListStyle *)style;

      [cbStyle addWithChecked:NO
                        range:styleRange
                   withTyping:NO
               withDirtyRange:NO];

      if (checkboxStates && checkboxStates.count > 0) {
        for (NSNumber *key in checkboxStates) {
          NSUInteger checkboxPosition =
              zeroWidthSpaceOffset + [key unsignedIntegerValue];
          BOOL isChecked = [checkboxStates[key] boolValue];

          if (isChecked) {
            [cbStyle toggleCheckedAt:checkboxPosition withDirtyRange:NO];
          }
        }
      }
    } else {
      [style add:styleRange withTyping:NO withDirtyRange:NO];
    }

    [ZeroWidthSpaceUtils addSpacesIfNeededInHost:_view inRange:styleRange];

    NSInteger delta = _view->textView.textStorage.string.length -
                      textLengthBeforeStyleApplied;

    // Use an adjusted range so that applyStyling covers any ZWS characters that
    // were just inserted by addSpacesIfNeededInHost:inRange:. Without this, a
    // style applied to an empty range {0,0} would call applyStyling on {0,0}
    // even after a ZWS was inserted.
    NSRange adjustedStyleRange = NSMakeRange(
        styleRange.location, styleRange.length + (NSUInteger)MAX(0LL, delta));

    if ([style isParagraph]) {
      [style applyStyling:adjustedStyleRange];
    } else {
      [pendingInlineApply
          addObject:@[ style, [NSValue valueWithRange:adjustedStyleRange] ]];
    }

    // Image shifts are already handled by _precedingImageCount during tag
    // finalization.
    if (delta != 0 && ![styleType isEqualToNumber:@([ImageStyle getType])]) {
      zeroWidthSpaceOffset += delta;
    }
  }

  // Apply visual styling for inline styles
  for (NSArray *entry in pendingInlineApply) {
    StyleBase *style = entry[0];
    NSRange adjustedStyleRange = [((NSValue *)entry[1]) rangeValue];
    [style applyStyling:adjustedStyleRange];
  }
}

- (void)applyProcessedAlignments:(NSArray<AlignmentEntry *> *)alignments {
  AlignmentStyle *alignmentStyle =
      _view.stylesDict[@([AlignmentStyle getType])];

  if (alignmentStyle == nil) {
    return;
  }

  for (AlignmentEntry *entry in alignments) {
    NSRange finalRange = NSMakeRange(entry.range.location, entry.range.length);
    [alignmentStyle addAlignment:entry.alignment
                           range:finalRange
                      withTyping:NO
                  withDirtyRange:NO];
    [alignmentStyle applyStyling:finalRange];
  }
}

@end
