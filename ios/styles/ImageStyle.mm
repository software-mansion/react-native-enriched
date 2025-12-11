#import "EnrichedTextInputView.h"
#import "ImageAttachment.h"
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

- (void)addAttributes:(NSRange)range {
  // no-op for image
}

- (void)addAttributesInAttributedString:
            (NSMutableAttributedString *)attributedString
                                  range:(NSRange)range {
  // no-op for image
}

- (void)addTypingAttributes {
  // no-op for image
}

- (void)removeAttributesInAttributedString:
            (NSMutableAttributedString *)attributedString
                                     range:(NSRange)range {
  [attributedString removeAttribute:ImageAttributeName range:range];
  [attributedString removeAttribute:NSAttachmentAttributeName range:range];
}

- (void)removeAttributes:(NSRange)range {
  [_input->textView.textStorage beginEditing];
  [self removeAttributesInAttributedString:_input->textView.textStorage
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

- (BOOL)detectStyleInAttributedString:
            (NSMutableAttributedString *)attributedString
                                range:(NSRange)range {
  return [OccurenceUtils detect:ImageAttributeName
                       inString:attributedString
                        inRange:range
                  withCondition:^BOOL(id _Nullable value, NSRange range) {
                    return [self styleCondition:value:range];
                  }];
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [self detectStyleInAttributedString:_input->textView.textStorage
                                         range:range];
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

- (NSArray<StylePair *> *_Nullable)
    findAllOccurencesInAttributedString:(NSAttributedString *)attributedString
                                  range:(NSRange)range {
  return [OccurenceUtils all:ImageAttributeName
                    inString:attributedString
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
  if (!imageData)
    return;

  ImageAttachment *attachment =
      [[ImageAttachment alloc] initWithImageData:imageData];
  attachment.delegate = _input;

  NSDictionary *attrs =
      @{NSAttachmentAttributeName : attachment, ImageAttributeName : imageData};

  NSString *placeholderChar = @"\uFFFC";

  if (range.length == 0) {
    [TextInsertionUtils insertText:placeholderChar
                                at:range.location
              additionalAttributes:attrs
                             input:_input
                     withSelection:withSelection];
  } else {
    [TextInsertionUtils replaceText:placeholderChar
                                 at:range
               additionalAttributes:attrs
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

- (void)addImageInAttributedString:(NSMutableAttributedString *)string
                             range:(NSRange)range
                         imageData:(ImageData *)imageData {
  if (!imageData)
    return;

  ImageAttachment *attachment =
      [[ImageAttachment alloc] initWithImageData:imageData];
  attachment.delegate = _input;

  NSMutableDictionary *attrs = [_input->defaultTypingAttributes mutableCopy];
  attrs[NSAttachmentAttributeName] = attachment;
  attrs[ImageAttributeName] = imageData;

  NSAttributedString *imgString =
      [[NSAttributedString alloc] initWithString:@"\uFFFC" attributes:attrs];

  if (range.length == 0) {
    [string insertAttributedString:imgString atIndex:range.location];
  } else {
    [string replaceCharactersInRange:range withAttributedString:imgString];
  }
}

@end
