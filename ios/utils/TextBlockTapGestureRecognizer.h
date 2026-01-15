typedef NS_ENUM(NSInteger, TextBlockTapKind) {
  TextBlockTapKindNone = 0,
  TextBlockTapKindCheckbox,
};

@class EnrichedTextInputView;

@interface TextBlockTapGestureRecognizer : UITapGestureRecognizer

@property(nonatomic, weak) UITextView *textView;
@property(nonatomic, weak) EnrichedTextInputView *input;

@property(nonatomic, assign, readonly) TextBlockTapKind tapKind;
@property(nonatomic, assign, readonly) NSInteger characterIndex;

@end
