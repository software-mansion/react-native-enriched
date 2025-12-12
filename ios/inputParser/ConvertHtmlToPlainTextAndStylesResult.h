#import <Foundation/Foundation.h>

@interface ConvertHtmlToPlainTextAndStylesResult : NSObject
@property(nonatomic, strong) NSString *text;
@property(nonatomic, strong) NSArray *styles;
- (instancetype)initWithData:(NSString *)text styles:(NSArray *)styles;
@end
