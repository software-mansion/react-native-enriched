#pragma once
#import <ReactNativeEnriched/Props.h>
#import <UIKit/UIKit.h>

using namespace facebook::react;

@interface LinkRegexConfig : NSObject

@property NSString *pattern;
@property BOOL caseInsensitive;
@property BOOL dotAll;
@property BOOL isDisabled;
@property BOOL isDefault;

- (instancetype)initWithLinkRegexProp:
    (EnrichedTextInputViewLinkRegexStruct)prop;
- (BOOL)isEqualToConfig:(LinkRegexConfig *)otherObj;

@end
