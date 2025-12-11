#import "EnrichedTextInputView.h"
#import "OccurenceUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

// custom NSAttributedStringKey to differentiate the image
static NSString *const ImageAttributeName = @"ImageAttributeName";

@implementation ImageStyle {
  EnrichedTextInputView *_input;
}

+ (StyleType)getStyleType {
  return Image;
}

+ (BOOL)isParagraphStyle {
  return NO;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  return self;
}

- (void)applyStyle:(NSRange)range {
  // no-op for image
}

- (void)addAttributes:(NSRange)range withTypingAttr:(BOOL)withTypingAttr {
  // no-op for image
}

- (void)addTypingAttributes {
  // no-op for image
}

- (void)removeAttributes:(NSRange)range {
  [_input->textView.textStorage beginEditing];
  [_input->textView.textStorage removeAttribute:ImageAttributeName range:range];
  [_input->textView.textStorage removeAttribute:NSAttachmentAttributeName
                                          range:range];
  [_input->textView.textStorage endEditing];
}

- (void)removeTypingAttributes {
  NSMutableDictionary *currentAttributes =
      [_input->textView.typingAttributes mutableCopy];
  [currentAttributes removeObjectForKey:ImageAttributeName];
  [currentAttributes removeObjectForKey:NSAttachmentAttributeName];
  _input->textView.typingAttributes = currentAttributes;
}

- (BOOL)styleCondition:(id _Nullable)value:(NSRange)range {
  return [value isKindOfClass:[ImageData class]];
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:ImageAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value:range];
               }];
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:ImageAttributeName
                        withInput:_input
                          inRange:range
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value:range];
                    }];
  } else {
    return [OccurenceUtils detect:ImageAttributeName
                        withInput:_input
                          atIndex:range.location
                    checkPrevious:YES
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value:range];
                    }];
  }
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:ImageAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value:range];
               }];
}

- (ImageData *)getImageDataAt:(NSUInteger)location {
  NSRange imageRange = NSMakeRange(0, 0);
  NSRange inputRange = NSMakeRange(0, _input->textView.textStorage.length);

  // don't search at the very end of input
  NSUInteger searchLocation = location;
  if (searchLocation == _input->textView.textStorage.length) {
    return nullptr;
  }

  ImageData *imageData =
      [_input->textView.textStorage attribute:ImageAttributeName
                                      atIndex:searchLocation
                        longestEffectiveRange:&imageRange
                                      inRange:inputRange];

  return imageData;
}

- (void)addImageAtRange:(NSRange)range
              imageData:(ImageData *)imageData
          withSelection:(BOOL)withSelection {
  UIImage *img = [self prepareImageFromUri:imageData.uri];

  NSDictionary *attributes = [@{
    NSAttachmentAttributeName : [self prepareImageAttachement:img
                                                        width:imageData.width
                                                       height:imageData.height],
    ImageAttributeName : imageData,
  } mutableCopy];

  // Use the Object Replacement Character for Image.
  // This tells TextKit "something non-text goes here".
  NSString *imagePlaceholder = @"\uFFFC";

  if (range.length == 0) {
    [TextInsertionUtils insertText:imagePlaceholder
                                at:range.location
              additionalAttributes:attributes
                             input:_input
                     withSelection:withSelection];
  } else {
    [TextInsertionUtils replaceText:imagePlaceholder
                                 at:range
               additionalAttributes:attributes
                              input:_input
                      withSelection:withSelection];
  }
}

- (void)addImage:(NSString *)uri width:(CGFloat)width height:(CGFloat)height {
  ImageData *data = [[ImageData alloc] init];
  data.uri = uri;
  data.width = width;
  data.height = height;

  [self addImageAtRange:_input->textView.selectedRange
              imageData:data
          withSelection:YES];
}

- (NSTextAttachment *)prepareImageAttachement:(UIImage *)image
                                        width:(CGFloat)width
                                       height:(CGFloat)height {

  NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
  attachment.image = image;
  attachment.bounds = CGRectMake(0, 0, width, height);

  return attachment;
}

- (UIImage *)prepareImageFromUri:(NSString *)uri {
  NSURL *url = [NSURL URLWithString:uri];
  NSData *imgData = [NSData dataWithContentsOfURL:url];
  UIImage *image = [UIImage imageWithData:imgData];

  return image;
}

@end
