#pragma once
#import <UIKit/UIKit.h>

@class EnrichedTextInputView;

@interface AttributesManager : NSObject
@property(nonatomic, weak) EnrichedTextInputView *input;
- (instancetype)initWithInput:(EnrichedTextInputView *)input;
- (void)addDirtyRange:(NSRange)range;
- (void)shiftDirtyRangesWithEditedRange:(NSRange)editedRange
                         changeInLength:(NSInteger)delta;
- (void)didRemoveTypingAttribute:(NSString *)key;
- (void)manageTypingAttributesWithOnlySelection:(BOOL)onlySelectionChanged;
- (void)handleDirtyRangesStyling;
@end
