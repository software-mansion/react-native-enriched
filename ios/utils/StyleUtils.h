#import "EnrichedTextStyleHeaders.h"
#import "StyleHeaders.h"

@interface StyleUtils : NSObject
+ (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)conflictMap;
+ (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)blockingMap;
+ (NSDictionary<NSNumber *, StyleBase *> *)stylesDictForHost:
                                               (id<EnrichedStyleHost>)host
                                                     isInput:(BOOL)isInput;

+ (BOOL)handleStyleBlocksAndConflicts:(StyleType)type
                                range:(NSRange)range
                              forHost:(id<EnrichedStyleHost>)host;
+ (NSArray<NSNumber *> *)getPresentStyleTypesFrom:(NSArray<NSNumber *> *)types
                                            range:(NSRange)range
                                          forHost:(id<EnrichedStyleHost>)host;
+ (void)addStyleBlock:(StyleType)blocking
                   to:(StyleType)blocked
              forHost:(id<EnrichedStyleHost>)host;
+ (void)removeStyleBlock:(StyleType)blocking
                    from:(StyleType)blocked
                 forHost:(id<EnrichedStyleHost>)host;

+ (void)addStyleConflict:(StyleType)conflicting
                      to:(StyleType)conflicted
                 forHost:(id<EnrichedStyleHost>)host;
+ (void)removeStyleConflict:(StyleType)conflicting
                       from:(StyleType)conflicted
                    forHost:(id<EnrichedStyleHost>)host;
@end
