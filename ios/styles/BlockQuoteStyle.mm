#import "ColorExtension.h"
#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation BlockQuoteStyle

+ (StyleType)getType {
  return BlockQuote;
}

- (NSString *)getValue {
  return @"EnrichedBlockQuote";
}

- (BOOL)isParagraph {
  return YES;
}

- (BOOL)needsZWS {
  return YES;
}

- (void)applyStyling:(NSRange)range {
  CGFloat indent = [self.host.config blockquoteBorderWidth] +
                   [self.host.config blockquoteGapWidth];
  [self.host.textView.textStorage
      enumerateAttribute:NSParagraphStyleAttributeName
                 inRange:range
                 options:0
              usingBlock:^(id _Nullable value, NSRange subRange,
                           BOOL *_Nonnull stop) {
                NSMutableParagraphStyle *pStyle =
                    [(NSParagraphStyle *)value mutableCopy];
                pStyle.headIndent = indent;
                pStyle.firstLineHeadIndent = indent;
                [self.host.textView.textStorage
                    addAttribute:NSParagraphStyleAttributeName
                           value:pStyle
                           range:subRange];
              }];

  UIColor *bqColor = [self.host.config blockquoteColor];
  [self.host.textView.textStorage addAttribute:NSForegroundColorAttributeName
                                         value:bqColor
                                         range:range];
  [self.host.textView.textStorage addAttribute:NSUnderlineColorAttributeName
                                         value:bqColor
                                         range:range];
  [self.host.textView.textStorage addAttribute:NSStrikethroughColorAttributeName
                                         value:bqColor
                                         range:range];
}

@end
