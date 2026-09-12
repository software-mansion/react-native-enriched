#import "EnrichedTextInputView.h"
#import "extensions/ColorExtension.h"
#import "interfaces/StyleHeaders.h"

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

- (CGFloat)headIndent {
  return [self.host.config blockquoteBorderWidth] +
         [self.host.config blockquoteGapWidth];
}

- (void)applyStyling:(NSRange)range {
  CGFloat indent = [self headIndent];
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

  UIColor *bqColor = [self.host.config blockquoteColor];
  if (bqColor != nil) {
    attributes[NSForegroundColorAttributeName] = bqColor;
    attributes[NSUnderlineColorAttributeName] = bqColor;
    attributes[NSStrikethroughColorAttributeName] = bqColor;
  }
}

@end
