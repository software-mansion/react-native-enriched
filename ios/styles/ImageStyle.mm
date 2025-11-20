#import "StyleHeaders.h"
#import "EnrichedTextInputView.h"
#import "ImageData.h"
#import "OccurenceUtils.h"
#import "TextInsertionUtils.h"

// custom NSAttributedStringKey to differentiate the image
static NSString *const ImageAttributeName = @"ImageAttributeName";


@implementation ImageStyle {
  EnrichedTextInputView *_input;
}

+ (StyleType)getStyleType { return Image; }

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

- (void)addTypingAttributes {
  // no-op for image
}

- (void)removeAttributes:(NSRange)range {
  [_input->textView.textStorage beginEditing];
  [_input->textView.textStorage removeAttribute:ImageAttributeName range:range];
  [_input->textView.textStorage endEditing];
}

- (void)removeTypingAttributes {
    NSMutableDictionary *currentAttributes = [_input->textView.typingAttributes mutableCopy];
    [currentAttributes removeObjectForKey:ImageAttributeName];
    _input->textView.typingAttributes = currentAttributes;
}

- (BOOL)styleCondition:(id _Nullable)value :(NSRange)range {
  return [value isKindOfClass:[ImageData class]];
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:ImageAttributeName withInput:_input inRange:range
      withCondition:^BOOL(id  _Nullable value, NSRange range) {
          return [self styleCondition:value :range];
      }
  ];
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:ImageAttributeName withInput:_input inRange:range
        withCondition:^BOOL(id  _Nullable value, NSRange range) {
            return [self styleCondition:value :range];
        }
    ];
  } else {
    return [OccurenceUtils detect:ImageAttributeName withInput:_input atIndex:range.location checkPrevious:YES
        withCondition:^BOOL(id  _Nullable value, NSRange range) {
            return [self styleCondition:value :range];
        }
    ];
  }
}

- (NSArray<StylePair *> * _Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:ImageAttributeName withInput:_input inRange:range
      withCondition:^BOOL(id  _Nullable value, NSRange range) {
          return [self styleCondition:value :range];
      }
  ];
}

- (void)addImage:(NSString *)uri {
  ImageData *data = [[ImageData alloc] init];
  data.uri = uri;
  
  NSMutableDictionary *attributes = [@{
        NSAttachmentAttributeName: [self prepareSpacerAttachement],
        ImageAttributeName: data
  } mutableCopy];
  
  // Use the Object Replacement Character for Image.
  // This tells TextKit "something non-text goes here".
  NSString *imagePlaceholder = @"\uFFFC";
  
  [TextInsertionUtils replaceText:imagePlaceholder
                               at:_input->textView.selectedRange
             additionalAttributes:nil
                            input:_input
                    withSelection:YES];
  
  NSRange newSelection = _input->textView.selectedRange;
  NSRange imageRange = NSMakeRange(newSelection.location - 1, 1);
  
  [_input->textView.textStorage beginEditing];
  [_input->textView.textStorage addAttributes:attributes range:imageRange];
  
  [_input->textView.textStorage endEditing];
}

-(NSTextAttachment *)prepareSpacerAttachement
{
  NSTextAttachment *spacerAttachment = [[NSTextAttachment alloc] init];
  spacerAttachment.bounds = CGRectMake(0, 0, [_input->config imageWidth], [_input->config imageHeight]);
  spacerAttachment.image = [self prepareTransparentImage];
  
  return spacerAttachment;
}

// Helper to create a 1x1 transparent image
- (UIImage *)prepareTransparentImage {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), NO, 0.0);
    UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return blank;
}

@end
