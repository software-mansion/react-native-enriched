#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"

@implementation BoldStyle {
  ReactNativeRichTextEditorView *_editor;
}

+ (StyleType)getStyleType { return Bold; }

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
  [_editor->textView.textStorage enumerateAttribute:NSFontAttributeName inRange:range options:0
    usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
      UIFont *font = (UIFont *)value;
      if(font != nullptr) {
        UIFont *newFont = [font setBold];
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
    newTypingAttrs[NSFontAttributeName] = [currentFontAttr setBold];
    _editor->textView.typingAttributes = newTypingAttrs;
  }
}

- (void)removeAttributes:(NSRange)range {
  [_editor->textView.textStorage beginEditing];
  [_editor->textView.textStorage enumerateAttribute:NSFontAttributeName inRange:range options:0
    usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
      UIFont *font = (UIFont *)value;
      if(font != nullptr) {
        UIFont *newFont = [font removeBold];
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
    newTypingAttrs[NSFontAttributeName] = [currentFontAttr removeBold];
    _editor->textView.typingAttributes = newTypingAttrs;
  }
}

- (BOOL)boldHeadingConflictsInRange:(NSRange)range type:(StyleType)type {
  if(type == H1) {
    if(![_editor->config h1Bold]) { return NO; }
  } else if(type == H2) {
    if(![_editor->config h2Bold]) { return NO; }
  } else if(type == H3) {
    if(![_editor->config h3Bold]) { return NO; }
  }
  
  id<BaseStyleProtocol> headingStyle = _editor->stylesDict[@(type)];
  return range.length > 0
    ? [headingStyle anyOccurence:range]
    : [headingStyle detectStyle:range];
}

- (BOOL)styleCondition:(id _Nullable)value :(NSRange)range {
  UIFont *font = (UIFont *)value;
  return font != nullptr && [font isBold] && ![self boldHeadingConflictsInRange:range type:H1] && ![self boldHeadingConflictsInRange:range type:H2] && ![self boldHeadingConflictsInRange:range type:H3];
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
    return [self styleCondition:currentFontAttr :range];
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
