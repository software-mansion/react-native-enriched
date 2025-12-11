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

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  return self;
}

- (void)applyStyle:(NSRange)range {
  BOOL isStylePresent = [self detectStyle:range];
  if (range.length >= 1) {
    isStylePresent ? [self removeAttributes:range] : [self addAttributes:range];
  } else {
    isStylePresent ? [self removeTypingAttributes] : [self addTypingAttributes];
  }
}

- (void)addAttributesInAttributedString:
            (NSMutableAttributedString *)attributedString
                                  range:(NSRange)range {
  [attributedString addAttribute:NSStrikethroughStyleAttributeName
                           value:@(NSUnderlineStyleSingle)
                           range:range];
}

- (void)addAttributes:(NSRange)range {
  [self addAttributesInAttributedString:_input->textView.textStorage
                                  range:range];
}

- (void)addTypingAttributes {
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
  _input->textView.typingAttributes = newTypingAttrs;
}

- (void)removeAttributesInAttributedString:
            (NSMutableAttributedString *)attributedString
                                     range:(NSRange)range {
  [attributedString removeAttribute:NSStrikethroughStyleAttributeName
                              range:range];
}

- (void)removeAttributes:(NSRange)range {
  [self removeAttributesInAttributedString:_input->textView.textStorage
                                     range:range];
}

- (void)removeTypingAttributes {
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  [newTypingAttrs removeObjectForKey:NSStrikethroughStyleAttributeName];
  _input->textView.typingAttributes = newTypingAttrs;
}

- (BOOL)styleCondition:(id _Nullable)value:(NSRange)range {
  NSNumber *strikethroughStyle = (NSNumber *)value;
  return strikethroughStyle != nullptr &&
         [strikethroughStyle intValue] != NSUnderlineStyleNone;
}

- (BOOL)detectStyleInAttributedString:
            (NSMutableAttributedString *)attributedString
                                range:(NSRange)range {
  return [OccurenceUtils detect:NSStrikethroughStyleAttributeName
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
    return [OccurenceUtils detect:NSStrikethroughStyleAttributeName
                        withInput:_input
                          atIndex:range.location
                    checkPrevious:NO
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value:range];
                    }];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSStrikethroughStyleAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value:range];
               }];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSStrikethroughStyleAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value:range];
               }];
}

@end
