#import "StyleHeaders.h"
#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"
#import "TextInsertionUtils.h"

@implementation HeadingStyleBase

// mock values since H1/2/3/4/5/6Style classes anyway are used
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
    return [OccurenceUtils detect:NSFontAttributeName withInput:[self typedInput] atIndex:range.location checkPrevious:YES
      withCondition:^BOOL(id  _Nullable value, NSRange range) {
        return [self styleCondition:value :range];
      }
    ];
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

// used to make sure headings dont persist after a newline is placed
- (BOOL)handleNewlinesInRange:(NSRange)range replacementText:(NSString *)text {
  // in a heading and a new text ends with a newline
  if(
    [self detectStyle:[self typedInput]->textView.selectedRange] &&
    text.length > 0 &&
    [[NSCharacterSet newlineCharacterSet] characterIsMember: [text characterAtIndex:text.length-1]]
  ) {
    // do the replacement manually
    [TextInsertionUtils replaceText:text at:range additionalAttributes:nullptr input:[self typedInput] withSelection:YES];
    // remove the attribtues at the new selection
    [self removeAttributes:[self typedInput]->textView.selectedRange];
    return YES;
  }
  return NO;
}

// backspacing a line after a heading "into" a heading will not result in the text attaining heading attributes
// so, we do it manually
- (void)handleImproperHeadings {
  NSArray *occurences = [self findAllOccurences:NSMakeRange(0, [self typedInput]->textView.textStorage.string.length)];
  for(StylePair *pair in occurences) {
    NSRange occurenceRange = [pair.rangeValue rangeValue];
    NSRange paragraphRange = [[self typedInput]->textView.textStorage.string paragraphRangeForRange:occurenceRange];
    if(!NSEqualRanges(occurenceRange, paragraphRange)) {
      // we have a heading but it does not span its whole paragraph - let's fix it
      [self addAttributes:paragraphRange];
    }
  }
}

@end

