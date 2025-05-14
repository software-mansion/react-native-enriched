#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"
#import "FontUtils.h"

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
  [_editor->textView.textStorage enumerateAttribute:NSFontAttributeName inRange:range options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
    UIFont *font = (UIFont *)value;
    if(font != nullptr) {
      UIFont *newFont = [font setItalic];
      [_editor->textView.textStorage addAttribute:NSFontAttributeName value:newFont range:range];
    }
  }];
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
  [_editor->textView.textStorage enumerateAttribute:NSFontAttributeName inRange:range options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
    UIFont *font = (UIFont *)value;
    if(font != nullptr) {
      UIFont *newFont = [font removeItalic];
      [_editor->textView.textStorage addAttribute:NSFontAttributeName value:newFont range:range];
    }
  }];
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

- (BOOL)detectStyle:(NSRange)range {
  if(range.length >= 1) {
    __block NSInteger totalLength = 0;
    [_editor->textView.textStorage enumerateAttribute:NSFontAttributeName inRange:range options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
      UIFont *font = (UIFont *)value;
      if(font != nullptr && [font isItalic]) {
        totalLength += range.length;
      }
    }];
    return totalLength == range.length;
  } else {
    UIFont *currentFontAttr = (UIFont *)_editor->textView.typingAttributes[NSFontAttributeName];
    if(currentFontAttr == nullptr) {
      return false;
    }
    return [currentFontAttr isItalic];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  __block BOOL found = NO;
  [_editor->textView.textStorage enumerateAttribute:NSFontAttributeName inRange:range options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
    UIFont *font = (UIFont *)value;
    if(font != nullptr && [font isItalic]) {
      found = YES;
      *stop = YES;
    }
  }];
  return found;
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  __block NSMutableArray<StylePair *> *occurences = [[NSMutableArray<StylePair *> alloc] init];
  [_editor->textView.textStorage enumerateAttribute:NSFontAttributeName inRange:range options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
    UIFont *font = (UIFont *)value;
    if(font != nullptr && [font isItalic]) {
      StylePair *pair = [[StylePair alloc] init];
      pair.rangeValue = [NSValue valueWithRange:range];
      pair.styleValue = value;
      [occurences addObject:pair];
    }
  }];
  return occurences;
}

@end
