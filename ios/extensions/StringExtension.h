#import <UIKit/UIKit.h>
#include "string"
#pragma once

@interface NSString (StringExtension)

- (std::string)toCppString;

+ (NSString *)fromCppString:(std::string)string;

@end

@interface NSMutableString (StringExtension)

- (std::string)toCppString;

+ (NSMutableString *)fromCppString:(std::string)string;

@end
