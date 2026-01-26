typedef NS_ENUM(NSInteger, TextBlockTapKind) {
  TextBlockTapKindNone = 0,
  TextBlockTapKindCheckbox,
};

@class EnrichedTextInputView;

@interface TextBlockTapGestureRecognizer : UITapGestureRecognizer
- (instancetype _Nonnull)initWithInput:(id _Nonnull)input
                                action:(SEL _Nonnull)action;

@property(nonatomic, weak) EnrichedTextInputView *input;

@property(nonatomic, assign, readonly) TextBlockTapKind tapKind;
@property(nonatomic, assign, readonly) NSInteger characterIndex;

@end
