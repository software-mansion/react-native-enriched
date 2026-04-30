#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation StrikethroughStyle : StyleBase

+ (StyleType)getType {
  return Strikethrough;
}

- (NSString *)getKey {
  return @"EnrichedStrikethrough";
}

- (BOOL)isParagraph {
  return NO;
}

- (void)applyStyling:(NSRange)range {
  [self.host.textView.textStorage addAttributes:@{
    NSStrikethroughStyleAttributeName : @(NSUnderlineStyleSingle)
  }
                                          range:range];
}

@end
