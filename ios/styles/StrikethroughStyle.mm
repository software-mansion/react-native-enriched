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
  NSDictionary *styles =
      @{NSStrikethroughStyleAttributeName : @(NSUnderlineStyleSingle)};
  [self.input->textView.textStorage addAttributes:styles range:range];
}

@end
