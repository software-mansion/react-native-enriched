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
  // if we fill empty lines with spaces, we need to offset later ranges
  NSInteger offset = 0;
  NSRange preModificationRange = _editor->textView.selectedRange;
  
  // to not emit any space filling selection/text changes
  _editor->blockEmitting = YES;
  
  for(NSValue *value in paragraphs) {
    NSRange pRange = NSMakeRange([value rangeValue].location + offset, [value rangeValue].length);
    
    // length 0 with first line, length 1 and newline with some empty lines in the middle
    if(pRange.length == 0 ||
      (pRange.length == 1 &&
      [[NSCharacterSet newlineCharacterSet] characterIsMember: [_editor->textView.textStorage.string characterAtIndex:pRange.location]])
    ) {
      [TextInsertionUtils insertText:@" " inView:_editor->textView at:pRange.location additionalAttributes:nullptr editor:_editor];
      pRange = NSMakeRange(pRange.location, pRange.length + 1);
      offset += 1;
    }
    
    [_editor->textView.textStorage enumerateAttribute:NSParagraphStyleAttributeName inRange:pRange options:0
      usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        NSMutableParagraphStyle *pStyle = [(NSParagraphStyle *)value mutableCopy];
        pStyle.headIndent = [self getHeadIndent];
        pStyle.firstLineHeadIndent = [self getHeadIndent];
        [_editor->textView.textStorage addAttribute:NSParagraphStyleAttributeName value:pStyle range:range];
      }
    ];
  }
  
  // back to emitting
  _editor->blockEmitting = NO;
  
  if(preModificationRange.length == 0) {
    // fix selection if only one line was possibly made a list and filled with a space
    _editor->textView.selectedRange = preModificationRange;
  } else {
    // in other cases, fix the selection with newly made offsets
    _editor->textView.selectedRange = NSMakeRange(preModificationRange.location, preModificationRange.length + offset);
  }
  
  // also add typing attributes
  NSMutableDictionary *typingAttrs = [_editor->textView.typingAttributes mutableCopy];
  NSMutableParagraphStyle *pStyle = [typingAttrs[NSParagraphStyleAttributeName] mutableCopy];
  pStyle.headIndent = [self getHeadIndent];
  pStyle.firstLineHeadIndent = [self getHeadIndent];
  typingAttrs[NSParagraphStyleAttributeName] = pStyle;
  _editor->textView.typingAttributes = typingAttrs;
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
}

// needed for the sake of style conflicts, needs to do exactly the same as removeAttribtues
- (void)removeTypingAttributes {
  [self removeAttributes:_editor->textView.selectedRange];
}

// removing first quote line by backspacing doesn't remove typing attributes because it doesn't run textViewDidChange
// so we try guessing that a point should be deleted here
- (BOOL)handleBackspaceInRange:(NSRange)range replacementText:(NSString *)text {
  if([self detectStyle:_editor->textView.selectedRange] &&
     NSEqualRanges(_editor->textView.selectedRange, NSMakeRange(0, 0)) &&
     [text isEqualToString:@""]
  ) {
    NSRange paragraphRange = [_editor->textView.textStorage.string paragraphRangeForRange:_editor->textView.selectedRange];
    [self removeAttributes:paragraphRange];
    
    // if there is only a space left we should also remove it as it's our placeholder for empty quotes
    if([[_editor->textView.textStorage.string substringWithRange:paragraphRange] isEqualToString:@" "]) {
      [TextInsertionUtils replaceText:@"" inView:_editor->textView at:paragraphRange additionalAttributes:nullptr editor:_editor];
      return YES;
    }
  }
  return NO;
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
