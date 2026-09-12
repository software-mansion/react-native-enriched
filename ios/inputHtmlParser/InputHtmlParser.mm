#import "InputHtmlParser.h"
#import "AlignmentEntry.h"
#import "EnrichedTextInputView.h"
#import "HtmlParser.h"
#import "MaxLengthUtils.h"
#import "StringExtension.h"
#import "StyleHeaders.h"
#import "StyleUtils.h"
#import "TextInsertionUtils.h"
#import <React/RCTLog.h>

@implementation InputHtmlParser {
  EnrichedTextInputView __weak *_input;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  return self;
}

- (void)replaceWholeFromHtml:(NSString *_Nonnull)html {
  // reset the text first and reset typing attributes
  _input->textView.text = @"";
  _input->textView.typingAttributes = _input->defaultTypingAttributes;

  NSInteger capacity = [MaxLengthUtils wholeContentCapacityForHost:_input];

  @try {
    NSArray *parsed = [HtmlParser getTextAndStylesFromHtml:html
                                                    config:_input.config];
    NSArray *processingResult = [self truncateProcessingResult:parsed
                                                    toCapacity:capacity];
    NSString *plainText = (NSString *)processingResult[0];
    NSArray *stylesInfo = (NSArray *)processingResult[1];
    NSArray *alignments = (NSArray *)processingResult[2];

    // set new text
    _input->textView.text = plainText;

    // re-apply the styles
    [self applyProcessedStyles:stylesInfo
           offsetFromBeginning:0
               plainTextLength:plainText.length];
    [self applyProcessedAlignments:alignments offset:0];
    [_input anyTextMayHaveBeenModified];
  } @catch (NSException *exception) {
    RCTLogWarn(@"[EnrichedTextInput]: Failed to parse HTML: (%@), falling back "
               @"to raw input.",
               exception.reason);

    // set new text
    _input->textView.text = [MaxLengthUtils truncate:html toCapacity:capacity];
  }
}

- (void)replaceFromHtml:(NSString *_Nonnull)html range:(NSRange)range {
  NSInteger capacity = [MaxLengthUtils capacityForHost:_input
                                        replacingRange:range];

  @try {
    NSArray *parsed = [HtmlParser getTextAndStylesFromHtml:html
                                                    config:_input.config];
    NSArray *processingResult = [self truncateProcessingResult:parsed
                                                    toCapacity:capacity];
    NSString *plainText = (NSString *)processingResult[0];
    NSArray *stylesInfo = (NSArray *)processingResult[1];
    NSArray *alignments = (NSArray *)processingResult[2];

    // we can use ready replace util
    [TextInsertionUtils replaceText:plainText
                                 at:range
               additionalAttributes:nil
                               host:_input
                      withSelection:YES];

    [self applyProcessedStyles:stylesInfo
           offsetFromBeginning:range.location
               plainTextLength:plainText.length];
    [self applyProcessedAlignments:alignments offset:range.location];
    [_input anyTextMayHaveBeenModified];
  } @catch (NSException *exception) {
    RCTLogWarn(@"[EnrichedTextInput]: Failed to parse HTML: (%@), falling back "
               @"to raw input.",
               exception.reason);
    [TextInsertionUtils replaceText:[MaxLengthUtils truncate:html
                                                  toCapacity:capacity]
                                 at:range
               additionalAttributes:nil
                               host:_input
                      withSelection:YES];
  }
}

- (void)insertFromHtml:(NSString *_Nonnull)html location:(NSInteger)location {
  NSInteger capacity =
      [MaxLengthUtils capacityForHost:_input
                       replacingRange:NSMakeRange(location, 0)];

  @try {
    NSArray *parsed = [HtmlParser getTextAndStylesFromHtml:html
                                                    config:_input.config];
    NSArray *processingResult = [self truncateProcessingResult:parsed
                                                    toCapacity:capacity];
    NSString *plainText = (NSString *)processingResult[0];
    NSArray *stylesInfo = (NSArray *)processingResult[1];
    NSArray *alignments = (NSArray *)processingResult[2];

    // same here, insertion utils got our back
    [TextInsertionUtils insertText:plainText
                                at:location
              additionalAttributes:nil
                              host:_input
                     withSelection:YES];

    [self applyProcessedStyles:stylesInfo
           offsetFromBeginning:location
               plainTextLength:plainText.length];
    [self applyProcessedAlignments:alignments offset:location];
    [_input anyTextMayHaveBeenModified];
  } @catch (NSException *exception) {
    RCTLogWarn(@"[EnrichedTextInput]: Failed to parse HTML: (%@), falling back "
               @"to raw input.",
               exception.reason);
    [TextInsertionUtils insertText:[MaxLengthUtils truncate:html
                                                 toCapacity:capacity]
                                at:location
              additionalAttributes:nil
                              host:_input
                     withSelection:YES];
  }
}

