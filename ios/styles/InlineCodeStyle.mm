#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"

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
  [_editor->textView.textStorage beginEditing];

  [_editor->textView.textStorage addAttribute:NSBackgroundColorAttributeName value:[_editor->config inlineCodeBgColor] range:range];
  [_editor->textView.textStorage addAttribute:NSForegroundColorAttributeName value:[_editor->config inlineCodeFgColor] range:range];
  [_editor->textView.textStorage addAttribute:NSUnderlineColorAttributeName value:[_editor->config inlineCodeFgColor] range:range];
  [_editor->textView.textStorage addAttribute:NSStrikethroughColorAttributeName value:[_editor->config inlineCodeFgColor] range:range];
  [_editor->textView.textStorage enumerateAttribute:NSFontAttributeName inRange:range options:0
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

- (void)addTypingAttributes {
  NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSBackgroundColorAttributeName] = [_editor->config inlineCodeBgColor];
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

- (BOOL)styleCondition:(id _Nullable)value :(NSRange)range {
  UIFont *font = (UIFont *)value;
  return font != nullptr && [font isMonospace:_editor->config];
}

- (BOOL)detectStyle:(NSRange)range {
  if(range.length >= 1) {
    return [OccurenceUtils detect:NSFontAttributeName withEditor:_editor inRange:range
      withCondition: ^BOOL(id  _Nullable value, NSRange range) {
        return [self styleCondition:value :range];
      }
    ];
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
