#import "StyleHeaders.h"
#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"
#import "ParagraphsUtils.h"
#import "TextInsertionUtils.h"
#import "ColorExtension.h"

@implementation CodeBlockStyle {
  EnrichedTextInputView *_input;
}

+ (StyleType)getStyleType { return CodeBlock; }

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
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
  NSTextList *codeBlockList = [[NSTextList alloc] initWithMarkerFormat:@"codeblock" options:0];
  NSArray *paragraphs = [ParagraphsUtils getSeparateParagraphsRangesIn:_input->textView range:range];
  // if we fill empty lines with zero width spaces, we need to offset later ranges
  NSInteger offset = 0;
  NSRange preModificationRange = _input->textView.selectedRange;
  
  // to not emit any space filling selection/text changes
  _input->blockEmitting = YES;

  for (NSValue *value in paragraphs) {
    NSRange pRange = NSMakeRange([value rangeValue].location + offset, [value rangeValue].length);
    // length 0 with first line, length 1 and newline with some empty lines in the middle
    if(pRange.length == 0 ||
      (pRange.length == 1 &&
      [[NSCharacterSet newlineCharacterSet] characterIsMember: [_input->textView.textStorage.string characterAtIndex:pRange.location]])
    ) {
      [TextInsertionUtils insertText:@"\u200B" at:pRange.location additionalAttributes:nullptr input:_input withSelection:NO];
      pRange = NSMakeRange(pRange.location, pRange.length + 1);
      offset += 1;
    }
    
    [_input->textView.textStorage enumerateAttribute:NSFontAttributeName
                                             inRange:pRange
                                             options:0
                                          usingBlock:^(id _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        UIFont *font = (UIFont *)value;
        if(font != nullptr) {
          UIFont *newFont = [[[_input->config monospacedFont] withFontTraits:font] setSize:font.pointSize];
          [_input->textView.textStorage addAttribute:NSFontAttributeName value:newFont range:range];
        }
    }];
    
    [_input->textView.textStorage enumerateAttribute:NSParagraphStyleAttributeName inRange:pRange options:0
      usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        NSMutableParagraphStyle *pStyle = [(NSParagraphStyle *)value mutableCopy];
        pStyle.textLists = @[codeBlockList];
        [_input->textView.textStorage addAttribute:NSParagraphStyleAttributeName value:pStyle range:range];
      }
    ];
  }
  
  // back to emitting
  _input->blockEmitting = NO;
  
  if(preModificationRange.length == 0) {
    // fix selection if only one line was possibly made a list and filled with a space
    _input->textView.selectedRange = preModificationRange;
  } else {
    // in other cases, fix the selection with newly made offsets
    _input->textView.selectedRange = NSMakeRange(preModificationRange.location, preModificationRange.length + offset);
  }
  
  // also add typing attributes
  NSMutableDictionary *typingAttrs = [_input->textView.typingAttributes mutableCopy];
  NSMutableParagraphStyle *pStyle = [typingAttrs[NSParagraphStyleAttributeName] mutableCopy];
  pStyle.textLists = @[codeBlockList];
  typingAttrs[NSParagraphStyleAttributeName] = pStyle;
  UIFont *currentFont = typingAttrs[NSFontAttributeName];
  if(currentFont != nullptr) {
    typingAttrs[NSFontAttributeName] = [[[_input->config monospacedFont] withFontTraits:currentFont] setSize:currentFont.pointSize];
  }
  
  _input->textView.typingAttributes = typingAttrs;
}

- (void)addTypingAttributes {
  [self addAttributes:_input->textView.selectedRange];
}

