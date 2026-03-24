#import "ImageAttachment.h"

static NSCache<NSString *, UIImage *> *ImageAttachmentCache(void) {
  static NSCache<NSString *, UIImage *> *cache = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cache = [[NSCache alloc] init];
    cache.totalCostLimit = 50 * 1024 * 1024; // 50 MB
  });
  return cache;
}

@implementation ImageAttachment

- (instancetype)initWithImageData:(ImageData *)data {
  self = [super initWithURI:data.uri width:data.width height:data.height];
  if (!self)
    return nil;

  _imageData = data;
  UIImage *cachedImage = nil;
  if (self.uri.length > 0) {
    cachedImage = [ImageAttachmentCache() objectForKey:self.uri];
  }

  if (cachedImage != nil) {
    self.image = cachedImage;
  } else {
    self.image = [UIImage new];
    [self loadAsync];
  }
  return self;
}

- (void)loadAsync {
  NSURL *url = [NSURL URLWithString:self.uri];
  if (!url) {
    self.image = [UIImage systemImageNamed:@"file"];
    return;
  }

  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    NSData *bytes = [NSData dataWithContentsOfURL:url];
    UIImage *img = bytes ? [UIImage imageWithData:bytes]
                         : [UIImage systemImageNamed:@"file"];

    dispatch_async(dispatch_get_main_queue(), ^{
      if (bytes != nil && img != nil && self.uri.length > 0) {
        CGFloat scale = img.scale;
        // Calculate true byte cost based on pixels
        // Width (in pixels) * Height (in pixels) * 4 bytes (for RGBA channels)
        NSUInteger cost = (NSUInteger)(img.size.width * scale *
                                       img.size.height * scale * 4.0);
        [ImageAttachmentCache() setObject:img forKey:self.uri cost:cost];
      }
      self.image = img;
      [self notifyUpdate];
    });
  });
}

@end
