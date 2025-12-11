#import "StyleSanitizer.h"
#import "StylePair.h"

@implementation StyleSanitizer

- (void)sanitizeStyles:(NSMutableArray *)styles
              blocking:
                  (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)blocking
           conflicting:
               (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)conflicting {
  NSMutableDictionary<NSValue *, NSMutableSet<NSNumber *> *> *rangeToTypes =
      [NSMutableDictionary new];

  for (NSArray *entry in styles) {
    NSNumber *type = entry[0];
    NSValue *rKey = ((StylePair *)entry[1]).rangeValue;

    if (!rangeToTypes[rKey]) {
      rangeToTypes[rKey] = [NSMutableSet new];
    }
    [rangeToTypes[rKey] addObject:type];
  }

  for (NSValue *rKey in rangeToTypes) {
    NSMutableSet<NSNumber *> *types = rangeToTypes[rKey];

    for (NSNumber *type in [types copy]) {

      // BLOCKING: remove style if blocked
      for (NSNumber *b in blocking[type]) {
        if ([types containsObject:b]) {
          [types removeObject:type];
          break;
        }
      }
      if (![types containsObject:type])
        continue;

      for (NSNumber *c in conflicting[type]) {
        if ([types containsObject:c]) {
          [types removeObject:c];
        }
      }
    }
  }

  NSMutableArray *final = [NSMutableArray new];

  for (NSArray *entry in styles) {
    NSNumber *type = entry[0];
    StylePair *pair = entry[1];

    NSMutableSet *set = rangeToTypes[pair.rangeValue];
    if ([set containsObject:type]) {
      [final addObject:@[ type, pair ]];
    }
  }

  [styles removeAllObjects];
  [styles addObjectsFromArray:final];
}

@end
