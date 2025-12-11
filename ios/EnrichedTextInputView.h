#pragma once
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
  NSMutableDictionary<NSAttributedStringKey, id> *defaultTypingAttributes;
@public
  NSDictionary<NSNumber *, id<BaseStyleProtocol>> *stylesDict;
  NSDictionary<NSNumber *, NSArray<NSNumber *> *> *conflictingStyles;
  NSDictionary<NSNumber *, NSArray<NSNumber *> *> *blockingStyles;
@public
  BOOL blockEmitting;
}
@property(nonatomic, strong)
    NSDictionary<NSNumber *, NSArray<NSNumber *> *> *conflictingStyles;
@property(nonatomic, strong)
    NSDictionary<NSNumber *, NSArray<NSNumber *> *> *blockingStyles;
- (CGSize)measureSize:(CGFloat)maxWidth;
- (void)emitOnLinkDetectedEvent:(NSString *)text
                            url:(NSString *)url
                          range:(NSRange)range;
- (void)emitOnMentionEvent:(NSString *)indicator text:(nullable NSString *)text;
- (void)anyTextMayHaveBeenModified;
- (BOOL)handleStyleBlocksAndConflicts:(StyleType)type range:(NSRange)range;
- (NSArray<NSNumber *> *)getPresentStyleTypesFrom:(NSArray<NSNumber *> *)types
                                            range:(NSRange)range;
@end

NS_ASSUME_NONNULL_END

#endif /* EnrichedTextInputViewNativeComponent_h */
