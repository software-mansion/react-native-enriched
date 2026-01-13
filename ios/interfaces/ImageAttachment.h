#import "ImageData.h"
#import "MediaAttachment.h"

@interface ImageAttachment : MediaAttachment

@property(nonatomic, strong) ImageData *imageData;

- (instancetype)initWithImageData:(ImageData *)data;

@end
