#import <UIKit/UIKit.h>

@class EnrichedTextView;

@interface EnrichedTextTouchHandler : NSObject

@property(nonatomic, weak) EnrichedTextView *view;

- (instancetype)initWithView:(EnrichedTextView *)view;
- (void)handleTouchBeganAtPoint:(CGPoint)point;
- (void)handleTouchEndedAtPoint:(CGPoint)point;
- (void)handleTouchCancelled;

@end
