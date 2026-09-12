#pragma once
#import "EnrichedViewHost.h"
#import <UIKit/UIKit.h>

@interface MaxLengthUtils : NSObject
+ (NSInteger)plainLengthOf:(NSString *_Nonnull)text;
+ (NSInteger)capacityForHost:(id<EnrichedViewHost> _Nullable)host
              replacingRange:(NSRange)range;
+ (NSInteger)wholeContentCapacityForHost:(id<EnrichedViewHost> _Nullable)host;
+ (NSUInteger)cutIndexIn:(NSString *_Nonnull)text capacity:(NSInteger)capacity;
+ (NSString *_Nonnull)truncate:(NSString *_Nonnull)text
                    toCapacity:(NSInteger)capacity;
@end
