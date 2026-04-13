#import "EnrichedTouchableTextView.h"
#import "EnrichedTextTouchHandler.h"

@implementation EnrichedTouchableTextView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  if (touches.count == 1) {
    UITouch *touch = touches.anyObject;
    CGPoint point = [touch locationInView:self];
    [self.touchHandler handleTouchBeganAtPoint:point];
  }
  [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  if (touches.count == 1) {
    UITouch *touch = touches.anyObject;
    CGPoint point = [touch locationInView:self];
    [self.touchHandler handleTouchEndedAtPoint:point];
  }
  [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches
               withEvent:(UIEvent *)event {
  [self.touchHandler handleTouchCancelled];
  [super touchesCancelled:touches withEvent:event];
}

@end
