#import "EnrichedTextInputView.h"
#import "OccurenceUtils.h"
#import "StyleHeaders.h"

@implementation StrikethroughStyle {
  EnrichedTextInputView *_input;
}

+ (StyleType)getStyleType {
  return Strikethrough;
}

+ (BOOL)isParagraphStyle {
  return NO;
}

+ (const char *)tagName {
  return "s";
}

+ (const char *)subTagName {
  return nil;
}

+ (NSAttributedStringKey)attributeKey {
  return NSStrikethroughStyleAttributeName;
}

+ (BOOL)isSelfClosing {
  return NO;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  return self;
}

- (void)applyStyle:(NSRange)range {
  BOOL isStylePresent = [self detectStyle:range];
  if (range.length >= 1) {
    isStylePresent ? [self removeAttributes:range]
                   : [self addAttributes:range withTypingAttr:YES];
  } else {
    isStylePresent ? [self removeTypingAttributes] : [self addTypingAttributes];
  }
}

- (void)addAttributes:(NSRange)range withTypingAttr:(BOOL)withTypingAttr {
  [_input->textView.textStorage addAttribute:NSStrikethroughStyleAttributeName
                                       value:@(NSUnderlineStyleSingle)
                                       range:range];
}

- (void)addTypingAttributes {
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
  _input->textView.typingAttributes = newTypingAttrs;
}

- (void)removeAttributes:(NSRange)range {
  [_input->textView.textStorage
      removeAttribute:NSStrikethroughStyleAttributeName
                range:range];
}

- (void)removeTypingAttributes {
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  [newTypingAttrs removeObjectForKey:NSStrikethroughStyleAttributeName];
  _input->textView.typingAttributes = newTypingAttrs;
}

- (BOOL)styleCondition:(id _Nullable)value range:(NSRange)range {
  if (!value)
    return NO;
  NSNumber *strikethroughStyle = (NSNumber *)value;
  return [strikethroughStyle intValue] != NSUnderlineStyleNone;
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:NSStrikethroughStyleAttributeName
                        withInput:_input
                          inRange:range
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  } else {
    return [OccurenceUtils detect:NSStrikethroughStyleAttributeName
                        withInput:_input
                          atIndex:range.location
                    checkPrevious:NO
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSStrikethroughStyleAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSStrikethroughStyleAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

@end
