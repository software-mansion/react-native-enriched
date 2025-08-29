#import "StyleHeaders.h"
#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"

@implementation HeadingStyleBase

// mock values since H1/2/3Style classes anyway are used
+ (StyleType)getStyleType { return None; }
- (CGFloat)getHeadingFontSize { return 0; }
- (BOOL)isHeadingBold { return false; }

- (EnrichedTextInputView *)typedInput {
  return (EnrichedTextInputView *)input;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  self->input = input;
  return self;
}

// the range will already be the full paragraph/s range
// but if the paragraph is empty it still is of length 0
- (void)applyStyle:(NSRange)range {
  BOOL isStylePresent = [self detectStyle:range];
  if(range.length >= 1) {
    isStylePresent ? [self removeAttributes:range] : [self addAttributes:range];
  } else {
    isStylePresent ? [self removeTypingAttributes] : [self addTypingAttributes];
  }
}

// the range will already be the proper full paragraph/s range
- (void)addAttributes:(NSRange)range {
  [[self typedInput]->textView.textStorage beginEditing];
  [[self typedInput]->textView.textStorage enumerateAttribute:NSFontAttributeName inRange:range options:0
    usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
      UIFont *font = (UIFont *)value;
      if(font != nullptr) {
        UIFont *newFont = [font setSize:[self getHeadingFontSize]];
        if([self isHeadingBold]) {
          newFont = [newFont setBold];
        }
        [[self typedInput]->textView.textStorage addAttribute:NSFontAttributeName value:newFont range:range];
      }
    }
  ];
  [[self typedInput]->textView.textStorage endEditing];
  
  // also toggle typing attributes
  [self addTypingAttributes];
}

// will always be called on empty paragraphs so only typing attributes can be changed
- (void)addTypingAttributes {
  UIFont *currentFontAttr = (UIFont *)[self typedInput]->textView.typingAttributes[NSFontAttributeName];
  if(currentFontAttr != nullptr) {
    NSMutableDictionary *newTypingAttrs = [[self typedInput]->textView.typingAttributes mutableCopy];
    UIFont *newFont = [currentFontAttr setSize:[self getHeadingFontSize]];
    if([self isHeadingBold]) {
      newFont = [newFont setBold];
    }
    newTypingAttrs[NSFontAttributeName] = newFont;
    [self typedInput]->textView.typingAttributes = newTypingAttrs;
  }
}

// we need to remove the style from the whole paragraph
- (void)removeAttributes:(NSRange)range {
  NSRange paragraphRange = [[self typedInput]->textView.textStorage.string paragraphRangeForRange:range];
  
  [[self typedInput]->textView.textStorage beginEditing];
  [[self typedInput]->textView.textStorage enumerateAttribute:NSFontAttributeName inRange:paragraphRange options:0
    usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
      if([self styleCondition:value :range]) {
        UIFont *newFont = [(UIFont *)value setSize:[[[self typedInput]->config primaryFontSize] floatValue]];
        if([self isHeadingBold]) {
          newFont = [newFont removeBold];
        }
        [[self typedInput]->textView.textStorage addAttribute:NSFontAttributeName value:newFont range:range];
      }
    }
  ];
  [[self typedInput]->textView.textStorage endEditing];
  
  // typing attributes still need to be removed
  UIFont *currentFontAttr = (UIFont *)[self typedInput]->textView.typingAttributes[NSFontAttributeName];
  if(currentFontAttr != nullptr) {
    NSMutableDictionary *newTypingAttrs = [[self typedInput]->textView.typingAttributes mutableCopy];
    UIFont *newFont = [currentFontAttr setSize:[[[self typedInput]->config primaryFontSize] floatValue]];
    if([self isHeadingBold]) {
      newFont = [newFont removeBold];
    }
    newTypingAttrs[NSFontAttributeName] = newFont;
    [self typedInput]->textView.typingAttributes = newTypingAttrs;
  }
}

- (void)removeTypingAttributes {
  // all the heading still needs to be removed because this function may be called in conflicting styles logic
  // typing attributes already get removed in there as well
  [self removeAttributes:[self typedInput]->textView.selectedRange];
}

- (BOOL)styleCondition:(id _Nullable)value :(NSRange)range {
  UIFont *font = (UIFont *)value;
  return font != nullptr && font.pointSize == [self getHeadingFontSize];
}

- (BOOL)detectStyle:(NSRange)range {
  if(range.length >= 1) {
    return [OccurenceUtils detect:NSFontAttributeName withInput:[self typedInput] inRange:range
      withCondition: ^BOOL(id  _Nullable value, NSRange range) {
        return [self styleCondition:value :range];
      }
    ];
  } else {
    UIFont *currentFontAttr = (UIFont *)[self typedInput]->textView.typingAttributes[NSFontAttributeName];
    if(currentFontAttr == nullptr) {
      return false;
    }
    return currentFontAttr.pointSize == [self getHeadingFontSize];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSFontAttributeName withInput:[self typedInput] inRange:range
    withCondition:^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSFontAttributeName withInput:[self typedInput] inRange:range
    withCondition:^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

@end

