#pragma once
#import "AttributesManager.h"
#import "BaseStyleProtocol.h"
#import "InputConfig.h"
#import "InputParser.h"
#import "InputTextView.h"
#import "MediaAttachment.h"
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

#ifndef EnrichedTextInputViewNativeComponent_h
#define EnrichedTextInputViewNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

@interface EnrichedTextInputView
    : RCTViewComponentView <MediaAttachmentDelegate> {
@public
  InputTextView *textView;
@public
  NSRange recentlyChangedRange;
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
  NSDictionary<NSNumber *, NSArray<NSNumber *> *> *conflictingStyles;
  NSMutableDictionary<NSNumber *, NSArray<NSNumber *> *> *blockingStyles;
@public
  BOOL blockEmitting;
@public
  NSValue *dotReplacementRange;
}
- (void)emitOnLinkDetectedEvent:(NSString *)text
                            url:(NSString *)url
                          range:(NSRange)range;
- (void)emitOnMentionEvent:(NSString *)indicator text:(nullable NSString *)text;
- (void)anyTextMayHaveBeenModified;
- (BOOL)handleStyleBlocksAndConflicts:(StyleType)type range:(NSRange)range;
- (NSArray<NSNumber *> *)getPresentStyleTypesFrom:(NSArray<NSNumber *> *)types
                                            range:(NSRange)range;
- (CGSize)measureInitialSizeWithMaxWidth:(CGFloat)maxWidth;
- (void)commitSize:(CGSize)size;
@end

NS_ASSUME_NONNULL_END

#endif /* EnrichedTextInputViewNativeComponent_h */
