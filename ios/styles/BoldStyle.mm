#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "StyleHeaders.h"

@implementation BoldStyle : StyleBase

+ (StyleType)getType {
  return Bold;
}

- (NSString *)getKey {
  return @"EnrichedBold";
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
                  UIFont *newFont = [font setBold];
                  [self.input->textView.textStorage
                      addAttribute:NSFontAttributeName
                             value:newFont
                             range:range];
                }
              }];
}

@end
