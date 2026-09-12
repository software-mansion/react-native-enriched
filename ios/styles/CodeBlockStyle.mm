#import "EnrichedTextInputView.h"
#import "extensions/FontExtension.h"
#import "interfaces/StyleHeaders.h"

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

- (BOOL)appliesStylingToTyping {
  return YES;
}

- (void)applyStylingToTypingAttrs:(NSMutableDictionary *)attributes {
  UIFont *currentFont =
      attributes[NSFontAttributeName] ?: [self.host.config primaryFont];
  UIFont *monoFont = [[[self.host.config monospacedFont]
      withFontTraits:currentFont] setSize:currentFont.pointSize];
  if (monoFont != nil) {
    attributes[NSFontAttributeName] = monoFont;
  }
  UIColor *fgColor = [self.host.config codeBlockFgColor];
  if (fgColor != nil) {
    attributes[NSForegroundColorAttributeName] = fgColor;
  }
}

@end
