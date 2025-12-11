#import "ColorExtension.h"
#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"
#import "ParagraphsUtils.h"
#import "StyleHeaders.h"

@implementation InlineCodeStyle {
  EnrichedTextInputView *_input;
}

+ (StyleType)getStyleType {
  return InlineCode;
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
  // we don't want to apply inline code to newline characters, it looks bad
  NSArray *nonNewlineRanges =
      [ParagraphsUtils getNonNewlineRangesIn:_input->textView range:range];

  for (NSValue *value in nonNewlineRanges) {
    NSRange currentRange = [value rangeValue];
    [_input->textView.textStorage beginEditing];

    [_input->textView.textStorage
        addAttribute:NSBackgroundColorAttributeName
               value:[[_input->config inlineCodeBgColor]
                         colorWithAlphaIfNotTransparent:0.4]
               range:currentRange];
    [_input->textView.textStorage
        addAttribute:NSForegroundColorAttributeName
               value:[_input->config inlineCodeFgColor]
               range:currentRange];
    [_input->textView.textStorage
        addAttribute:NSUnderlineColorAttributeName
               value:[_input->config inlineCodeFgColor]
               range:currentRange];
    [_input->textView.textStorage
        addAttribute:NSStrikethroughColorAttributeName
               value:[_input->config inlineCodeFgColor]
               range:currentRange];
    [_input->textView.textStorage
        enumerateAttribute:NSFontAttributeName
                   inRange:currentRange
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  UIFont *font = (UIFont *)value;
                  if (font != nullptr) {
                    UIFont *newFont = [[[_input->config monospacedFont]
                        withFontTraits:font] setSize:font.pointSize];
                    [_input->textView.textStorage
                        addAttribute:NSFontAttributeName
                               value:newFont
                               range:range];
                  }
                }];

    [_input->textView.textStorage endEditing];
  }
}

- (void)addTypingAttributes {
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSBackgroundColorAttributeName] =
      [[_input->config inlineCodeBgColor] colorWithAlphaIfNotTransparent:0.4];
  newTypingAttrs[NSForegroundColorAttributeName] =
      [_input->config inlineCodeFgColor];
  newTypingAttrs[NSUnderlineColorAttributeName] =
      [_input->config inlineCodeFgColor];
  newTypingAttrs[NSStrikethroughColorAttributeName] =
      [_input->config inlineCodeFgColor];
  UIFont *currentFont = (UIFont *)newTypingAttrs[NSFontAttributeName];
  if (currentFont != nullptr) {
    newTypingAttrs[NSFontAttributeName] = [[[_input->config monospacedFont]
        withFontTraits:currentFont] setSize:currentFont.pointSize];
  }
  _input->textView.typingAttributes = newTypingAttrs;
}

- (void)removeAttributes:(NSRange)range {
  [_input->textView.textStorage beginEditing];

  [_input->textView.textStorage removeAttribute:NSBackgroundColorAttributeName
                                          range:range];
  [_input->textView.textStorage addAttribute:NSForegroundColorAttributeName
                                       value:[_input->config primaryColor]
                                       range:range];
  [_input->textView.textStorage addAttribute:NSUnderlineColorAttributeName
                                       value:[_input->config primaryColor]
                                       range:range];
  [_input->textView.textStorage addAttribute:NSStrikethroughColorAttributeName
                                       value:[_input->config primaryColor]
                                       range:range];
  [_input->textView.textStorage
      enumerateAttribute:NSFontAttributeName
                 inRange:range
                 options:0
              usingBlock:^(id _Nullable value, NSRange range,
                           BOOL *_Nonnull stop) {
                UIFont *font = (UIFont *)value;
                if (font != nullptr) {
                  UIFont *newFont = [[[_input->config primaryFont]
                      withFontTraits:font] setSize:font.pointSize];
                  [_input->textView.textStorage addAttribute:NSFontAttributeName
                                                       value:newFont
                                                       range:range];
                }
              }];

  [_input->textView.textStorage endEditing];
}

- (void)removeTypingAttributes {
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  [newTypingAttrs removeObjectForKey:NSBackgroundColorAttributeName];
  newTypingAttrs[NSForegroundColorAttributeName] =
      [_input->config primaryColor];
  newTypingAttrs[NSUnderlineColorAttributeName] = [_input->config primaryColor];
  newTypingAttrs[NSStrikethroughColorAttributeName] =
      [_input->config primaryColor];
  UIFont *currentFont = (UIFont *)newTypingAttrs[NSFontAttributeName];
  if (currentFont != nullptr) {
    newTypingAttrs[NSFontAttributeName] = [[[_input->config primaryFont]
        withFontTraits:currentFont] setSize:currentFont.pointSize];
  }
  _input->textView.typingAttributes = newTypingAttrs;
}

// making sure no newlines get inline code style, it looks bad
- (void)handleNewlines {
  for (int i = 0; i < _input->textView.textStorage.string.length; i++) {
    if ([[NSCharacterSet newlineCharacterSet]
            characterIsMember:[_input->textView.textStorage.string
                                  characterAtIndex:i]]) {
      NSRange mockRange = NSMakeRange(0, 0);
      // can't use detect style because it intentionally doesn't take newlines
      // into consideration
      UIColor *bgColor =
          [_input->textView.textStorage attribute:NSBackgroundColorAttributeName
                                          atIndex:i
                                   effectiveRange:&mockRange];
      if ([self styleCondition:bgColor:NSMakeRange(i, 1)]) {
        [self removeAttributes:NSMakeRange(i, 1)];
      }
    }
  }
}

// emojis don't retain monospace font attribute so we check for the background
// color if there is no mention
- (BOOL)styleCondition:(id _Nullable)value:(NSRange)range {
  UIColor *bgColor = (UIColor *)value;
  MentionStyle *mStyle = _input->stylesDict[@([MentionStyle getStyleType])];
  return bgColor != nullptr && mStyle != nullptr && ![mStyle detectStyle:range];
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    // detect only in non-newline characters
    NSArray *nonNewlineRanges =
        [ParagraphsUtils getNonNewlineRangesIn:_input->textView range:range];
    if (nonNewlineRanges.count == 0) {
      return NO;
    }

    BOOL detected = YES;
    for (NSValue *value in nonNewlineRanges) {
      NSRange currentRange = [value rangeValue];
      BOOL currentDetected =
          [OccurenceUtils detect:NSBackgroundColorAttributeName
                       withInput:_input
                         inRange:currentRange
                   withCondition:^BOOL(id _Nullable value, NSRange range) {
                     return [self styleCondition:value:range];
                   }];
      detected = detected && currentDetected;
    }

    return detected;
  } else {
    return [OccurenceUtils detect:NSBackgroundColorAttributeName
                        withInput:_input
                          atIndex:range.location
                    checkPrevious:NO
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value:range];
                    }];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSBackgroundColorAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value:range];
               }];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSBackgroundColorAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value:range];
               }];
}

@end
