#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "StyleHeaders.h"

@implementation ItalicStyle : StyleBase

+ (StyleType)getType {
  return Italic;
}

- (NSString *)getKey {
  return @"EnrichedItalic";
}

- (BOOL)isParagraph {
  return NO;
}

- (void)applyStyling:(NSRange)range {
  [self.input->textView.textStorage
      enumerateAttribute:NSFontAttributeName
                 inRange:range
                 options:0
              usingBlock:^(id _Nullable value, NSRange range,
                           BOOL *_Nonnull stop) {
                UIFont *font = (UIFont *)value;
                if (font != nullptr) {
                  UIFont *newFont = [font setItalic];
                  [self.input->textView.textStorage
                      addAttribute:NSFontAttributeName
                             value:newFont
                             range:range];
                }
              }];
}

@end
