#pragma once
#import "StyleHeaders.h"
#import <UIKit/UIKit.h>

@interface OrderedListMetricsUtils : NSObject

+ (NSInteger)digitCountOf:(NSInteger)n;

+ (CGFloat)headIndentForItemCount:(NSInteger)itemCount
                           config:(EnrichedConfig *)config;

+ (NSRange)contiguousOrderedListRangeContaining:(NSRange)range
                                       forStyle:(OrderedListStyle *)style
                                      itemCount:(NSInteger *)outCount;

@end
