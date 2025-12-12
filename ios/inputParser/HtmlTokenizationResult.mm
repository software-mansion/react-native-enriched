#import "HtmlTokenizationResult.h"

@implementation HtmlTokenizationResult
- (instancetype)initWithData:(NSString *)text
                        tags:(NSMutableArray *_Nonnull)tags {
  self = [super init];
  _text = text;
  _tags = tags;
  return self;
}
@end
