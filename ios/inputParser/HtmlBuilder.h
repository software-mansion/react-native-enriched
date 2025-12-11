#import "EnrichedTextInputView.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HtmlBuilder : NSObject

@property(nonatomic, weak) NSDictionary *stylesDict;
@property(nonatomic, weak) EnrichedTextInputView *input;

- (NSString *)htmlFromRange:(NSRange)range;

@end
