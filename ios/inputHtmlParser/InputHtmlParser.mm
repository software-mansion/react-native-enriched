#import "InputHtmlParser.h"
#import "AlignmentEntry.h"
#import "EnrichedTextInputView.h"
#import "HtmlParser.h"
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

  @try {
    NSArray *processingResult = [HtmlParser getTextAndStylesFromHtml:html];
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
    _input->textView.text = html;
  }
}

- (void)replaceFromHtml:(NSString *_Nonnull)html range:(NSRange)range {
  @try {
    NSArray *processingResult = [HtmlParser getTextAndStylesFromHtml:html];
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
    [TextInsertionUtils replaceText:html
                                 at:range
               additionalAttributes:nil
                               host:_input
                      withSelection:YES];
  }
}

- (void)insertFromHtml:(NSString *_Nonnull)html location:(NSInteger)location {
  @try {
    NSArray *processingResult = [HtmlParser getTextAndStylesFromHtml:html];
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
    [TextInsertionUtils insertText:html
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

- (NSString *_Nullable)initiallyProcessHtml:(NSString *_Nonnull)html {
  return [HtmlParser initiallyProcessHtml:html
                        useHtmlNormalizer:_input->useHtmlNormalizer];
}

@end
