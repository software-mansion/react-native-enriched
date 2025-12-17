#import "TagHandlersFactory.h"

#import "ImageData.h"
#import "MentionParams.h"
#import "StyleHeaders.h"
#import "StylePair.h"

NSDictionary<NSString *, TagHandler> *MakeTagHandlers(void) {
  static NSDictionary<NSString *, TagHandler> *taghandlers;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    taghandlers =
        @{@"b" : ^(NSString *params, StylePair *pair, NSMutableArray *styleArr){
            [styleArr addObject:@([BoldStyle getStyleType])];
          },
          @"strong": ^(NSString *params, StylePair *pair, NSMutableArray *styleArr) { // alias
    [styleArr addObject:@([BoldStyle getStyleType])];
          },
          @"i": ^(NSString *params, StylePair *pair, NSMutableArray *styleArr) {
    [styleArr addObject:@([ItalicStyle getStyleType])];
          },

          @"em": ^(NSString *params, StylePair *pair, NSMutableArray *styleArr) { // alias
    [styleArr addObject:@([ItalicStyle getStyleType])];
          },

          @"u": ^(NSString *params, StylePair *pair, NSMutableArray *styleArr) {
    [styleArr addObject:@([UnderlineStyle getStyleType])];
          },

          @"s": ^(NSString *params, StylePair *pair, NSMutableArray *styleArr) {
    [styleArr addObject:@([StrikethroughStyle getStyleType])];
          },

          @"code": ^(NSString *params, StylePair *pair, NSMutableArray *styleArr) {
    [styleArr addObject:@([InlineCodeStyle getStyleType])];
          },
          @"img": ^(NSString *params, StylePair *pair, NSMutableArray *styleArr) {
    ImageData *img = [ImageData new];

    NSRegularExpression *srcRegex =
        [NSRegularExpression regularExpressionWithPattern:@"src=\"([^\"]+)\""
                                                  options:0
                                                    error:nil];
    NSTextCheckingResult *sercMatch =
        [srcRegex firstMatchInString:params
                             options:0
                               range:NSMakeRange(0, params.length)];
    if (!sercMatch)
      return;

    img.uri = [params substringWithRange:[sercMatch rangeAtIndex:1]];

    NSRegularExpression *widthRegex =
        [NSRegularExpression regularExpressionWithPattern:@"width=\"([0-9.]+)\""
                                                  options:0
                                                    error:nil];
    NSTextCheckingResult *widthMatch =
        [widthRegex firstMatchInString:params
                               options:0
                                 range:NSMakeRange(0, params.length)];
    if (widthMatch) {
      img.width =
          [[params substringWithRange:[widthMatch rangeAtIndex:1]] floatValue];
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
      img.height =
          [[params substringWithRange:[heightMatch rangeAtIndex:1]] floatValue];
    }

    pair.styleValue = img;
    [styleArr addObject:@([ImageStyle getStyleType])];
          },
          @"a": ^(NSString *params, StylePair *pair, NSMutableArray *styleArr) {
    NSRegularExpression *hrefRegex =
        [NSRegularExpression regularExpressionWithPattern:@"href=\"([^\"]*)\""
                                                  options:0
                                                    error:nil];

    NSTextCheckingResult *match =
        [hrefRegex firstMatchInString:params
                              options:0
                                range:NSMakeRange(0, params.length)];

    if (!match)
      return;
    NSString *url = [params substringWithRange:[match rangeAtIndex:1]];

    pair.styleValue = url;
    [styleArr addObject:@([LinkStyle getStyleType])];
          },
          @"mention": ^(NSString *params, StylePair *pair, NSMutableArray *styleArr) {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    NSRegularExpression *re =
        [NSRegularExpression regularExpressionWithPattern:@"(\\w+)=\"([^\"]*)\""
                                                  options:0
                                                    error:nil];

    [re enumerateMatchesInString:params
                         options:0
                           range:NSMakeRange(0, params.length)
                      usingBlock:^(NSTextCheckingResult *res,
                                   NSMatchingFlags flags, BOOL *stop) {
                        if (res.numberOfRanges == 3) {
                          NSString *k =
                              [params substringWithRange:[res rangeAtIndex:1]];
                          NSString *v =
                              [params substringWithRange:[res rangeAtIndex:2]];
                          dict[k] = v;
                        }
                      }];

    MentionParams *mp = [MentionParams new];
    mp.text = dict[@"text"];
    mp.indicator = dict[@"indicator"];

    [dict removeObjectsForKeys:@[ @"text", @"indicator" ]];
    NSData *json = [NSJSONSerialization dataWithJSONObject:dict
                                                   options:0
                                                     error:nil];
    mp.attributes = [[NSString alloc] initWithData:json
                                          encoding:NSUTF8StringEncoding];

    pair.styleValue = mp;
    [styleArr addObject:@([MentionStyle getStyleType])];
          },
          @"h1": ^(NSString *params, StylePair *pair, NSMutableArray *styleArr) {
    [styleArr addObject:@([H1Style getStyleType])];
          },
          @"h2": ^(NSString *params, StylePair *pair, NSMutableArray *styleArr) {
    [styleArr addObject:@([H2Style getStyleType])];
          },
          @"h3": ^(NSString *params, StylePair *pair, NSMutableArray *styleArr) {
    [styleArr addObject:@([H3Style getStyleType])];
          },
          @"ul": ^(NSString *params, StylePair *pair, NSMutableArray *styleArr) {
    [styleArr addObject:@([UnorderedListStyle getStyleType])];
          },
          @"ol": ^(NSString *params, StylePair *pair, NSMutableArray *styleArr) {
    [styleArr addObject:@([OrderedListStyle getStyleType])];
          },
          @"blockquote": ^(NSString *params, StylePair *pair, NSMutableArray *styleArr) {
    [styleArr addObject:@([BlockQuoteStyle getStyleType])];
          },
          @"codeblock": ^(NSString *params, StylePair *pair, NSMutableArray *styleArr) {
    [styleArr addObject:@([CodeBlockStyle getStyleType])];
          },
};
});

return taghandlers;
}
