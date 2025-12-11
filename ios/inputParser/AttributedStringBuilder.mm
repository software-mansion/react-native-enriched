#import "AttributedStringBuilder.h"
#import "StyleHeaders.h"
#import "StylePair.h"

@implementation AttributedStringBuilder

- (void)apply:(NSArray *)processedStyles
     toAttributedString:(NSMutableAttributedString *)attributedString
    offsetFromBeginning:(NSInteger)offset {
  NSArray *sorted = [processedStyles
      sortedArrayUsingComparator:^NSComparisonResult(NSArray *a, NSArray *b) {
        StylePair *pa = a[1];
        StylePair *pb = b[1];

        NSInteger la = offset + pa.rangeValue.rangeValue.location;
        NSInteger lb = offset + pb.rangeValue.rangeValue.location;
        return (la < lb ? NSOrderedDescending
                        : (la > lb ? NSOrderedAscending : NSOrderedSame));
      }];

  [attributedString beginEditing];

  for (NSArray *arr in sorted) {
    NSNumber *type = arr[0];
    StylePair *pair = arr[1];

    NSRange r = NSMakeRange(offset + pair.rangeValue.rangeValue.location,
                            pair.rangeValue.rangeValue.length);

    id<BaseStyleProtocol> style = self.stylesDict[type];

    if ([type isEqualToNumber:@([LinkStyle getStyleType])]) {
      NSString *text = [attributedString.string substringWithRange:r];
      NSString *url = pair.styleValue;
      BOOL isManual = [text isEqualToString:url];
      [(LinkStyle *)style addLinkInAttributedString:attributedString
                                              range:r
                                               text:text
                                                url:url
                                             manual:isManual];

    } else if ([type isEqualToNumber:@([MentionStyle getStyleType])]) {
      [(MentionStyle *)style addMentionInAttributedString:attributedString
                                                    range:r
                                                   params:pair.styleValue];

    } else if ([type isEqualToNumber:@([ImageStyle getStyleType])]) {
      [(ImageStyle *)style addImageInAttributedString:attributedString
                                                range:r
                                            imageData:pair.styleValue];

    } else {
      [style addAttributesInAttributedString:attributedString range:r];
    }
  }

  [attributedString endEditing];
}

@end
