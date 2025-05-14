#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>
#import "EditorConfig.h"
#import "BaseStyleProtocol.h"

#ifndef ReactNativeRichTextEditorViewNativeComponent_h
#define ReactNativeRichTextEditorViewNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

@interface ReactNativeRichTextEditorView : RCTViewComponentView {
  @public UITextView *textView;
  @public EditorConfig *config;
  @public NSRange currentRange;
  @public NSDictionary<NSNumber *, id<BaseStyleProtocol>> *stylesDict;
}
- (CGSize)measureSize:(CGFloat)maxWidth;
@end

NS_ASSUME_NONNULL_END

#endif /* ReactNativeRichTextEditorViewNativeComponent_h */
