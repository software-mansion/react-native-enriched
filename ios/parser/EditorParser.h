#pragma once
#import <UIKit/UIKit.h>

@interface EditorParser : NSObject
- (instancetype _Nonnull)initWithEditor:(id _Nonnull)editor;
- (NSString * _Nonnull)parseToHtmlFromRange:(NSRange)range;
- (void)replaceWholeFromHtml:(NSString * _Nonnull)html;
- (void)replaceFromHtml:(NSString * _Nonnull)html range:(NSRange)range;
- (void)insertFromHtml:(NSString * _Nonnull)html location:(NSInteger)location;
- (NSString * _Nullable)initiallyProcessHtml:(NSString * _Nonnull)html;
@end
