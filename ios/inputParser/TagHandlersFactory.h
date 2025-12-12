#import <Foundation/Foundation.h>

@class StylePair;

typedef void (^TagHandler)(NSString *params, StylePair *pair,
                           NSMutableArray *styleArr);

FOUNDATION_EXPORT NSDictionary<NSString *, TagHandler> *MakeTagHandlers(void);
