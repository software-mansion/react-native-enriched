#import <Foundation/Foundation.h>

@interface StyleSanitizer : NSObject

- (void)sanitizeStyles:(NSMutableArray *)styles
              blocking:
                  (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)blocking
           conflicting:
               (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)conflicting;

@end
