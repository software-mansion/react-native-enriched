#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"

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

- (BOOL)detectStyle:(NSRange)range {
  if(range.length >= 1) {
    __block NSInteger totalLength = 0;
    [_editor->textView.textStorage enumerateAttribute:NSStrikethroughStyleAttributeName
      inRange:range options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
      NSNumber *strikethroughStyle = (NSNumber *)value;
      if(strikethroughStyle != nullptr && [strikethroughStyle intValue] != NSUnderlineStyleNone) {
        totalLength += range.length;
      }
    }];
    return totalLength == range.length;
  } else {
    NSNumber *currenStrikethroughAttr = (NSNumber *)_editor->textView.typingAttributes[NSStrikethroughStyleAttributeName];
    return currenStrikethroughAttr != nullptr;
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  __block BOOL found = NO;
  [_editor->textView.textStorage enumerateAttribute:NSStrikethroughStyleAttributeName
    inRange:range options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
    NSNumber *strikethroughStyle = (NSNumber *)value;
    if(strikethroughStyle != nullptr && [strikethroughStyle intValue] != NSUnderlineStyleNone) {
      found = YES;
      *stop = YES;
    }
  }];
  return found;
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  __block NSMutableArray<StylePair *> *occurences = [[NSMutableArray<StylePair *> alloc] init];
  [_editor->textView.textStorage enumerateAttribute:NSStrikethroughStyleAttributeName
    inRange:range options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
    NSNumber *strikethroughStyle = (NSNumber *)value;
    if(strikethroughStyle != nullptr && [strikethroughStyle intValue] != NSUnderlineStyleNone) {
      StylePair *pair = [[StylePair alloc] init];
      pair.rangeValue = [NSValue valueWithRange:range];
      pair.styleValue = value;
      [occurences addObject:pair];
    }
  }];
  return occurences;
}

@end
