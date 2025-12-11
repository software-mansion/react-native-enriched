#pragma once
#import <UIKit/UIKit.h>

@interface InputParser : NSObject
- (instancetype _Nonnull)initWithInput:(id _Nonnull)input;
- (NSString *_Nonnull)parseToHtmlFromRange:(NSRange)range;
- (void)replaceWholeFromHtml:(NSString *_Nonnull)html
    notifyAnyTextMayHaveBeenModified:(BOOL)notifyAnyTextMayHaveBeenModified;
- (void)replaceFromHtml:(NSString *_Nonnull)html range:(NSRange)range;
- (void)insertFromHtml:(NSString *_Nonnull)html location:(NSInteger)location;
- (NSString *_Nullable)initiallyProcessHtml:(NSString *_Nonnull)html;
@end
