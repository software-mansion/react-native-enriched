#pragma once
#import <UIKit/UIKit.h>

@interface EditorParser : NSObject
- (instancetype _Nonnull)initWithEditor:(id _Nonnull)editor;
- (NSString *_Nonnull)parseToHtml;
- (void)replaceWholeFromHtml:(NSString * _Nonnull)html;
- (void)replaceRangeFromHtml:(NSString * _Nonnull)html range:(NSRange)range;
- (void)insertFromHtml:(NSString * _Nonnull)html location:(NSInteger)location;
@end
