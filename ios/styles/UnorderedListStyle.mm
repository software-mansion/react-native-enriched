#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"
#import "ParagraphsUtils.h"
#import "TextInsertionUtils.h"

@implementation UnorderedListStyle {
  ReactNativeRichTextEditorView *_editor;
}

+ (StyleType)getStyleType { return UnorderedList; }

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

// we assume correct paragraph range is already given
- (void)addAttributes:(NSRange)range {
  NSTextList *bullet = [[NSTextList alloc] initWithMarkerFormat:NSTextListMarkerDisc options:0];
  NSArray *paragraphs = [ParagraphsUtils getSeparateParagraphsRangesIn:_editor->textView range:range];
  // if we fill empty lines with spaces, we need to offset later ranges
  NSInteger offset = 0;
  // needed for range adjustments
  NSRange preModificationRange = _editor->textView.selectedRange;
  
  // let's not emit some weird selection changes or text/html changes
  _editor->blockEmitting = YES;
  
  for(NSValue *value in paragraphs) {
    // take previous offsets into consideration
    NSRange fixedRange = NSMakeRange([value rangeValue].location + offset, [value rangeValue].length);
    
    if(fixedRange.length == 0) {
      [TextInsertionUtils insertText:@" " inView:_editor->textView at:fixedRange.location additionalAttributes:nullptr];
      fixedRange = NSMakeRange(fixedRange.location, 1);
      offset += 1;
    }
    
    [_editor->textView.textStorage enumerateAttribute:NSParagraphStyleAttributeName inRange:fixedRange options:0
      usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        NSMutableParagraphStyle *pStyle = [(NSParagraphStyle *)value mutableCopy];
        pStyle.textLists = @[bullet];
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
  pStyle.textLists = @[bullet];
  typingAttrs[NSParagraphStyleAttributeName] = pStyle;
  _editor->textView.typingAttributes = typingAttrs;
    
  // safety check
  [_editor anyTextMayHaveBeenModified];
}

// does pretty much the same as normal addAttributes, just need to get the range
- (void)addTypingAttributes {
  [self addAttributes:_editor->textView.selectedRange];
}

- (void)removeAttributes:(NSRange)range {
  NSArray *paragraphs = [ParagraphsUtils getSeparateParagraphsRangesIn:_editor->textView range:range];
  
  [_editor->textView.textStorage beginEditing];
  
  for(NSValue *value in paragraphs) {
    NSRange range = [value rangeValue];
    [_editor->textView.textStorage enumerateAttribute:NSParagraphStyleAttributeName inRange:range options:0
      usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        NSMutableParagraphStyle *pStyle = [(NSParagraphStyle *)value mutableCopy];
        pStyle.textLists = @[];
        [_editor->textView.textStorage addAttribute:NSParagraphStyleAttributeName value:pStyle range:range];
      }
    ];
  }
  
  [_editor->textView.textStorage endEditing];
    
  // also remove typing attributes
  NSMutableDictionary *typingAttrs = [_editor->textView.typingAttributes mutableCopy];
  NSMutableParagraphStyle *pStyle = [typingAttrs[NSParagraphStyleAttributeName] mutableCopy];
  pStyle.textLists = @[];
  typingAttrs[NSParagraphStyleAttributeName] = pStyle;
  _editor->textView.typingAttributes = typingAttrs;
    
  // safety check
  [_editor anyTextMayHaveBeenModified];
}

// needed for the sake of style conflicts, needs to do exactly the same as removeAttribtues
- (void)removeTypingAttributes {
  [self removeAttributes:_editor->textView.selectedRange];
}

// removing first list point by backspacing doesn't remove typing attributes because it doesn't run textViewDidChange
// so we try guessing that a point should be deleted here
- (void)handleBackspaceInRange:(NSRange)range replacementText:(NSString *)text {
  if([self detectStyle:_editor->textView.selectedRange] &&
     NSEqualRanges(_editor->textView.selectedRange, NSMakeRange(0, 0)) &&
     [text isEqualToString:@""]
  ) {
    NSRange paragraphRange = [_editor->textView.textStorage.string paragraphRangeForRange:_editor->textView.selectedRange];
    [self removeAttributes:paragraphRange];
  }
}

- (BOOL)styleCondition:(id _Nullable)value :(NSRange)range {
  NSParagraphStyle *paragraph = (NSParagraphStyle *)value;
  return paragraph != nullptr && paragraph.textLists.count > 0;
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
      return pStyle != nullptr && pStyle.textLists.count > 0;
    }
    
    NSRange paragraphRange = NSMakeRange(0, 0);
    NSRange editorRange = NSMakeRange(0, _editor->textView.textStorage.length);
    NSParagraphStyle *paragraph = [_editor->textView.textStorage
      attribute:NSParagraphStyleAttributeName
      atIndex:searchLocation
      longestEffectiveRange: &paragraphRange
      inRange:editorRange
    ];
    
    return paragraph != nullptr && paragraph.textLists.count > 0;
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