- (void)removeAttributes:(NSRange)range {
  NSArray *paragraphs = [ParagraphsUtils getSeparateParagraphsRangesIn:_input->textView range:range];
  
  [_input->textView.textStorage beginEditing];
  
  for(NSValue *value in paragraphs) {
    NSRange pRange = [value rangeValue];
    [_input->textView.textStorage enumerateAttribute:NSFontAttributeName inRange:pRange options:0
      usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        UIFont *font = (UIFont *)value;
        if(font != nullptr) {
          UIFont *newFont = [[[_input->config primaryFont] withFontTraits:font] setSize:font.pointSize];
          [_input->textView.textStorage addAttribute:NSFontAttributeName value:newFont range:range];
        }
      }
    ];
    
    [_input->textView.textStorage enumerateAttribute:NSParagraphStyleAttributeName inRange:range options:0
      usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        NSMutableParagraphStyle *pStyle = [(NSParagraphStyle *)value mutableCopy];
        pStyle.textLists = @[];
        [_input->textView.textStorage addAttribute:NSParagraphStyleAttributeName value:pStyle range:range];
      }
    ];
  }
  
  [_input->textView.textStorage endEditing];
  
  // also remove typing attributes
  NSMutableDictionary *typingAttrs = [_input->textView.typingAttributes mutableCopy];
  NSMutableParagraphStyle *pStyle = [typingAttrs[NSParagraphStyleAttributeName] mutableCopy];
  pStyle.textLists = @[];
  
  typingAttrs[NSParagraphStyleAttributeName] = pStyle;
  UIFont *currentFont = typingAttrs[NSFontAttributeName];
  if(currentFont != nullptr) {
    typingAttrs[NSFontAttributeName] = [[[_input->config primaryFont] withFontTraits:currentFont] setSize:currentFont.pointSize];
  }
  
  _input->textView.typingAttributes = typingAttrs;
}

- (void)removeTypingAttributes {
  [self removeAttributes:_input->textView.selectedRange];
}

- (BOOL)styleCondition:(id _Nullable)value :(NSRange)range {
  NSParagraphStyle *paragraph = (NSParagraphStyle *)value;
  return paragraph != nullptr && paragraph.textLists.count == 1 && [paragraph.textLists.firstObject.markerFormat  isEqual: @"codeblock"];
}

- (BOOL)detectStyle:(NSRange)range {
  if(range.length >= 1) {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName withInput:_input inRange:range
      withCondition: ^BOOL(id  _Nullable value, NSRange range) {
        return [self styleCondition:value :range];
      }
    ];
  } else {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName withInput:_input atIndex:range.location checkPrevious:YES
      withCondition:^BOOL(id  _Nullable value, NSRange range) {
        return [self styleCondition:value :range];
      }
    ];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSParagraphStyleAttributeName withInput:_input inRange:range
    withCondition:^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSParagraphStyleAttributeName withInput:_input inRange:range
    withCondition:^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

- (void)manageCodeBlockColor {
  if([[_input->config codeBlockFgColor] isEqualToColor:[_input->config primaryColor]]) {
    return;
  }
  
  NSRange wholeRange = NSMakeRange(0, _input->textView.textStorage.string.length);
  
  NSArray *paragraphs = [ParagraphsUtils getSeparateParagraphsRangesIn:_input->textView range:wholeRange];
  for(NSValue *pValue in paragraphs) {
    NSRange paragraphRange = [pValue rangeValue];
    BOOL selfDetected = [self detectStyle:paragraphRange];
    
    [_input->textView.textStorage enumerateAttribute:NSForegroundColorAttributeName inRange:paragraphRange options:0
      usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        UIColor *newColor = nullptr;
        BOOL colorApplied = [(UIColor *)value isEqualToColor:[_input->config codeBlockFgColor]];
        
        if(colorApplied && !selfDetected) {
          newColor = [_input->config primaryColor];
        } else if(!colorApplied && selfDetected) {
          newColor = [_input->config codeBlockFgColor];
        }
    
        if(newColor != nullptr) {
          [_input->textView.textStorage addAttribute:NSForegroundColorAttributeName value:newColor range:range];
          [_input->textView.textStorage addAttribute:NSUnderlineColorAttributeName value:newColor range:range];
          [_input->textView.textStorage addAttribute:NSStrikethroughColorAttributeName value:newColor range:range];
        }
      }
    ];
  }
}

@end
