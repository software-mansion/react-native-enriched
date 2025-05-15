#import <UIKit/UIKit.h>
#include "string"
#pragma once

@interface NSString (StringUtils)

- (std::string)toCppString;

+ (NSString *)fromCppString:(std::string)string;

@end

@interface NSMutableString (StringUtils)

- (std::string)toCppString;

+ (NSMutableString *)fromCppString:(std::string)string;

@end
