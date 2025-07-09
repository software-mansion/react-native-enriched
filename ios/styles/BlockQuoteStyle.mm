#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"
#import "OccurenceUtils.h"
#import "ParagraphsUtils.h"
#import "TextInsertionUtils.h"

@implementation BlockQuoteStyle {
  ReactNativeRichTextEditorView *_editor;
}

+ (StyleType)getStyleType { return BlockQuote; }

- (instancetype)initWithEditor:(id)editor {
  self = [super init];
  _editor = (ReactNativeRichTextEditorView *) editor;
  return self;
}

- (CGFloat)getHeadIndent {
  // rectangle width + gap
  return [_editor->config blockquoteWidth] + [_editor->config blockquoteGapWidth];
}

// the range will already be the full paragraph/s range
- (void)applyStyle:(NSRange)range {
  BOOL isStylePresent = [self detectStyle:range];
  if(range.length >= 1) {
    isStylePresent ? [self removeAttributes:range] : [self addAttributes:range];
  } else {
    isStylePresent ? [self removeTypingAttributes] : [self addTypingAttributes];
  }
}

- (void)addAttributes:(NSRange)range {
  NSArray *paragraphs = [ParagraphsUtils getSeparateParagraphsRangesIn:_editor->textView range:range];
  
  for(NSValue *value in paragraphs) {
    NSRange pRange = [value rangeValue];
    [_editor->textView.textStorage enumerateAttribute:NSParagraphStyleAttributeName inRange:pRange options:0
      usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        NSMutableParagraphStyle *pStyle = [(NSParagraphStyle *)value mutableCopy];
        pStyle.headIndent = [self getHeadIndent];
        pStyle.firstLineHeadIndent = [self getHeadIndent];
        [_editor->textView.textStorage addAttribute:NSParagraphStyleAttributeName value:pStyle range:range];
      }
    ];
  }
  
  // also add typing attributes
  NSMutableDictionary *typingAttrs = [_editor->textView.typingAttributes mutableCopy];
  NSMutableParagraphStyle *pStyle = [typingAttrs[NSParagraphStyleAttributeName] mutableCopy];
  pStyle.headIndent = [self getHeadIndent];
  pStyle.firstLineHeadIndent = [self getHeadIndent];
  typingAttrs[NSParagraphStyleAttributeName] = pStyle;
  _editor->textView.typingAttributes = typingAttrs;
      
  // safety check
  [_editor anyTextMayHaveBeenModified];
}

// does pretty much the same as addAttributes
- (void)addTypingAttributes {
  [self addAttributes:_editor->textView.selectedRange];
}

- (void)removeAttributes:(NSRange)range {
  NSArray *paragraphs = [ParagraphsUtils getSeparateParagraphsRangesIn:_editor->textView range:range];
  
  for(NSValue *value in paragraphs) {
    NSRange pRange = [value rangeValue];
    [_editor->textView.textStorage enumerateAttribute:NSParagraphStyleAttributeName inRange:pRange options:0
      usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        NSMutableParagraphStyle *pStyle = [(NSParagraphStyle *)value mutableCopy];
        pStyle.headIndent = 0;
        pStyle.firstLineHeadIndent = 0;
        [_editor->textView.textStorage addAttribute:NSParagraphStyleAttributeName value:pStyle range:range];
      }
    ];
  }
  
  // also remove typing attributes
  NSMutableDictionary *typingAttrs = [_editor->textView.typingAttributes mutableCopy];
  NSMutableParagraphStyle *pStyle = [typingAttrs[NSParagraphStyleAttributeName] mutableCopy];
  pStyle.headIndent = 0;
  pStyle.firstLineHeadIndent = 0;
  typingAttrs[NSParagraphStyleAttributeName] = pStyle;
  _editor->textView.typingAttributes = typingAttrs;
    
  // safety check
  [_editor anyTextMayHaveBeenModified];
}

// needed for the sake of style conflicts, needs to do exactly the same as removeAttribtues
- (void)removeTypingAttributes {
  [self removeAttributes:_editor->textView.selectedRange];
}

- (BOOL)styleCondition:(id _Nullable)value :(NSRange)range {
  NSParagraphStyle *pStyle = (NSParagraphStyle *)value;
  return pStyle != nullptr && pStyle.headIndent == [self getHeadIndent] && pStyle.firstLineHeadIndent == [self getHeadIndent] && pStyle.textLists.count == 0;
}

- (BOOL)detectStyle:(NSRange)range {
  if(range.length >= 1) {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName withEditor:_editor inRange:range
      withCondition: ^BOOL(id  _Nullable value, NSRange range) {
        return [self styleCondition:value :range];
      }
    ];
  } else {
    NSInteger searchLocation = range.location;
    if(searchLocation == _editor->textView.textStorage.length) {
      NSParagraphStyle *pStyle = _editor->textView.typingAttributes[NSParagraphStyleAttributeName];
      return [self styleCondition:pStyle :NSMakeRange(0, 0)];
    }
    
    NSRange paragraphRange = NSMakeRange(0, 0);
    NSRange editorRange = NSMakeRange(0, _editor->textView.textStorage.length);
    NSParagraphStyle *paragraph = [_editor->textView.textStorage
      attribute:NSParagraphStyleAttributeName
      atIndex:searchLocation
      longestEffectiveRange: &paragraphRange
      inRange:editorRange
    ];
    
    return [self styleCondition:paragraph :NSMakeRange(0, 0)];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSParagraphStyleAttributeName withEditor:_editor inRange:range
    withCondition:^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSParagraphStyleAttributeName withEditor:_editor inRange:range
    withCondition:^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

@end
