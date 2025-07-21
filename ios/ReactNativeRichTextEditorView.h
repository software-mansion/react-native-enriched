#pragma once
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>
#import "EditorConfig.h"
#import "EditorParser.h"
#import "BaseStyleProtocol.h"

#ifndef ReactNativeRichTextEditorViewNativeComponent_h
#define ReactNativeRichTextEditorViewNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

@interface ReactNativeRichTextEditorView : RCTViewComponentView {
  @public UITextView *textView;
  @public NSRange recentlyChangedRange;
  @public EditorConfig *config;
  @public EditorParser *parser;
  @public NSMutableDictionary<NSAttributedStringKey, id> *defaultTypingAttributes;
  @public NSDictionary<NSNumber *, id<BaseStyleProtocol>> *stylesDict;
  @public BOOL blockEmitting;
  @public BOOL emitHtml;
}
- (CGSize)measureSize:(CGFloat)maxWidth;
- (void)emitOnLinkDetectedEvent:(NSString *)text url:(NSString *)url;
- (void)emitOnMentionEvent:(NSString *)indicator text:(nullable NSString *)text;
- (void)anyTextMayHaveBeenModified;
- (BOOL)handleStyleBlocksAndConflicts:(StyleType)type range:(NSRange)range;
@end

NS_ASSUME_NONNULL_END

#endif /* ReactNativeRichTextEditorViewNativeComponent_h */
