#import "AttributedStringBuilder.h"
#import "StyleHeaders.h"
#import "StylePair.h"

@implementation AttributedStringBuilder

- (void)apply:(NSArray *)processedStyles
     toAttributedString:(NSMutableAttributedString *)attributedString
    offsetFromBeginning:(NSInteger)offset
      conflictingStyles:
          (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)conflictingStyles {
  [attributedString beginEditing];

  for (NSArray *processedStylePair in processedStyles) {
    NSNumber *type = processedStylePair[0];
    StylePair *pair = processedStylePair[1];

    NSRange pairRange = [pair.rangeValue rangeValue];
    NSRange range = NSMakeRange(offset + pairRange.location, pairRange.length);
    if (![self canApplyStyle:type
                       range:range
            attributedString:attributedString
              conflictingMap:conflictingStyles
                  stylesDict:self.stylesDict]) {
      continue;
    }

    id<BaseStyleProtocol> style = self.stylesDict[type];

    if ([type isEqualToNumber:@([LinkStyle getStyleType])]) {
      NSString *text = [attributedString.string substringWithRange:range];
      NSString *url = pair.styleValue;
      BOOL isManual = [text isEqualToString:url];
      [(LinkStyle *)style addLinkInAttributedString:attributedString
                                              range:range
                                               text:text
                                                url:url
                                             manual:isManual];

    } else if ([type isEqualToNumber:@([MentionStyle getStyleType])]) {
      [(MentionStyle *)style addMentionInAttributedString:attributedString
                                                    range:range
                                                   params:pair.styleValue];

    } else if ([type isEqualToNumber:@([ImageStyle getStyleType])]) {
      [(ImageStyle *)style addImageInAttributedString:attributedString
                                                range:range
                                            imageData:pair.styleValue];
    } else {
      [style addAttributesInAttributedString:attributedString range:range];
    }
  }

  [attributedString endEditing];
}

- (BOOL)canApplyStyle:(NSNumber *)type
                range:(NSRange)range
     attributedString:(NSAttributedString *)string
       conflictingMap:(NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)confMap
           stylesDict:
               (NSDictionary<NSNumber *, id<BaseStyleProtocol>> *)stylesDict {
  NSArray<NSNumber *> *conflicts = confMap[type];
  if (!conflicts || conflicts.count == 0)
    return YES;

  for (NSNumber *conflictType in conflicts) {
    id<BaseStyleProtocol> conflictStyle = stylesDict[conflictType];
    if (!conflictStyle)
      continue;

    NSArray<StylePair *> *occurrences =
        [conflictStyle findAllOccurencesInAttributedString:string range:range];

    if (occurrences.count > 0) {
      return NO;
    }
  }

  return YES;
}
@end
