#import "ImageData.h"
#import "MediaAttachment.h"

@interface ImageAttachment : MediaAttachment

@property(nonatomic, strong) ImageData *imageData;
@property(nonatomic, strong) UIImage *storedAnimatedImage;

- (instancetype)initWithImageData:(ImageData *)data;

@end
