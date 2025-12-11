#import "ImageAttachment.h"

@implementation ImageAttachment

- (instancetype)initWithImageData:(ImageData *)data {
  self = [super initWithURI:data.uri width:data.width height:data.height];
  if (!self)
    return nil;

  _imageData = data;

  [self loadAsync];
  return self;
}

- (void)loadAsync {
  NSURL *url = [NSURL URLWithString:self.uri];
  if (!url)
    return;

  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    NSData *bytes = [NSData dataWithContentsOfURL:url];
    UIImage *img = bytes ? [UIImage imageWithData:bytes] : nil;
    if (!img)
      return;

    dispatch_async(dispatch_get_main_queue(), ^{
      self.image = img;
      [self notifyUpdate];
    });
  });
}

@end
