#import "HtmlTagInterpreter.h"
#import "ImageData.h"
#import "MentionParams.h"
#import "StyleHeaders.h"
#import "StylePair.h"

@implementation HtmlTagInterpreter

- (NSMutableArray *)convertTags:(NSArray *)initiallyProcessedTags
                      plainText:(NSString *)plainText {
  // process tags into proper StyleType + StylePair values
  NSMutableArray *processedStyles = [[NSMutableArray alloc] init];

  for (NSArray *arr in initiallyProcessedTags) {
    NSString *tagName = (NSString *)arr[0];
    NSValue *tagRangeValue = (NSValue *)arr[1];
    NSMutableString *params = [[NSMutableString alloc] initWithString:@""];
    if (arr.count > 2) {
      [params appendString:(NSString *)arr[2]];
    }

    NSMutableArray *styleArr = [[NSMutableArray alloc] init];
    StylePair *stylePair = [[StylePair alloc] init];
    if ([tagName isEqualToString:@"b"]) {
      [styleArr addObject:@([BoldStyle getStyleType])];
    } else if ([tagName isEqualToString:@"i"]) {
      [styleArr addObject:@([ItalicStyle getStyleType])];
    } else if ([tagName isEqualToString:@"img"]) {
      NSRegularExpression *srcRegex =
          [NSRegularExpression regularExpressionWithPattern:@"src=\"([^\"]+)\""
                                                    options:0
                                                      error:nullptr];
      NSTextCheckingResult *match =
          [srcRegex firstMatchInString:params
                               options:0
                                 range:NSMakeRange(0, params.length)];

      if (match == nullptr) {
        continue;
      }

      NSRange srcRange = match.range;
      [styleArr addObject:@([ImageStyle getStyleType])];
      // cut only the uri from the src="..." string
      NSString *uri =
          [params substringWithRange:NSMakeRange(srcRange.location + 5,
                                                 srcRange.length - 6)];
      ImageData *imageData = [[ImageData alloc] init];
      imageData.uri = uri;

      NSRegularExpression *widthRegex = [NSRegularExpression
          regularExpressionWithPattern:@"width=\"([0-9.]+)\""
                               options:0
                                 error:nil];
      NSTextCheckingResult *widthMatch =
          [widthRegex firstMatchInString:params
                                 options:0
                                   range:NSMakeRange(0, params.length)];

      if (widthMatch) {
        NSString *widthString =
            [params substringWithRange:[widthMatch rangeAtIndex:1]];
        imageData.width = [widthString floatValue];
      }

      NSRegularExpression *heightRegex = [NSRegularExpression
          regularExpressionWithPattern:@"height=\"([0-9.]+)\""
                               options:0
                                 error:nil];
      NSTextCheckingResult *heightMatch =
          [heightRegex firstMatchInString:params
                                  options:0
                                    range:NSMakeRange(0, params.length)];

      if (heightMatch) {
        NSString *heightString =
            [params substringWithRange:[heightMatch rangeAtIndex:1]];
        imageData.height = [heightString floatValue];
      }

      stylePair.styleValue = imageData;
    } else if ([tagName isEqualToString:@"u"]) {
      [styleArr addObject:@([UnderlineStyle getStyleType])];
    } else if ([tagName isEqualToString:@"s"]) {
      [styleArr addObject:@([StrikethroughStyle getStyleType])];
    } else if ([tagName isEqualToString:@"code"]) {
      [styleArr addObject:@([InlineCodeStyle getStyleType])];
    } else if ([tagName isEqualToString:@"a"]) {
      NSRegularExpression *hrefRegex =
          [NSRegularExpression regularExpressionWithPattern:@"href=\".+\""
                                                    options:0
                                                      error:nullptr];
      NSTextCheckingResult *match =
          [hrefRegex firstMatchInString:params
                                options:0
                                  range:NSMakeRange(0, params.length)];

      if (match == nullptr) {
        // same as on Android, no href (or empty href) equals no link style
        continue;
      }

      NSRange hrefRange = match.range;
      [styleArr addObject:@([LinkStyle getStyleType])];
      // cut only the url from the href="..." string
      NSString *url =
          [params substringWithRange:NSMakeRange(hrefRange.location + 6,
                                                 hrefRange.length - 7)];
      stylePair.styleValue = url;
    } else if ([tagName isEqualToString:@"mention"]) {
      [styleArr addObject:@([MentionStyle getStyleType])];
      // extract html expression into dict using some regex
      NSMutableDictionary *paramsDict = [[NSMutableDictionary alloc] init];
      NSString *pattern = @"(\\w+)=\"([^\"]*)\"";
      NSRegularExpression *regex =
          [NSRegularExpression regularExpressionWithPattern:pattern
                                                    options:0
                                                      error:nil];

      [regex enumerateMatchesInString:params
                              options:0
                                range:NSMakeRange(0, params.length)
                           usingBlock:^(NSTextCheckingResult *_Nullable result,
                                        NSMatchingFlags flags,
                                        BOOL *_Nonnull stop) {
                             if (result.numberOfRanges == 3) {
                               NSString *key = [params
                                   substringWithRange:[result rangeAtIndex:1]];
                               NSString *value = [params
                                   substringWithRange:[result rangeAtIndex:2]];
                               paramsDict[key] = value;
                             }
                           }];

      MentionParams *mentionParams = [[MentionParams alloc] init];
      mentionParams.text = paramsDict[@"text"];
      mentionParams.indicator = paramsDict[@"indicator"];

      [paramsDict removeObjectsForKeys:@[ @"text", @"indicator" ]];
      NSError *error;
      NSData *attrsData = [NSJSONSerialization dataWithJSONObject:paramsDict
                                                          options:0
                                                            error:&error];
      NSString *formattedAttrsString =
          [[NSString alloc] initWithData:attrsData
                                encoding:NSUTF8StringEncoding];
      mentionParams.attributes = formattedAttrsString;

      stylePair.styleValue = mentionParams;
    } else if ([[tagName substringWithRange:NSMakeRange(0, 1)]
                   isEqualToString:@"h"]) {
      if ([tagName isEqualToString:@"h1"]) {
        [styleArr addObject:@([H1Style getStyleType])];
      } else if ([tagName isEqualToString:@"h2"]) {
        [styleArr addObject:@([H2Style getStyleType])];
      } else if ([tagName isEqualToString:@"h3"]) {
        [styleArr addObject:@([H3Style getStyleType])];
      }
    } else if ([tagName isEqualToString:@"ul"]) {
      [styleArr addObject:@([UnorderedListStyle getStyleType])];
    } else if ([tagName isEqualToString:@"ol"]) {
      [styleArr addObject:@([OrderedListStyle getStyleType])];
    } else if ([tagName isEqualToString:@"blockquote"]) {
      [styleArr addObject:@([BlockQuoteStyle getStyleType])];
    } else if ([tagName isEqualToString:@"codeblock"]) {
      [styleArr addObject:@([CodeBlockStyle getStyleType])];
    } else {
      // some other external tags like span just don't get put into the
      // processed styles
      continue;
    }

    stylePair.rangeValue = tagRangeValue;
    [styleArr addObject:stylePair];
    [processedStyles addObject:styleArr];
  }

  return processedStyles;
}

@end
