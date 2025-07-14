#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"
#import "ParagraphsUtils.h"
#import "TextInsertionUtils.h"

@implementation InlineCodeStyle {
  ReactNativeRichTextEditorView *_editor;
}

+ (StyleType)getStyleType { return InlineCode; }

- (instancetype)initWithEditor:(id)editor {
  self = [super init];
  _editor = (ReactNativeRichTextEditorView *) editor;
  return self;
}

- (void)applyStyle:(NSRange)range {
  BOOL isStylePresent = [self detectStyle:range];
  if(range.length >= 1) {
    isStylePresent ? [self removeAttributes:range] : [self addAttributes:range];
  } else {
    isStylePresent ? [self removeTypingAttributes] : [self addTypingAttributes];
  }
}

- (void)addAttributes:(NSRange)range {
  // we don't want to apply inline code to newline characters, it looks bad
  NSArray *nonNewlineRanges = [ParagraphsUtils getNonNewlineRangesIn:_editor->textView range:range];
  
  for(NSValue *value in nonNewlineRanges) {
    NSRange currentRange = [value rangeValue];
    [_editor->textView.textStorage beginEditing];

    [_editor->textView.textStorage addAttribute:NSBackgroundColorAttributeName value:[[_editor->config inlineCodeBgColor] colorWithAlphaComponent:0.6] range:currentRange];
    [_editor->textView.textStorage addAttribute:NSForegroundColorAttributeName value:[_editor->config inlineCodeFgColor] range:currentRange];
    [_editor->textView.textStorage addAttribute:NSUnderlineColorAttributeName value:[_editor->config inlineCodeFgColor] range:currentRange];
    [_editor->textView.textStorage addAttribute:NSStrikethroughColorAttributeName value:[_editor->config inlineCodeFgColor] range:currentRange];
    [_editor->textView.textStorage enumerateAttribute:NSFontAttributeName inRange:currentRange options:0
      usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        UIFont *font = (UIFont *)value;
        if(font != nullptr) {
          UIFont *newFont = [[_editor->config monospacedFont] withFontTraits:font];
          [_editor->textView.textStorage addAttribute:NSFontAttributeName value:newFont range:range];
        }
      }
    ];
    
    [_editor->textView.textStorage endEditing];
  }
}

- (void)addTypingAttributes {
  NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSBackgroundColorAttributeName] = [[_editor->config inlineCodeBgColor] colorWithAlphaComponent:0.6];
  newTypingAttrs[NSForegroundColorAttributeName] = [_editor->config inlineCodeFgColor];
  newTypingAttrs[NSUnderlineColorAttributeName] = [_editor->config inlineCodeFgColor];
  newTypingAttrs[NSStrikethroughColorAttributeName] = [_editor->config inlineCodeFgColor];
  UIFont* currentFont = (UIFont *)newTypingAttrs[NSFontAttributeName];
  if(currentFont != nullptr) {
    newTypingAttrs[NSFontAttributeName] = [[_editor->config monospacedFont] withFontTraits:currentFont];
  }
  _editor->textView.typingAttributes = newTypingAttrs;
}

- (void)removeAttributes:(NSRange)range {
  [_editor->textView.textStorage beginEditing];

  [_editor->textView.textStorage removeAttribute:NSBackgroundColorAttributeName range:range];
  [_editor->textView.textStorage addAttribute:NSForegroundColorAttributeName value:[_editor->config primaryColor] range:range];
  [_editor->textView.textStorage addAttribute:NSUnderlineColorAttributeName value:[_editor->config primaryColor] range:range];
  [_editor->textView.textStorage addAttribute:NSStrikethroughColorAttributeName value:[_editor->config primaryColor] range:range];
  [_editor->textView.textStorage enumerateAttribute:NSFontAttributeName inRange:range options:0
    usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
      UIFont *font = (UIFont *)value;
      if(font != nullptr) {
        UIFont *newFont = [[_editor->config primaryFont] withFontTraits:font];
        [_editor->textView.textStorage addAttribute:NSFontAttributeName value:newFont range:range];
      }
    }
  ];
  
  [_editor->textView.textStorage endEditing];
}

- (void)removeTypingAttributes {
  NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
  [newTypingAttrs removeObjectForKey:NSBackgroundColorAttributeName];
  newTypingAttrs[NSForegroundColorAttributeName] = [_editor->config primaryColor];
  newTypingAttrs[NSUnderlineColorAttributeName] = [_editor->config primaryColor];
  newTypingAttrs[NSStrikethroughColorAttributeName] = [_editor->config primaryColor];
  UIFont* currentFont = (UIFont *)newTypingAttrs[NSFontAttributeName];
  if(currentFont != nullptr) {
    newTypingAttrs[NSFontAttributeName] = [[_editor->config primaryFont] withFontTraits:currentFont];
  }
  _editor->textView.typingAttributes = newTypingAttrs;
}

// making sure no newlines get inline code style, it looks bad
- (void)handleNewlines {
  for(int i = 0; i < _editor->textView.textStorage.string.length; i++) {
    if([[NSCharacterSet newlineCharacterSet] characterIsMember:[_editor->textView.textStorage.string characterAtIndex:i]]) {
      NSRange mockRange = NSMakeRange(0, 0);
      // can't use detect style because it intentionally doesn't take newlines into consideration
      UIFont *font = [_editor->textView.textStorage attribute:NSFontAttributeName atIndex:i effectiveRange:&mockRange];
      if([self styleCondition:font :NSMakeRange(i, 1)]) {
        [self removeAttributes:NSMakeRange(i, 1)];
      }
    }
  }
}

- (BOOL)styleCondition:(id _Nullable)value :(NSRange)range {
  UIFont *font = (UIFont *)value;
  return font != nullptr && [font isMonospace:_editor->config];
}

- (BOOL)detectStyle:(NSRange)range {
  if(range.length >= 1) {
    // detect only in non-newline characters
    NSArray *nonNewlineRanges = [ParagraphsUtils getNonNewlineRangesIn:_editor->textView range:range];
    if(nonNewlineRanges.count == 0) {
      return NO;
    }
    
    BOOL detected = YES;
    for(NSValue *value in nonNewlineRanges) {
      NSRange currentRange = [value rangeValue];
      BOOL currentDetected = [OccurenceUtils detect:NSFontAttributeName withEditor:_editor inRange:currentRange
        withCondition: ^BOOL(id  _Nullable value, NSRange range) {
          return [self styleCondition:value :range];
        }
      ];
      detected = detected && currentDetected;
    }
  
    return detected;
  } else {
    UIFont *currentFontAttr = (UIFont *)_editor->textView.typingAttributes[NSFontAttributeName];
    if(currentFontAttr == nullptr) {
      return false;
    }
    return [currentFontAttr isMonospace:_editor->config];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSFontAttributeName withEditor:_editor inRange:range
    withCondition:^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSFontAttributeName withEditor:_editor inRange:range
    withCondition:^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

@end
