#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "StyleHeaders.h"

@implementation CodeBlockStyle

+ (StyleType)getType {
  return CodeBlock;
}

- (NSString *)getValue {
  return @"EnrichedCodeBlock";
}

- (BOOL)isParagraph {
  return YES;
}

- (BOOL)needsZWS {
  return YES;
}

- (void)applyStyling:(NSRange)range {
  [self.host.textView.textStorage
      enumerateAttribute:NSFontAttributeName
                 inRange:range
                 options:0
              usingBlock:^(id _Nullable value, NSRange subRange,
                           BOOL *_Nonnull stop) {
                UIFont *currentFont = (UIFont *)value;
                if (currentFont == nullptr)
                  return;
                UIFont *monoFont = [[[self.host.config monospacedFont]
                    withFontTraits:currentFont] setSize:currentFont.pointSize];
                if (monoFont != nullptr) {
                  [self.host.textView.textStorage
                      addAttribute:NSFontAttributeName
                             value:monoFont
                             range:subRange];
                }
              }];

  [self.host.textView.textStorage
      addAttribute:NSForegroundColorAttributeName
             value:[self.host.config codeBlockFgColor]
             range:range];
}

@end
