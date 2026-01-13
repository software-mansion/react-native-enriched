#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"
#import "ParagraphsUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

@implementation CheckboxListStyle {
  EnrichedTextInputView *_input;
}

+ (StyleType)getStyleType {
  return CheckboxList;
}

+ (BOOL)isParagraphStyle {
  return YES;
}

- (CGFloat)getHeadIndent {
  return [_input->config checkboxListMarginLeft] +
         [_input->config checkboxListGapWidth];
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  return self;
}

- (void)applyStyle:(NSRange)range {
  BOOL isStylePresent = [self detectStyle:range];
  if (range.length >= 1) {
    isStylePresent ? [self removeAttributes:range]
                   : [self addAttributes:range withTypingAttr:YES];
  } else {
    isStylePresent ? [self removeTypingAttributes] : [self addTypingAttributes];
  }
}

- (void)addAttributes:(NSRange)range withTypingAttr:(BOOL)withTypingAttr {
}

- (void)addTypingAttributes {
}

- (void)removeAttributes:(NSRange)range {
}

- (void)removeTypingAttributes {
}

- (BOOL)handleBackspaceInRange:(NSRange)range replacementText:(NSString *)text {
}

- (BOOL)detectStyle:(NSRange)range {
}

- (NSArray<StylePair *> *)findAllOccurences:(NSRange)range {
}

- (BOOL)anyOccurence:(NSRange)range {
}

@end
