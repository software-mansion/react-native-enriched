#pragma once

#import <UIKit/UIKit.h>

@class EnrichedTextTouchHandler;
@class EnrichedTextView;

// Forwards single-finger touches to `EnrichedTextTouchHandler` before `super`
// so link/mention pressed styling is not delayed by `UITextView` gesture
// arbitration.
@interface EnrichedTextTextView : UITextView

@property(nonatomic, weak) EnrichedTextTouchHandler *touchHandler;
@property(nonatomic, weak) EnrichedTextView *host;

@end
