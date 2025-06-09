#pragma once
#import <UIKit/UIKit.h>

@interface EditorParser : NSObject
- (instancetype _Nonnull)initWithEditor:(id _Nonnull)editor;
- (NSString *)parseToHtml;
@end
