#import "ImageAttachment.h"
#import "ImageExtension.h"

@implementation ImageAttachment

- (instancetype)initWithImageData:(ImageData *)data {
  self = [super initWithURI:data.uri width:data.width height:data.height];
  if (!self)
    return nil;

  _imageData = data;

  // Assign an empty image to reserve layout space within the text system.
  // The actual image is not drawn here; it is rendered and overlaid by a
  // separate ImageView.
  self.image = [UIImage new];

  [self loadAsync];
  return self;
}

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex {
  CGRect baseBounds = self.bounds;

  if (!textContainer.layoutManager.textStorage ||
      charIndex >= textContainer.layoutManager.textStorage.length) {
    return baseBounds;
  }

  UIFont *font =
      [textContainer.layoutManager.textStorage attribute:NSFontAttributeName
                                                 atIndex:charIndex
                                          effectiveRange:NULL];
  if (!font) {
    return baseBounds;
  }

  // Extend the layout bounds below the baseline by the font's descender.
  // Without this, a line containing only the attachment has no descender space
  // below the baseline, but adding a text character introduces it — causing
  // the line height to jump.  By reserving descender space upfront the line
  // height stays consistent regardless of whether text is present.
  CGFloat descender = font.descender;
  return CGRectMake(baseBounds.origin.x, descender, baseBounds.size.width,
                    baseBounds.size.height - descender);
}

- (void)loadAsync {
  NSURL *url = [NSURL URLWithString:self.uri];
  if (!url) {
    self.storedAnimatedImage = [UIImage systemImageNamed:@"photo"];
    return;
  }

  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    NSData *bytes = [NSData dataWithContentsOfURL:url];

    // We pass all image data (including static formats like PNG or JPEG)
    // through the GIF parser. It safely acts as a universal parser, returning
    // a single-frame UIImage for static formats and an animated UIImage for
    // GIFs.
    UIImage *img = bytes ? [UIImage animatedImageWithAnimatedGIFData:bytes]
                         : [UIImage systemImageNamed:@"photo"];

    dispatch_async(dispatch_get_main_queue(), ^{
      self.storedAnimatedImage = img;
      [self notifyUpdate];
    });
  });
}

@end