- (void)applyProcessedStyles:(NSArray *)processedStyles
         offsetFromBeginning:(NSInteger)offset
             plainTextLength:(NSUInteger)plainTextLength {
  // Some paragraph styles (codeblock, blockquote, etc.) insert \u200B
  // into empty lines, mutating NSTextStorage length. We need to
  // shift subsequent ranges by this offset.
  NSInteger zeroWidthSpaceOffset = 0;

  for (NSArray *arr in processedStyles) {
    // unwrap all info from processed style
    NSNumber *styleType = (NSNumber *)arr[0];
    StylePair *stylePair = (StylePair *)arr[1];
    StyleBase *baseStyle = _input->stylesDict[styleType];
    NSRange parsedRange = [stylePair.rangeValue rangeValue];
    NSUInteger textLengthBeforeStyleApplied =
        _input->textView.textStorage.string.length;
    // range must be taking zeroWidthSpaceOffset and offest into consideration
    // because processed styles ranges are relative to only the new text while
    // we need absolute ranges relative to the whole existing text
    NSRange styleRange =
        NSMakeRange(offset + zeroWidthSpaceOffset + parsedRange.location,
                    parsedRange.length);

    // of course any changes here need to take blocks and conflicts into
    // consideration
    if ([StyleUtils handleStyleBlocksAndConflicts:[[baseStyle class] getType]
                                            range:styleRange
                                          forHost:_input]) {
      BOOL shouldAddTypingAttr =
          styleRange.location + styleRange.length ==
          plainTextLength + offset + zeroWidthSpaceOffset;

      if ([styleType isEqualToNumber:@([LinkStyle getType])]) {
        LinkData *linkData = (LinkData *)stylePair.styleValue;
        [((LinkStyle *)baseStyle) addLink:linkData
                                    range:styleRange
                            withSelection:NO];
      } else if ([styleType isEqualToNumber:@([MentionStyle getType])]) {
        MentionParams *params = (MentionParams *)stylePair.styleValue;
        [((MentionStyle *)baseStyle) addMentionAtRange:styleRange
                                                params:params];
      } else if ([styleType isEqualToNumber:@([ImageStyle getType])]) {
        ImageData *imgData = (ImageData *)stylePair.styleValue;
        [((ImageStyle *)baseStyle) addImageAtRange:styleRange
                                         imageData:imgData
                                     withSelection:NO
                                    withDirtyRange:YES];
      } else if ([styleType isEqualToNumber:@([CheckboxListStyle getType])]) {
        NSDictionary *checkboxStates = (NSDictionary *)stylePair.styleValue;
        CheckboxListStyle *cbLStyle = (CheckboxListStyle *)baseStyle;

        // First apply the checkbox list style to the entire range with
        // unchecked value
        [cbLStyle addWithChecked:NO
                           range:styleRange
                      withTyping:shouldAddTypingAttr
                  withDirtyRange:YES];

        if (checkboxStates && checkboxStates.count > 0) {
          // Then toggle checked checkboxes
          for (NSNumber *key in checkboxStates) {
            NSUInteger checkboxPosition =
                offset + zeroWidthSpaceOffset + [key unsignedIntegerValue];
            BOOL isChecked = [checkboxStates[key] boolValue];
            if (isChecked) {
              [cbLStyle toggleCheckedAt:checkboxPosition withDirtyRange:YES];
            }
          }
        }
      } else {
        [baseStyle add:styleRange
                withTyping:shouldAddTypingAttr
            withDirtyRange:YES];
      }
    }

    NSInteger delta = (NSInteger)_input->textView.textStorage.string.length -
                      (NSInteger)textLengthBeforeStyleApplied;
    // Image shifts are already handled by _precedingImageCount during tag
    // finalization.
    if (delta != 0 && ![styleType isEqualToNumber:@([ImageStyle getType])]) {
      zeroWidthSpaceOffset += delta;
    }
  }
}

