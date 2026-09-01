#import "EnrichedTextInputView.h"
#import "interfaces/StyleHeaders.h"
#import "utils/RangeUtils.h"
#import "utils/StyleUtils.h"
#import "utils/TextInsertionUtils.h"

@implementation OrderedListStyle

+ (StyleType)getType {
  return OrderedList;
}

- (NSString *)getValue {
  return @"EnrichedOrderedList";
}

- (BOOL)isParagraph {
  return YES;
}

- (BOOL)needsZWS {
  return YES;
}

- (CGFloat)headIndent {
  return [self.host.config orderedListMarginLeft] +
         [self.host.config orderedListGapWidth];
}

- (void)applyStyling:(NSRange)range {
  // lists are drawn manually
  // margin before marker + gap between marker and paragraph
  CGFloat listHeadIndent = [self headIndent];

  [self.host.textView.textStorage
      enumerateAttribute:NSParagraphStyleAttributeName
                 inRange:range
                 options:0
              usingBlock:^(id _Nullable value, NSRange range,
                           BOOL *_Nonnull stop) {
                NSMutableParagraphStyle *pStyle =
                    [(NSParagraphStyle *)value mutableCopy];
                pStyle.headIndent = listHeadIndent;
                pStyle.firstLineHeadIndent = listHeadIndent;
                [self.host.textView.textStorage
                    addAttribute:NSParagraphStyleAttributeName
                           value:pStyle
                           range:range];
              }];
}

- (BOOL)appliesStylingToTyping {
  return YES;
}

- (void)applyStylingToTypingAttrs:(NSMutableDictionary *)attributes {
  NSMutableParagraphStyle *pStyle =
      [attributes[NSParagraphStyleAttributeName] mutableCopy];
  if (pStyle == nil)
    return;
  CGFloat indent = [self headIndent];
  pStyle.headIndent = indent;
  pStyle.firstLineHeadIndent = indent;
  attributes[NSParagraphStyleAttributeName] = pStyle;
}

@end
