#import "EnrichedViewHost.h"
#import <UIKit/UIKit.h>
#pragma once

@interface ZeroWidthSpaceUtils : NSObject
+ (void)handleZeroWidthSpacesInHost:(id<EnrichedViewHost>)host;
+ (void)addSpacesIfNeededInHost:(id<EnrichedViewHost>)host
                        inRange:(NSRange)range;
+ (void)applyKernForZeroWidthSpacesInRange:(NSRange)range
                                      host:(id<EnrichedViewHost>)host;
+ (BOOL)handleBackspaceInRange:(NSRange)range
               replacementText:(NSString *)text
                          host:(id<EnrichedViewHost>)host;
@end
