#import "ParagraphAttributesUtils.h"
#import "EnrichedTextInputView.h"
#import "RangeUtils.h"
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

  NSArray *paragraphs = [RangeUtils getNonNewlineRangesIn:typedInput->textView
                                                    range:paragraphRange];
  if (paragraphs.count == 0) {
    return NO;
  }

  NSRange nonNewlineRange = [(NSValue *)paragraphs.firstObject rangeValue];

  // the backspace removes the whole content of a paragraph (possibly more but
  // has to start where the paragraph starts)
  if (range.location == nonNewlineRange.location &&
      range.length >= nonNewlineRange.length) {

    // for styles that need ZWS (lists, quotes, etc.) we do the following:
    // - manually do the removing
    // - reset typing attribtues so that the previous line styles don't get
    // applied
    // - reapply the paragraph style that was present so that a zero width space
    // appears here
    for (NSNumber *type in typedInput->stylesDict) {
      StyleBase *style = typedInput->stylesDict[type];
      if ([style needsZWS] && [style detect:nonNewlineRange]) {
        [TextInsertionUtils replaceText:text
                                     at:range
                   additionalAttributes:nullptr
                                  input:typedInput
                          withSelection:YES];
        typedInput->textView.typingAttributes =
            typedInput->defaultTypingAttributes;
        [style add:NSMakeRange(range.location, 0)
                withTyping:YES
            withDirtyRange:YES];
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

  // Must be a backspace.
  if (text.length > 0) {
    return NO;
  }

  // Backspace must have removed a newline character.
  NSString *removedString =
      [typedInput->textView.textStorage.string substringWithRange:range];
  if ([removedString
          rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]]
          .location == NSNotFound) {
    return NO;
  }

  NSRange leftRange = [typedInput->textView.textStorage.string
      paragraphRangeForRange:NSMakeRange(range.location, 0)];

  StyleBase *leftParagraphStyle = nullptr;
  for (NSNumber *key in typedInput->stylesDict) {
    StyleBase *style = typedInput->stylesDict[key];
    if ([style isParagraph] && [style detect:leftRange]) {
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

  StyleType type = [[leftParagraphStyle class] getType];

  NSArray *conflictingStyles = [typedInput
      getPresentStyleTypesFrom:typedInput->conflictingStyles[@(type)]
                         range:rightRange];
  NSArray *blockingStyles =
      [typedInput getPresentStyleTypesFrom:typedInput->blockingStyles[@(type)]
                                     range:rightRange];
  NSArray *allToBeRemoved =
      [conflictingStyles arrayByAddingObjectsFromArray:blockingStyles];

  for (NSNumber *style in allToBeRemoved) {
    StyleBase *styleToRemove = typedInput->stylesDict[style];

    NSArray<StylePair *> *allOccurences = [styleToRemove all:rightRange];

    for (StylePair *pair in allOccurences) {
      [styleToRemove remove:[pair.rangeValue rangeValue] withDirtyRange:YES];
    }
  }

  [TextInsertionUtils replaceText:text
                               at:range
             additionalAttributes:nullptr
                            input:typedInput
                    withSelection:YES];
  return YES;
}

/**
 * Resets typing attributes to defaults when the cursor lands on an empty line
 * after a deletion.
 *
 * This override is necessary because `UITextView` automatically inherits
 * attributes from the preceding newline. This prevents scenarios where a
 * restrictive style (like CodeBlock) "leaks" into the next empty paragraph.
 */
+ (BOOL)handleResetTypingAttributesOnBackspace:(NSRange)range
                               replacementText:(NSString *)text
                                         input:(id)input {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if (typedInput == nullptr) {
    return NO;
  }

  NSString *storageString = typedInput->textView.textStorage.string;

  if (text.length > 0 || range.location >= storageString.length) {
    return NO;
  }

  unichar firstCharToDelete = [storageString characterAtIndex:range.location];
  if (![[NSCharacterSet newlineCharacterSet]
          characterIsMember:firstCharToDelete]) {
    return NO;
  }

  NSRange leftParagraphRange =
      [storageString paragraphRangeForRange:NSMakeRange(range.location, 0)];
  BOOL isLeftLineEmpty = [self isParagraphEmpty:leftParagraphRange
                                       inString:storageString];

  BOOL isRightLineEmpty = YES;
  NSUInteger rightRangeStart = range.location + range.length;

  if (rightRangeStart < storageString.length) {
    NSRange rightParagraphRange =
        [storageString paragraphRangeForRange:NSMakeRange(rightRangeStart, 0)];
    isRightLineEmpty = [self isParagraphEmpty:rightParagraphRange
                                     inString:storageString];
  }

  if (isLeftLineEmpty && isRightLineEmpty) {
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

+ (BOOL)isParagraphEmpty:(NSRange)range inString:(NSString *)string {
  if (range.length == 0)
    return YES;

  NSString *paragraphText = [string substringWithRange:range];
  NSString *trimmed = [paragraphText
      stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  return trimmed.length == 0;
}

@end
