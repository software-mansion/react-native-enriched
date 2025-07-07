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
    @"&": @"&amp;",
    @"<": @"&lt;",
    @">": @"&gt;",
    @"\"": @"&quot;",
    @"'": @"&apos;"
  };
  
  for(NSString *key in escapeMap) {
    [escaped replaceOccurrencesOfString:key withString:escapeMap[key] options:NSLiteralSearch range:NSMakeRange(0, escaped.length)];
  }
  return escaped;
}

+ (NSString *)stringByUnescapingHtml:(NSString *)html {
  NSMutableString *unescaped = [html mutableCopy];
  NSDictionary *unescapeMap = @{
    @"&amp;": @"&",
    @"&lt;": @"<",
    @"&gt;": @">",
    @"&quot;": @"\"",
    @"&apos;": @"'",
  };
  
  for(NSString *key in unescapeMap) {
    [unescaped replaceOccurrencesOfString:key withString:unescapeMap[key] options:NSLiteralSearch range:NSMakeRange(0, unescaped.length)];
  }
  return unescaped;
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
