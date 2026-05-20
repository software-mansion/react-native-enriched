#pragma once
#import "BaseStyleProtocol.h"
#import "EnrichedConfig.h"
#import "EnrichedInputTextView.h"
#import "EnrichedViewHost.h"
#import "InputAttributesManager.h"
#import "InputHtmlParser.h"
#import "LinkData.h"
#import "MediaAttachment.h"
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

#ifndef EnrichedTextInputViewNativeComponent_h
#define EnrichedTextInputViewNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

@interface EnrichedTextInputView
    : RCTViewComponentView <EnrichedViewHost, MediaAttachmentDelegate> {
@public
  EnrichedInputTextView *textView;
@public
  EnrichedConfig *config;
@public
  InputHtmlParser *parser;
@public
  InputAttributesManager *attributesManager;
@public
  NSMutableDictionary<NSAttributedStringKey, id> *defaultTypingAttributes;
@public
  NSDictionary<NSNumber *, id> *stylesDict;
  NSMutableDictionary<NSNumber *, NSArray<NSNumber *> *> *conflictingStyles;
  NSMutableDictionary<NSNumber *, NSArray<NSNumber *> *> *blockingStyles;
@public
  BOOL blockEmitting;
@public
  BOOL useHtmlNormalizer;
@public
  NSValue *dotReplacementRange;
@public
  NSArray<NSDictionary *> *textShortcuts;
}
- (CGSize)measureSize:(CGFloat)maxWidth;
- (void)emitOnLinkDetectedEvent:(LinkData *)linkData range:(NSRange)range;
- (void)emitOnMentionEvent:(NSString *)indicator text:(nullable NSString *)text;
- (void)emitOnPasteImagesEvent:(NSArray<NSDictionary *> *)images;
- (void)anyTextMayHaveBeenModified;
- (void)scheduleRelayoutIfNeeded;

@end

NS_ASSUME_NONNULL_END

#endif /* EnrichedTextInputViewNativeComponent_h */
