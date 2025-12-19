#import "ParagraphAttributesUtils.h"
#import "EnrichedTextInputView.h"
#import "ParagraphsUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

@implementation ParagraphAttributesUtils

// if the user backspaces the last character in a line, the iOS applies typing
// attributes from the previous line in the case of some paragraph styles it
// works especially bad when a list point just appears this method handles that
// case differently with or without present paragraph styles
+ (BOOL)handleBackspaceInRange:(NSRange)range
               replacementText:(NSString *)text
                         input:(id)input {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  UnorderedListStyle *ulStyle =
      typedInput->stylesDict[@([UnorderedListStyle getStyleType])];
  OrderedListStyle *olStyle =
      typedInput->stylesDict[@([OrderedListStyle getStyleType])];
  BlockQuoteStyle *bqStyle =
      typedInput->stylesDict[@([BlockQuoteStyle getStyleType])];
  CodeBlockStyle *cbStyle =
      typedInput->stylesDict[@([CodeBlockStyle getStyleType])];

  if (typedInput == nullptr) {
    return NO;
  }

  // we make sure it was a backspace (text with 0 length) and it deleted
  // something (range longer than 0)
  if (text.length > 0 || range.length == 0) {
    return NO;
  }

  // find a non-newline range of the paragraph
  NSRange paragraphRange =
      [typedInput->textView.textStorage.string paragraphRangeForRange:range];

  NSArray *paragraphs =
      [ParagraphsUtils getNonNewlineRangesIn:typedInput->textView
                                       range:paragraphRange];
  if (paragraphs.count == 0) {
    return NO;
  }

  NSRange nonNewlineRange = [(NSValue *)paragraphs.firstObject rangeValue];

  // the backspace removes the whole content of a paragraph (possibly more but
  // has to start where the paragraph starts)
  if (range.location == nonNewlineRange.location &&
      range.length >= nonNewlineRange.length) {

    // for lists, quotes and codeblocks present we do the following:
    // - manually do the removing
    // - reset typing attribtues so that the previous line styles don't get
    // applied
    // - reapply the paragraph style that was present so that a zero width space
    // appears here
    NSArray *handledStyles = @[ ulStyle, olStyle, bqStyle, cbStyle ];
    for (id<BaseStyleProtocol> style in handledStyles) {
      if ([style detectStyle:nonNewlineRange]) {
        [TextInsertionUtils replaceText:text
                                     at:range
                   additionalAttributes:nullptr
                                  input:typedInput
                          withSelection:YES];
        typedInput->textView.typingAttributes =
            typedInput->defaultTypingAttributes;
        [style addAttributes:NSMakeRange(range.location, 0) withTypingAttr:YES];
        return YES;
      }
    }

    // otherwise (no paragraph styles present), we just do the replacement
    // manually and reset typing attribtues
    [TextInsertionUtils replaceText:text
                                 at:range
               additionalAttributes:nullptr
                              input:typedInput
                      withSelection:YES];
    typedInput->textView.typingAttributes = typedInput->defaultTypingAttributes;
    return YES;
  }

  return NO;
}

/**
 * Handles the specific case of backspacing a newline character, which results
 * in merging two paragraphs.
 *
 * THE PROBLEM:
 * When merging a bottom paragraph (Source) into a top paragraph (Destination),
 * the bottom paragraph normally brings all its attributes with it. If the top
 * paragraph is a restrictive style (like a CodeBlock), and the bottom paragraph
 * contains a conflicting style (like an H1 Header), a standard merge would
 * create an invalid state (e.g., a CodeBlock that is also a Header).
 *
 * THE SOLUTION:
 * 1. Identifies the dominant style of the paragraph ABOVE the deleted newline
 * (`leftParagraphStyle`).
 * 2. Checks the paragraph BELOW the newline (`rightRange`) for any styles that
 * conflict with or are blocked by the top style.
 * 3. Explicitly removes those forbidden styles from the bottom paragraph
 * *before* the merge occurs.
 * 4. Performs the merge (deletes the newline).
 *
 * @return YES if the newline backspace was handled and sanitized; NO otherwise.
 */
+ (BOOL)handleParagraphStylesMergeOnBackspace:(NSRange)range
                              replacementText:(NSString *)text
                                        input:(id)input {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if (typedInput == nullptr) {
    return NO;
  }

  if (text.length == 0) {
    NSRange leftRange = [typedInput->textView.textStorage.string
        paragraphRangeForRange:NSMakeRange(range.location, 0)];

    id<BaseStyleProtocol> leftParagraphStyle = nullptr;
    for (NSNumber *key in typedInput->stylesDict) {
      id<BaseStyleProtocol> style = typedInput->stylesDict[key];
      if ([[style class] isParagraphStyle] && [style detectStyle:leftRange]) {
        leftParagraphStyle = style;
      }
    }

    if (leftParagraphStyle == nullptr) {
      return NO;
    }

    // index out of bounds
    NSUInteger rightRangeStart = range.location + range.length;
    if (rightRangeStart >= typedInput->textView.textStorage.string.length) {
      return NO;
    }

    NSRange rightRange = [typedInput->textView.textStorage.string
        paragraphRangeForRange:NSMakeRange(rightRangeStart, 1)];

    StyleType type = [[leftParagraphStyle class] getStyleType];

    NSArray *conflictingStyles = [typedInput
        getPresentStyleTypesFrom:typedInput->conflictingStyles[@(type)]
                           range:rightRange];
    NSArray *blockingStyles =
        [typedInput getPresentStyleTypesFrom:typedInput->blockingStyles[@(type)]
                                       range:rightRange];
    NSArray *allToBeRemoved =
        [conflictingStyles arrayByAddingObjectsFromArray:blockingStyles];

    for (NSNumber *style in allToBeRemoved) {
      id<BaseStyleProtocol> styleClass = typedInput->stylesDict[style];

      // for ranges, we need to remove each occurence
      NSArray<StylePair *> *allOccurences =
          [styleClass findAllOccurences:rightRange];

      for (StylePair *pair in allOccurences) {
        [styleClass removeAttributes:[pair.rangeValue rangeValue]];
      }
    }

    [TextInsertionUtils replaceText:text
                                 at:range
               additionalAttributes:nullptr
                              input:typedInput
                      withSelection:YES];
    return YES;
  }

  return NO;
}

@end
