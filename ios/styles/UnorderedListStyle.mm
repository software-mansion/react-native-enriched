#import "EnrichedTextInputView.h"
#import "RangeUtils.h"
#import "StyleHeaders.h"
#import "StyleUtils.h"
#import "TextInsertionUtils.h"

@implementation UnorderedListStyle

+ (StyleType)getType {
  return UnorderedList;
}

- (NSString *)getValue {
  return @"EnrichedUnorderedList";
}

- (BOOL)isParagraph {
  return YES;
}

- (BOOL)needsZWS {
  return YES;
}

- (void)applyStyling:(NSRange)range {
  // lists are drawn manually
  // margin before bullet + gap between bullet and paragraph
  CGFloat listHeadIndent = [self.host.config unorderedListMarginLeft] +
                           [self.host.config unorderedListGapWidth];

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

@end
