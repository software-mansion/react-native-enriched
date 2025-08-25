#import <UIKit/UIKit.h>
#pragma once

@interface ZeroWidthSpaceUtils : NSObject
+ (void)handleZeroWidthSpacesInEditor:(id)editor;
+ (BOOL)handleBackspaceInRange:(NSRange)range replacementText:(NSString *)text editor:(id)editor;
@end
