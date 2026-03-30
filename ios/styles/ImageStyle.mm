#import "EnrichedTextInputView.h"
#import "ImageAttachment.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

// custom NSAttributedStringKey to differentiate the image
static NSString *const ImageAttributeName = @"EnrichedImage";

@implementation ImageStyle

+ (StyleType)getType {
  return Image;
}

- (NSString *)getKey {
  return ImageAttributeName;
}

- (BOOL)isParagraph {
  return NO;
}

- (void)applyStyling:(NSRange)range {
  // no-op for image
}

- (void)reapplyFromStylePair:(StylePair *)pair {
  NSRange range = [pair.rangeValue rangeValue];
  ImageData *imageData = (ImageData *)pair.styleValue;
  if (imageData == nullptr || range.length == 0) {
    return;
  }

  ImageAttachment *attachment =
      [[ImageAttachment alloc] initWithImageData:imageData];
  attachment.delegate = self.input;

  [self.input->textView.textStorage addAttributes:@{
    NSAttachmentAttributeName : attachment,
    ImageAttributeName : imageData
  }
                                            range:range];
}

- (AttributeEntry *)getEntryIfPresent:(NSRange)range {
  return nullptr;
}

- (void)toggle:(NSRange)range {
  // no-op for image
}

- (void)remove:(NSRange)range withDirtyRange:(BOOL)withDirtyRange {
  [self.input->textView.textStorage beginEditing];
  [self.input->textView.textStorage removeAttribute:ImageAttributeName
                                              range:range];
  [self.input->textView.textStorage removeAttribute:NSAttachmentAttributeName
                                              range:range];
  [self.input->textView.textStorage endEditing];

  if (withDirtyRange) {
    [self.input->attributesManager addDirtyRange:range];
  }

  [self removeTyping];
}

- (void)removeTyping {
  NSMutableDictionary *currentAttributes =
      [self.input->textView.typingAttributes mutableCopy];
  [currentAttributes removeObjectForKey:ImageAttributeName];
  [currentAttributes removeObjectForKey:NSAttachmentAttributeName];
  [self.input->attributesManager didRemoveTypingAttribute:ImageAttributeName];
  self.input->textView.typingAttributes = currentAttributes;
}

- (BOOL)styleCondition:(id _Nullable)value range:(NSRange)range {
  return [value isKindOfClass:[ImageData class]];
}

- (ImageData *)getImageDataAt:(NSUInteger)location {
  NSRange imageRange = NSMakeRange(0, 0);
  NSRange inputRange = NSMakeRange(0, self.input->textView.textStorage.length);

  // don't search at the very end of input
  NSUInteger searchLocation = location;
  if (searchLocation == self.input->textView.textStorage.length) {
    return nullptr;
  }

  ImageData *imageData =
      [self.input->textView.textStorage attribute:ImageAttributeName
                                          atIndex:searchLocation
                            longestEffectiveRange:&imageRange
                                          inRange:inputRange];

  return imageData;
}

- (void)addImageAtRange:(NSRange)range
              imageData:(ImageData *)imageData
          withSelection:(BOOL)withSelection {
  if (!imageData)
    return;

  ImageAttachment *attachment =
      [[ImageAttachment alloc] initWithImageData:imageData];
  attachment.delegate = self.input;

  NSDictionary *attributes =
      @{NSAttachmentAttributeName : attachment, ImageAttributeName : imageData};

  // Use the Object Replacement Character for Image.
  // This tells TextKit "something non-text goes here".
  NSString *placeholderChar = @"\uFFFC";

  if (range.length == 0) {
    [TextInsertionUtils insertText:placeholderChar
                                at:range.location
              additionalAttributes:attributes
                             input:self.input
                     withSelection:withSelection];
  } else {
    [TextInsertionUtils replaceText:placeholderChar
                                 at:range
               additionalAttributes:attributes
                              input:self.input
                      withSelection:withSelection];
  }

  NSRange insertedImageRange = NSMakeRange(range.location, 1);
  [self.input->attributesManager addDirtyRange:insertedImageRange];
}

- (void)addImage:(NSString *)uri width:(CGFloat)width height:(CGFloat)height {
  ImageData *data = [[ImageData alloc] init];
  data.uri = uri;
  data.width = width;
  data.height = height;

  [self addImageAtRange:self.input->textView.selectedRange
              imageData:data
          withSelection:YES];
}

@end
