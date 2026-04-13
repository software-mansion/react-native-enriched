#pragma once
#import "EnrichedConfig.h"
#import "EnrichedViewHost.h"
#import "MediaAttachment.h"
#import "MentionParams.h"
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

#ifndef EnrichedTextViewNativeComponent_h
#define EnrichedTextViewNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

@interface EnrichedTextView
    : RCTViewComponentView <EnrichedViewHost, MediaAttachmentDelegate> {
@public
  UITextView *textView;
@public
  EnrichedConfig *config;
@public
  NSDictionary<NSNumber *, id> *stylesDict;
  NSMutableDictionary<NSNumber *, NSArray<NSNumber *> *> *conflictingStyles;
  NSMutableDictionary<NSNumber *, NSArray<NSNumber *> *> *blockingStyles;
}
- (CGSize)measureSize:(CGFloat)maxWidth;
- (void)emitOnLinkPressEvent:(NSString *)url;
- (void)emitOnMentionPressEvent:(MentionParams *)mention;
@end

NS_ASSUME_NONNULL_END

#endif /* EnrichedTextViewNativeComponent_h */
