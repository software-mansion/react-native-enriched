#import <UIKit/UIKit.h>

@interface ZeroWidthSpaceUtils : NSObject
+ (void)handleZeroWidthSpacesInEditor:(id)editor;
+ (BOOL)handleBackspaceInRange:(NSRange)range replacementText:(NSString *)text editor:(id)editor;
@end
