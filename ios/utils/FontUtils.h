#import <UIKit/UIKit.h>
#import <EditorConfig.h>

@interface UIFont (FontUtils)

- (BOOL)isBold;
- (UIFont *)setBold;
- (UIFont *)removeBold;
- (BOOL)isItalic;
- (UIFont *)setItalic;
- (UIFont *)removeItalic;
- (BOOL)isMonospace:(EditorConfig *)withConfig;
- (UIFont *)withFontTraits:(UIFont *)from;

@end
