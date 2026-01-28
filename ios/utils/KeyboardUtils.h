#import <UIKit/UIKit.h>
#pragma once

@interface KeyboardUtils : NSObject
+ (UIReturnKeyType)getUIReturnKeyTypeFromReturnKeyType:
    (NSString *)returnKeyType;
@end
