#import <Foundation/Foundation.h>

@interface HtmlTokenizationResult : NSObject
@property(nonatomic, strong) NSString *text;
@property(nonatomic, strong) NSMutableArray *tags;
- (instancetype)initWithData:(NSString *_Nonnull)text
                        tags:(NSMutableArray *_Nonnull)tags;
@end
