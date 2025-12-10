#import "StringExtension.h"

@implementation NSString (StringExtension)

- (std::string)toCppString {
  return std::string([self UTF8String]);
}

+ (NSString *)fromCppString:(std::string)string {
  return [NSString stringWithUTF8String:string.c_str()];
}

+ (NSString *)stringByEscapingHtml:(NSString *)html {
  NSMutableString *escaped = [html mutableCopy];
  NSDictionary *escapeMap = @{
    @"&" : @"&amp;",
    @"<" : @"&lt;",
    @">" : @"&gt;",
  };

  for (NSString *key in escapeMap) {
    [escaped replaceOccurrencesOfString:key
                             withString:escapeMap[key]
                                options:NSLiteralSearch
                                  range:NSMakeRange(0, escaped.length)];
  }
  return escaped;
}

+ (NSDictionary *)getEscapedCharactersInfoFrom:(NSString *)text {
  NSDictionary *unescapeMap = @{
    @"&amp;" : @"&",
    @"&lt;" : @"<",
    @"&gt;" : @">",
  };

  NSMutableDictionary *results = [[NSMutableDictionary alloc] init];

  for (NSString *key in unescapeMap) {
    NSRange searchRange = NSMakeRange(0, text.length);
    NSRange foundRange;

    while (searchRange.location < text.length) {
      foundRange = [text rangeOfString:key options:0 range:searchRange];
      if (foundRange.location == NSNotFound) {
        break;
      }
      results[@(foundRange.location)] = @[ key, unescapeMap[key] ];
      searchRange.location = foundRange.location + foundRange.length;
      searchRange.length = text.length - searchRange.location;
    }
  }

  return results;
}

@end

@implementation NSMutableString (StringExtension)

- (std::string)toCppString {
  return std::string([self UTF8String]);
}

+ (NSMutableString *)fromCppString:(std::string)string {
  return [NSMutableString stringWithUTF8String:string.c_str()];
}

@end
