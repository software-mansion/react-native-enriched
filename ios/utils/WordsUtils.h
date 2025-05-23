#import <UIKit/UIKit.h>

@interface WordsUtils : NSObject
+ (NSArray<NSDictionary *> *)getAffectedWordsFromText:(NSString *)text modificationRange:(NSRange)range;
@end
