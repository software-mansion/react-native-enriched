#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"
#import "OccurenceUtils.h"

@implementation UnderlineStyle {
  ReactNativeRichTextEditorView *_editor;
}

+ (StyleType)getStyleType { return Underline; }

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
  [_editor->textView.textStorage addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:range];
}

- (void)addTypingAttributes {
  NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
  _editor->textView.typingAttributes = newTypingAttrs;
}

- (void)removeAttributes:(NSRange)range {
  [_editor->textView.textStorage removeAttribute:NSUnderlineStyleAttributeName range:range];
}

- (void)removeTypingAttributes {
  NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
  [newTypingAttrs removeObjectForKey: NSUnderlineStyleAttributeName];
  _editor->textView.typingAttributes = newTypingAttrs;
}

- (BOOL)styleCondition:(id _Nullable)value :(NSRange)range {
  NSNumber *underlineStyle = (NSNumber *)value;
  return underlineStyle != nullptr && [underlineStyle intValue] != NSUnderlineStyleNone;
}

- (BOOL)detectStyle:(NSRange)range {
  if(range.length >= 1) {
    return [OccurenceUtils detect:NSUnderlineStyleAttributeName withEditor:_editor inRange:range
      withCondition: ^BOOL(id  _Nullable value, NSRange range) {
        return [self styleCondition:value :range];
      }
    ];
  } else {
    NSNumber *currentUnderlineAttr = (NSNumber *)_editor->textView.typingAttributes[NSUnderlineStyleAttributeName];
    return currentUnderlineAttr != nullptr;
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSUnderlineStyleAttributeName withEditor:_editor inRange:range
    withCondition:^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSUnderlineStyleAttributeName withEditor:_editor inRange:range
    withCondition:^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

@end