- (void)applyProcessedAlignments:(NSArray<AlignmentEntry *> *)alignments
                          offset:(NSInteger)offset {
  AlignmentStyle *alignmentStyle =
      _input.stylesDict[@([AlignmentStyle getType])];

  if (alignmentStyle == nil) {
    return;
  }

  for (AlignmentEntry *entry in alignments) {
    // Offset the range (e.g. if inserting into the middle of text)
    NSRange finalRange =
        NSMakeRange(offset + entry.range.location, entry.range.length);

    [alignmentStyle addAlignment:entry.alignment
                           range:finalRange
                      withTyping:NO
                  withDirtyRange:NO];
  }
}

/**
 * Shortens the parsed html so that it fits in `capacity` plain characters,
 * dropping and clamping the parsed styles and alignments accordingly.
 */
- (NSArray *)truncateProcessingResult:(NSArray *)processingResult
                           toCapacity:(NSInteger)capacity {
  NSString *plainText = (NSString *)processingResult[0];

  if ([MaxLengthUtils plainLengthOf:plainText] <= capacity) {
    return processingResult;
  }

  NSUInteger cut = [MaxLengthUtils cutIndexIn:plainText capacity:capacity];
  NSMutableArray *styles = [NSMutableArray new];
  NSMutableArray<AlignmentEntry *> *alignments = [NSMutableArray new];

  for (NSArray *styleInfo in (NSArray *)processingResult[1]) {
    StylePair *stylePair = (StylePair *)styleInfo[1];
    NSRange range = [stylePair.rangeValue rangeValue];

    if (range.location >= cut) {
      continue;
    }

    NSUInteger clampedLength = MIN(range.length, cut - range.location);
    StylePair *clampedPair = [[StylePair alloc] init];
    clampedPair.rangeValue =
        [NSValue valueWithRange:NSMakeRange(range.location, clampedLength)];
    clampedPair.styleValue = [self clampStyleValue:stylePair.styleValue
                                          toLength:cut
                                     clampedLength:clampedLength];
    [styles addObject:@[ styleInfo[0], clampedPair ]];
  }

  for (AlignmentEntry *entry in (
           NSArray<AlignmentEntry *> *)processingResult[2]) {
    if (entry.range.location >= cut) {
      continue;
    }

    AlignmentEntry *clampedEntry = [[AlignmentEntry alloc] init];
    clampedEntry.range =
        NSMakeRange(entry.range.location,
                    MIN(entry.range.length, cut - entry.range.location));
    clampedEntry.alignment = entry.alignment;
    [alignments addObject:clampedEntry];
  }

  return @[ [plainText substringToIndex:cut], styles, alignments ];
}

- (id)clampStyleValue:(id)styleValue
             toLength:(NSUInteger)length
        clampedLength:(NSUInteger)clampedLength {
  // link's text value that is later inserted by addLink
  if ([styleValue isKindOfClass:[LinkData class]]) {
    LinkData *linkData = (LinkData *)styleValue;
    if (linkData.text.length > clampedLength) {
      LinkData *clampedLinkData = [linkData copy];
      clampedLinkData.text = [MaxLengthUtils truncate:linkData.text
                                           toCapacity:clampedLength];
      return clampedLinkData;
    }
    return styleValue;
  }

  if (![styleValue isKindOfClass:[NSDictionary class]]) {
    return styleValue;
  }

  // checkbox list's { position: isChecked } dictionary
  NSDictionary *dictionary = (NSDictionary *)styleValue;
  NSMutableDictionary *clamped = [NSMutableDictionary new];
  for (NSNumber *key in dictionary) {
    if ([key unsignedIntegerValue] < length) {
      clamped[key] = dictionary[key];
    }
  }

  return clamped;
}

- (NSString *_Nullable)initiallyProcessHtml:(NSString *_Nonnull)html {
  return [HtmlParser initiallyProcessHtml:html
                        useHtmlNormalizer:_input->useHtmlNormalizer];
}

@end
