#import "DotReplacementUtils.h"
#import "EnrichedTextInputView.h"

@implementation DotReplacementUtils

// This is a fix for iOS replacing a space with a dot when two spaces are
// quickly inputted That operation doesn't properly extend our custom attributes
// and we do it here manually
+ (void)handleDotReplacement:(id)input
                 textStorage:(NSTextStorage *)textStorage
                  editedMask:(NSTextStorageEditActions)editedMask
                 editedRange:(NSRange)editedRange
                       delta:(NSInteger)delta {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if (typedInput == nullptr) {
    return;
  }

  // Conditions for the dot attributes fix:
  // - character edition was done
  // - it edited one character
  // - new character is a dot
  // - delta=0, meaning a replacement was done
  // - there is something before the edited range to get attributes from
  if ((editedMask & NSTextStorageEditedCharacters) != 0 &&
      editedRange.length == 1 &&
      [[textStorage.string substringWithRange:editedRange]
          isEqualToString:@"."] &&
      delta == 0 && editedRange.location > 0) {
    // If all of the above are true, we are sure some dot replacement has been
    // done So we manually need to apply the preceeding attribtues to the dot
    NSDictionary *prevAttrs =
        [textStorage attributesAtIndex:editedRange.location - 1
                        effectiveRange:nullptr];
    [textStorage addAttributes:prevAttrs range:editedRange];
    typedInput->dotReplacementRange = [NSValue valueWithRange:editedRange];
    return;
  }

  // Space after the dot added by iOS comes in a separate, second callback.
  // Checking its conditions:
  // - dotReplacementRange defined
  // - dotReplacementRange was exactly before the new edited range
  // - character edition was done
  // - it edited one character
  // - edited character is a space
  // - delta=1, meaning addition was done
  if (typedInput->dotReplacementRange != nullptr &&
      [typedInput->dotReplacementRange rangeValue].location + 1 ==
          editedRange.location &&
      (editedMask & NSTextStorageEditedCharacters) != 0 &&
      editedRange.length == 1 &&
      [[textStorage.string substringWithRange:editedRange]
          isEqualToString:@" "] &&
      delta == 1) {
    // If all of the above are true, we are now sure it was the iOS dot
    // replacement Only then do we also fix attribtues of the space added
    // afterwards
    NSDictionary *prevAttrs =
        [textStorage attributesAtIndex:editedRange.location - 1
                        effectiveRange:nullptr];
    [textStorage addAttributes:prevAttrs range:editedRange];
  }
  // always reset the replacement range after any processing
  typedInput->dotReplacementRange = nullptr;
}

@end
