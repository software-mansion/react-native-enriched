#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"
#import "FontUtils.h"
#import "OccurenceUtils.h"

@implementation ItalicStyle {
  ReactNativeRichTextEditorView *_editor;
}

+ (StyleType)getStyleType { return Italic; }

- (instancetype)initWithEditor:(id)editor {
  self = [super init];
  _editor = (ReactNativeRichTextEditorView *) editor;
  return self;
}

- (void)applyStyle:(NSRange)range {
  BOOL isStylePresent = [self detectStyle: _editor->currentRange];
  if(_editor->currentRange.length >= 1) {
    isStylePresent ? [self removeAttributes:_editor->currentRange] : [self addAttributes:_editor->currentRange];
  } else {
    isStylePresent ? [self removeTypingAttributes] : [self addTypingAttributes];
  }
}

- (void)addAttributes:(NSRange)range {
  [_editor->textView.textStorage beginEditing];
  [_editor->textView.textStorage enumerateAttribute:NSFontAttributeName inRange:range options:0
    usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
      UIFont *font = (UIFont *)value;
      if(font != nullptr) {
        UIFont *newFont = [font setItalic];
        [_editor->textView.textStorage addAttribute:NSFontAttributeName value:newFont range:range];
      }
    }
  ];
  [_editor->textView.textStorage endEditing];
}

- (void)addTypingAttributes {
  UIFont *currentFontAttr = (UIFont *)_editor->textView.typingAttributes[NSFontAttributeName];
  if(currentFontAttr != nullptr) {
    NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
    newTypingAttrs[NSFontAttributeName] = [currentFontAttr setItalic];
    _editor->textView.typingAttributes = newTypingAttrs;
  }
}

- (void)removeAttributes:(NSRange)range {
  [_editor->textView.textStorage beginEditing];
  [_editor->textView.textStorage enumerateAttribute:NSFontAttributeName inRange:range options:0
    usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
      UIFont *font = (UIFont *)value;
      if(font != nullptr) {
        UIFont *newFont = [font removeItalic];
        [_editor->textView.textStorage addAttribute:NSFontAttributeName value:newFont range:range];
      }
    }
  ];
  [_editor->textView.textStorage endEditing];
}

- (void)removeTypingAttributes {
  UIFont *currentFontAttr = (UIFont *)_editor->textView.typingAttributes[NSFontAttributeName];
  if(currentFontAttr != nullptr) {
    NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
    newTypingAttrs[NSFontAttributeName] = [currentFontAttr removeItalic];
    _editor->textView.typingAttributes = newTypingAttrs;
  }
}

- (BOOL)styleCondition:(id _Nullable)value :(NSRange)range {
  UIFont *font = (UIFont *)value;
  return font != nullptr && [font isItalic];
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
    return [currentFontAttr isItalic];
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
