#import "ConvertHtmlToPlainTextAndStylesResult.h"

@implementation ConvertHtmlToPlainTextAndStylesResult
- (instancetype)initWithData:(NSString *)text styles:(NSArray *)styles {
  self = [super init];
  _text = text;
  _styles = styles;
  return self;
}
@end
