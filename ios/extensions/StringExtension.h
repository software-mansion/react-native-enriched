#include "string"
#import <UIKit/UIKit.h>
#pragma once

@interface NSString (StringExtension)
- (std::string)toCppString;
+ (NSString *)fromCppString:(std::string)string;
+ (NSString *)stringByEscapingHtml:(NSString *)html;
+ (NSDictionary *)getEscapedCharactersInfoFrom:(NSString *)text;
@end

@interface NSMutableString (StringExtension)
- (std::string)toCppString;
+ (NSMutableString *)fromCppString:(std::string)string;
@end
