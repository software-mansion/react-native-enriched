#pragma once
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
  @public NSDictionary<NSNumber *, id<BaseStyleProtocol>> *stylesDict;
  @public NSDictionary<NSNumber *, NSArray<NSNumber *> *> *conflictingStyles;
  @public NSDictionary<NSNumber *, NSArray<NSNumber *> *> *blockingStyles;
}
- (CGSize)measureSize:(CGFloat)maxWidth;
- (void)emitOnLinkDetectedEvent:(NSString *)text url:(NSString *)url;
- (void)emitOnMentionEvent:(NSString *)indicator text:(nullable NSString *)text;
@end

NS_ASSUME_NONNULL_END

#endif /* ReactNativeRichTextEditorViewNativeComponent_h */
