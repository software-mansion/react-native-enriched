#import <Foundation/Foundation.h>

@interface HtmlTokenizationResult : NSObject
@property(nonatomic, strong) NSString *plainText;
@property(nonatomic, strong) NSMutableArray *initialTags;
@end

@interface HtmlTokenizer : NSObject
- (NSString *)initiallyProcessHtml:(NSString *)html;
- (NSString *)stringByAddingNewlinesToTag:(NSString *)tag
                                 inString:(NSString *)html
                                  leading:(BOOL)leading
                                 trailing:(BOOL)trailing;

- (HtmlTokenizationResult *)tokenize:(NSString *)fixedHtml;
@end
