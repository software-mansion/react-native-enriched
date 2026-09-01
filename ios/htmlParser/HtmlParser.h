#pragma once
#import "interfaces/EnrichedViewHost.h"
#import <UIKit/UIKit.h>

@class EnrichedConfig;

@interface HtmlParser : NSObject
+ (NSString *_Nullable)initiallyProcessHtml:(NSString *_Nonnull)html
                          useHtmlNormalizer:(BOOL)useHtmlNormalizer;
+ (NSArray *_Nonnull)getTextAndStylesFromHtml:(NSString *_Nonnull)fixedHtml
                                       config:(EnrichedConfig *_Nullable)config;
+ (NSString *_Nonnull)parseToHtmlFromRange:(NSRange)range
                                      host:(id<EnrichedViewHost>)host;
@end
