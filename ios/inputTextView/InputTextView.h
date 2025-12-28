#pragma once
#import <UIkit/UIKit.h>

@interface InputTextView : UITextView
@property(nonatomic, weak) id input;
@property(nonatomic, copy, nullable) NSString *placeholderText;
@property(nonatomic, strong, nullable) UIColor *placeholderColor;
- (void)updatePlaceholderVisibility;
@end
