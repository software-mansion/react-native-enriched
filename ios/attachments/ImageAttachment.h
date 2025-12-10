#import "MediaAttachment.h"
#import "ImageData.h"

@interface ImageAttachment : MediaAttachment

@property(nonatomic, strong) ImageData *imageData;

- (instancetype)initWithImageData:(ImageData *)data;

@end
