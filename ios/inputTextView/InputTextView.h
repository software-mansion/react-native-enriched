#pragma once
#import <UIkit/UIKit.h>

@interface InputTextView : UITextView
@property(nonatomic, weak) id input;
@property(nonatomic) BOOL textWasPasted;
@end
