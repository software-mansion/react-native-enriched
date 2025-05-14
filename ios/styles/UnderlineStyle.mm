#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"

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

- (BOOL)detectStyle:(NSRange)range {
  if(range.length >= 1) {
    __block NSInteger totalLength = 0;
    [_editor->textView.textStorage enumerateAttribute:NSUnderlineStyleAttributeName
      inRange:range options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
      NSNumber *underlineStyle = (NSNumber *)value;
      if(underlineStyle != nullptr && [underlineStyle intValue] != NSUnderlineStyleNone) {
        totalLength += range.length;
      }
    }];
    return totalLength == range.length;
  } else {
    NSNumber *currentUnderlineAttr = (NSNumber *)_editor->textView.typingAttributes[NSUnderlineStyleAttributeName];
    return currentUnderlineAttr != nullptr;
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  __block BOOL found = NO;
  [_editor->textView.textStorage enumerateAttribute:NSUnderlineStyleAttributeName
    inRange:range options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
    NSNumber *underlineStyle = (NSNumber *)value;
    if(underlineStyle != nullptr && [underlineStyle intValue] != NSUnderlineStyleNone) {
      found = YES;
      *stop = YES;
    }
  }];
  return found;
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  __block NSMutableArray<StylePair *> *occurences = [[NSMutableArray<StylePair *> alloc] init];
  [_editor->textView.textStorage enumerateAttribute:NSUnderlineStyleAttributeName
    inRange:range options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
    NSNumber *underlineStyle = (NSNumber *)value;
    if(underlineStyle != nullptr && [underlineStyle intValue] != NSUnderlineStyleNone) {
      StylePair *pair = [[StylePair alloc] init];
      pair.rangeValue = [NSValue valueWithRange:range];
      pair.styleValue = value;
      [occurences addObject:pair];
    }
  }];
  return occurences;
}

@end
