#import "MediaAttachment.h"

@implementation MediaAttachment

- (instancetype)initWithURI:(NSString *)uri
                      width:(CGFloat)width
                     height:(CGFloat)height {
  self = [super init];
  if (!self)
    return nil;

  _uri = uri;
  _width = width;
  _height = height;

  self.bounds = CGRectMake(0, 0, width, height);

  return self;
}

- (void)loadAsync {
  // no-op for base
}

- (void)notifyUpdate {
  if ([self.delegate respondsToSelector:@selector(mediaAttachmentDidUpdate:)]) {
    [self.delegate mediaAttachmentDidUpdate:self];
  }
}

@end
