#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"
#import "OccurenceUtils.h"

@implementation StrikethroughStyle {
  ReactNativeRichTextEditorView *_editor;
}

+ (StyleType)getStyleType { return Strikethrough; }

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
  [_editor->textView.textStorage addAttribute:NSStrikethroughStyleAttributeName value:@(NSUnderlineStyleSingle) range:range];
}

- (void)addTypingAttributes {
  NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
  _editor->textView.typingAttributes = newTypingAttrs;
}

- (void)removeAttributes:(NSRange)range {
  [_editor->textView.textStorage removeAttribute:NSStrikethroughStyleAttributeName range:range];
}

- (void)removeTypingAttributes {
  NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
  [newTypingAttrs removeObjectForKey: NSStrikethroughStyleAttributeName];
  _editor->textView.typingAttributes = newTypingAttrs;
}

- (BOOL)styleCondition:(id _Nullable)value :(NSRange)range {
  NSNumber *strikethroughStyle = (NSNumber *)value;
  return strikethroughStyle != nullptr && [strikethroughStyle intValue] != NSUnderlineStyleNone;
}

- (BOOL)detectStyle:(NSRange)range {
  if(range.length >= 1) {
    return [OccurenceUtils detect:NSStrikethroughStyleAttributeName withEditor:_editor inRange:range
      withCondition: ^BOOL(id  _Nullable value, NSRange range) {
        return [self styleCondition:value :range];
      }
    ];
  } else {
    NSNumber *currenStrikethroughAttr = (NSNumber *)_editor->textView.typingAttributes[NSStrikethroughStyleAttributeName];
    return currenStrikethroughAttr != nullptr;
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSStrikethroughStyleAttributeName withEditor:_editor inRange:range
    withCondition:^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSStrikethroughStyleAttributeName withEditor:_editor inRange:range
    withCondition:^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

@end
