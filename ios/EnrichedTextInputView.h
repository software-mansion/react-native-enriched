#pragma once
#import "AttributesManager.h"
#import "BaseStyleProtocol.h"
#import "EnrichedStyleHost.h"
#import "InputConfig.h"
#import "InputParser.h"
#import "InputTextView.h"
#import "LinkData.h"
#import "MediaAttachment.h"
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

#ifndef EnrichedTextInputViewNativeComponent_h
#define EnrichedTextInputViewNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

@interface EnrichedTextInputView
    : RCTViewComponentView <MediaAttachmentDelegate, EnrichedStyleHost> {
@public
  InputTextView *textView;
@public
  InputConfig *config;
@public
  InputParser *parser;
@public
  AttributesManager *attributesManager;
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
}
- (CGSize)measureSize:(CGFloat)maxWidth;
- (void)emitOnLinkDetectedEvent:(LinkData *)linkData range:(NSRange)range;
- (void)emitOnMentionEvent:(NSString *)indicator text:(nullable NSString *)text;
- (void)emitOnPasteImagesEvent:(NSArray<NSDictionary *> *)images;
- (void)anyTextMayHaveBeenModified;
- (void)scheduleRelayoutIfNeeded;
- (BOOL)handleStyleBlocksAndConflicts:(StyleType)type range:(NSRange)range;
- (NSArray<NSNumber *> *)getPresentStyleTypesFrom:(NSArray<NSNumber *> *)types
                                            range:(NSRange)range;
@end

NS_ASSUME_NONNULL_END

#endif /* EnrichedTextInputViewNativeComponent_h */
