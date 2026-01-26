#import "TextBlockTapGestureRecognizer.h"
#import "CheckboxHitTestUtils.h"
#import "EnrichedTextInputView.h"

@implementation TextBlockTapGestureRecognizer {
  TextBlockTapKind _tapKind;
  NSInteger _characterIndex;
}

- (instancetype)initWithInput:(id)input action:(SEL)action {
  self = [super initWithTarget:input action:action];
  _input = input;

  self.cancelsTouchesInView = YES;
  self.delaysTouchesBegan = YES;
  self.delaysTouchesEnded = YES;

  for (UIGestureRecognizer *gr in _input->textView.gestureRecognizers) {
    [gr requireGestureRecognizerToFail:self];
  }

  return self;
}

- (TextBlockTapKind)tapKind {
  return _tapKind;
}

- (NSInteger)characterIndex {
  return _characterIndex;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  _tapKind = TextBlockTapKindNone;
  _characterIndex = NSNotFound;

  if (!self.input) {
    self.state = UIGestureRecognizerStateFailed;
    return;
  }

  UITouch *touch = touches.anyObject;
  CGPoint point = [touch locationInView:self.input->textView];
  NSInteger checkboxIndex =
      [CheckboxHitTestUtils hitTestCheckboxAtPoint:point inInput:self.input];

  if (checkboxIndex >= 0) {
    _tapKind = TextBlockTapKindCheckbox;
    _characterIndex = checkboxIndex;
    [super touchesBegan:touches withEvent:event];
    return;
  }
  self.state = UIGestureRecognizerStateFailed;
}

@end
