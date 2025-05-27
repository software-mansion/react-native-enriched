#pragma once
#import "StylePair.h"
#import "ReactNativeRichTextEditorView.h"


@interface OccurenceUtils : NSObject
+ (BOOL)detect
  :(NSAttributedStringKey _Nonnull)key
  withEditor:(ReactNativeRichTextEditorView* _Nonnull)editor
  inRange:(NSRange)range
  withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition;
+ (BOOL)any
  :(NSAttributedStringKey _Nonnull)key
  withEditor:(ReactNativeRichTextEditorView* _Nonnull)editor
  inRange:(NSRange)range
  withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition;
+ (NSArray<StylePair *> *_Nullable)all
  :(NSAttributedStringKey _Nonnull)key
  withEditor:(ReactNativeRichTextEditorView* _Nonnull)editor
  inRange:(NSRange)range
  withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition;
@end
