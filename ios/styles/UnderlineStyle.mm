#import "EnrichedTextInputView.h"
#import "OccurenceUtils.h"
#import "StyleHeaders.h"

@implementation UnderlineStyle {
  EnrichedTextInputView *_input;
}

+ (StyleType)getStyleType {
  return Underline;
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
  [_input->textView.textStorage addAttribute:NSUnderlineStyleAttributeName
                                       value:@(NSUnderlineStyleSingle)
                                       range:range];
}

- (void)addTypingAttributes {
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
  _input->textView.typingAttributes = newTypingAttrs;
}

- (void)removeAttributes:(NSRange)range {
  [_input->textView.textStorage removeAttribute:NSUnderlineStyleAttributeName
                                          range:range];
}

- (void)removeTypingAttributes {
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  [newTypingAttrs removeObjectForKey:NSUnderlineStyleAttributeName];
  _input->textView.typingAttributes = newTypingAttrs;
}

- (BOOL)underlinedLinkConflictsInRange:(NSRange)range {
  BOOL conflicted = NO;
  if ([_input->config linkDecorationLine] == DecorationUnderline) {
    LinkStyle *linkStyle = _input->stylesDict[@([LinkStyle getStyleType])];
    conflicted = range.length > 0 ? [linkStyle anyOccurence:range]
                                  : [linkStyle detectStyle:range];
  }
  return conflicted;
}

- (BOOL)underlinedMentionConflictsInRange:(NSRange)range {
  BOOL conflicted = NO;
  MentionStyle *mentionStyle =
      _input->stylesDict[@([MentionStyle getStyleType])];
  if (range.length == 0) {
    if ([mentionStyle detectStyle:range]) {
      MentionParams *params = [mentionStyle getMentionParamsAt:range.location];
      conflicted =
          [_input->config mentionStylePropsForIndicator:params.indicator]
              .decorationLine == DecorationUnderline;
    }
  } else {
    NSArray *occurences = [mentionStyle findAllOccurences:range];
    for (StylePair *pair in occurences) {
      MentionParams *params = [mentionStyle
          getMentionParamsAt:[pair.rangeValue rangeValue].location];
      if ([_input->config mentionStylePropsForIndicator:params.indicator]
              .decorationLine == DecorationUnderline) {
        conflicted = YES;
        break;
      }
    }
  }
  return conflicted;
}

- (BOOL)styleCondition:(id _Nullable)value:(NSRange)range {
  NSNumber *underlineStyle = (NSNumber *)value;
  return underlineStyle != nullptr &&
         [underlineStyle intValue] != NSUnderlineStyleNone &&
         ![self underlinedLinkConflictsInRange:range] &&
         ![self underlinedMentionConflictsInRange:range];
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:NSUnderlineStyleAttributeName
                        withInput:_input
                          inRange:range
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value:range];
                    }];
  } else {
    return [OccurenceUtils detect:NSUnderlineStyleAttributeName
                        withInput:_input
                          atIndex:range.location
                    checkPrevious:NO
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value:range];
                    }];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSUnderlineStyleAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value:range];
               }];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSUnderlineStyleAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value:range];
               }];
}

@end
