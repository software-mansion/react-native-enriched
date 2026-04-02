#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation UnderlineStyle

+ (StyleType)getType {
  return Underline;
}

- (NSString *)getKey {
  return @"EnrichedUnderline";
}

- (BOOL)isParagraph {
  return NO;
}

- (void)applyStyling:(NSRange)range {
  [self.input->textView.textStorage addAttribute:NSUnderlineStyleAttributeName
                                           value:@(NSUnderlineStyleSingle)
                                           range:range];
}

@end
