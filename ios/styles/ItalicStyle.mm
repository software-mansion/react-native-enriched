#import "EnrichedTextInputView.h"
#import "interfaces/StyleHeaders.h"
#import "utils/ItalicUtils.h"

@implementation ItalicStyle : StyleBase

+ (StyleType)getType {
  return Italic;
}

- (NSString *)getKey {
  return @"EnrichedItalic";
}

- (BOOL)isParagraph {
  return NO;
}

// some styles might apply a new font (inline code), so we need to apply
// the italic last, that way we know if the used font supports italics
// or we need to apply a slant
- (NSInteger)stylePriority {
  return 3;
}

- (void)applyStyling:(NSRange)range {
  if (self.host.textView.textStorage == nullptr || range.length == 0 ||
      NSMaxRange(range) > self.host.textView.textStorage.length) {
    return;
  }

  // we process each present font
  [self.host.textView.textStorage
      enumerateAttribute:NSFontAttributeName
                 inRange:range
                 options:0
              usingBlock:^(id _Nullable value, NSRange fontRange,
                           BOOL *_Nonnull stop) {
                UIFont *font = (UIFont *)value;
                if (font == nullptr) {
                  return;
                }
                [ItalicUtils applyItalicForFont:font
                                  inTextStorage:self.host.textView.textStorage
                                        inRange:fontRange];
              }];
}

@end
