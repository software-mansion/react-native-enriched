#import "EnrichedViewHost.h"
#import <UIKit/UIKit.h>
#pragma once

@interface ZeroWidthSpaceUtils : NSObject
+ (void)handleZeroWidthSpacesInInput:(id<EnrichedViewHost>)host;
+ (void)addSpacesIfNeededinInput:(id<EnrichedViewHost>)host
                         inRange:(NSRange)range;
+ (BOOL)handleBackspaceInRange:(NSRange)range
               replacementText:(NSString *)text
                         input:(id<EnrichedViewHost>)host;
@end
