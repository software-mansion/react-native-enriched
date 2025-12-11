#pragma once
#import "TextDecorationLineEnum.h"
#import "string"
#import <UIKit/UIKit.h>
#import <folly/dynamic.h>

@interface MentionStyleProps : NSObject
@property UIColor *color;
@property UIColor *backgroundColor;
@property TextDecorationLineEnum decorationLine;
+ (NSDictionary *)getSinglePropsFromFollyDynamic:(folly::dynamic)folly;
+ (NSDictionary *)getComplexPropsFromFollyDynamic:(folly::dynamic)folly;
@end
