#import "EnrichedTextStyleHeaders.h"
#import "StyleHeaders.h"

@interface StyleUtils : NSObject
+ (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)conflictMap;
+ (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)blockingMap;
+ (NSDictionary<NSNumber *, StyleBase *> *)stylesDictForHost:
                                               (id<EnrichedViewHost>)host
                                                     isInput:(BOOL)isInput;

+ (BOOL)handleStyleBlocksAndConflicts:(StyleType)type
                                range:(NSRange)range
                              forHost:(id<EnrichedViewHost>)host;
+ (NSArray<NSNumber *> *)getPresentStyleTypesFrom:(NSArray<NSNumber *> *)types
                                            range:(NSRange)range
                                          forHost:(id<EnrichedViewHost>)host;
+ (void)addStyleBlock:(StyleType)blocking
                   to:(StyleType)blocked
              forHost:(id<EnrichedViewHost>)host;
+ (void)removeStyleBlock:(StyleType)blocking
                    from:(StyleType)blocked
                 forHost:(id<EnrichedViewHost>)host;

+ (void)addStyleConflict:(StyleType)conflicting
                      to:(StyleType)conflicted
                 forHost:(id<EnrichedViewHost>)host;
+ (void)removeStyleConflict:(StyleType)conflicting
                       from:(StyleType)conflicted
                    forHost:(id<EnrichedViewHost>)host;
@end
