#import "HtmlNode.h"

@implementation HTMLNode
- (instancetype)init {
  if ((self = [super init])) {
    _children = [NSMutableArray array];
  }
  return self;
}
@end

@implementation HTMLElement
@end

@implementation HTMLTextNode
@end
