#import "ColorExtension.h"
#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "RangeUtils.h"
#import "StyleHeaders.h"

@implementation InlineCodeStyle

+ (StyleType)getType {
  return InlineCode;
}

- (NSString *)getKey {
  return @"EnrichedInlineCode";
}

- (BOOL)isParagraph {
  return NO;
}

- (void)applyStyling:(NSRange)range {
  // we don't want to apply inline code to newline characters, it looks bad
  NSArray *nonNewlineRanges =
      [RangeUtils getNonNewlineRangesIn:self.input->textView range:range];

  for (NSValue *value in nonNewlineRanges) {
    NSRange subRange = [value rangeValue];

    [self.input->textView.textStorage
        addAttribute:NSBackgroundColorAttributeName
               value:[[self.input->config inlineCodeBgColor]
                         colorWithAlphaIfNotTransparent:0.4]
               range:subRange];
    [self.input->textView.textStorage
        addAttribute:NSForegroundColorAttributeName
               value:[self.input->config inlineCodeFgColor]
               range:subRange];
    [self.input->textView.textStorage
        addAttribute:NSUnderlineColorAttributeName
               value:[self.input->config inlineCodeFgColor]
               range:subRange];
    [self.input->textView.textStorage
        addAttribute:NSStrikethroughColorAttributeName
               value:[self.input->config inlineCodeFgColor]
               range:subRange];
    [self.input->textView.textStorage
        enumerateAttribute:NSFontAttributeName
                   inRange:subRange
                   options:0
                usingBlock:^(id _Nullable value, NSRange fontRange,
                             BOOL *_Nonnull stop) {
                  UIFont *font = (UIFont *)value;
                  if (font != nullptr) {
                    UIFont *newFont = [[[self.input->config monospacedFont]
                        withFontTraits:font] setSize:font.pointSize];
                    [self.input->textView.textStorage
                        addAttribute:NSFontAttributeName
                               value:newFont
                               range:fontRange];
                  }
                }];
  }
}

@end
