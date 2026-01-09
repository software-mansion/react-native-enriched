#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"
#import "StyleHeaders.h"

@implementation BoldStyle {
  EnrichedTextInputView *_input;
}

+ (StyleType)getStyleType {
  return Bold;
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
    isStylePresent ? [self removeAttributes:range]
                   : [self addAttributes:range withTypingAttr:YES];
  } else {
    isStylePresent ? [self removeTypingAttributes] : [self addTypingAttributes];
  }
}

- (void)addAttributes:(NSRange)range withTypingAttr:(BOOL)withTypingAttr {
  [_input->textView.textStorage beginEditing];
  [_input->textView.textStorage
      enumerateAttribute:NSFontAttributeName
                 inRange:range
                 options:0
              usingBlock:^(id _Nullable value, NSRange range,
                           BOOL *_Nonnull stop) {
                UIFont *font = (UIFont *)value;
                if (font != nullptr) {
                  UIFont *newFont = [font setBold];
                  [_input->textView.textStorage addAttribute:NSFontAttributeName
                                                       value:newFont
                                                       range:range];
                }
              }];
  [_input->textView.textStorage endEditing];
}

- (void)addTypingAttributes {
  UIFont *currentFontAttr =
      (UIFont *)_input->textView.typingAttributes[NSFontAttributeName];
  if (currentFontAttr != nullptr) {
    NSMutableDictionary *newTypingAttrs =
        [_input->textView.typingAttributes mutableCopy];
    newTypingAttrs[NSFontAttributeName] = [currentFontAttr setBold];
    _input->textView.typingAttributes = newTypingAttrs;
  }
}

- (void)removeAttributes:(NSRange)range {
  [_input->textView.textStorage beginEditing];
  [_input->textView.textStorage
      enumerateAttribute:NSFontAttributeName
                 inRange:range
                 options:0
              usingBlock:^(id _Nullable value, NSRange range,
                           BOOL *_Nonnull stop) {
                UIFont *font = (UIFont *)value;
                if (font != nullptr) {
                  UIFont *newFont = [font removeBold];
                  [_input->textView.textStorage addAttribute:NSFontAttributeName
                                                       value:newFont
                                                       range:range];
                }
              }];
  [_input->textView.textStorage endEditing];
}

- (void)removeTypingAttributes {
  UIFont *currentFontAttr =
      (UIFont *)_input->textView.typingAttributes[NSFontAttributeName];
  if (currentFontAttr != nullptr) {
    NSMutableDictionary *newTypingAttrs =
        [_input->textView.typingAttributes mutableCopy];
    newTypingAttrs[NSFontAttributeName] = [currentFontAttr removeBold];
    _input->textView.typingAttributes = newTypingAttrs;
  }
}

- (BOOL)boldHeadingConflictsInRange:(NSRange)range type:(StyleType)type {
  if (type == H1) {
    if (![_input->config h1Bold]) {
      return NO;
    }
  } else if (type == H2) {
    if (![_input->config h2Bold]) {
      return NO;
    }
  } else if (type == H3) {
    if (![_input->config h3Bold]) {
      return NO;
    }
  } else if (type == H4) {
    if (![_input->config h4Bold]) {
      return NO;
    }
  } else if (type == H5) {
    if (![_input->config h5Bold]) {
      return NO;
    }
  } else if (type == H6) {
    if (![_input->config h6Bold]) {
      return NO;
    }
  }

  id<BaseStyleProtocol> headingStyle = _input->stylesDict[@(type)];
  return range.length > 0 ? [headingStyle anyOccurence:range]
                          : [headingStyle detectStyle:range];
}

- (BOOL)styleCondition:(id _Nullable)value:(NSRange)range {
  UIFont *font = (UIFont *)value;
  return font != nullptr && [font isBold] &&
         ![self boldHeadingConflictsInRange:range type:H1] &&
         ![self boldHeadingConflictsInRange:range type:H2] &&
         ![self boldHeadingConflictsInRange:range type:H3] &&
         ![self boldHeadingConflictsInRange:range type:H4] &&
         ![self boldHeadingConflictsInRange:range type:H5] &&
         ![self boldHeadingConflictsInRange:range type:H6];
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:NSFontAttributeName
                        withInput:_input
                          inRange:range
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value:range];
                    }];
  } else {
    return [OccurenceUtils detect:NSFontAttributeName
                        withInput:_input
                          atIndex:range.location
                    checkPrevious:NO
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value:range];
                    }];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSFontAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value:range];
               }];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSFontAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value:range];
               }];
}

@end
