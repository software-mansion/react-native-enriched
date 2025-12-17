#import <Foundation/Foundation.h>

@class ConvertHtmlToPlainTextAndStylesResult;
@class HtmlTokenizationResult;

@interface HtmlHandler : NSObject
- (NSString *)initiallyProcessHtml:(NSString *)html;
- (ConvertHtmlToPlainTextAndStylesResult *)getTextAndStylesFromHtml:
    (NSString *)fixedHtml;
@end
