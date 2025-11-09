#import <UIKit/UIKit.h>

@interface WordsUtils : NSObject
+ (NSArray<NSDictionary *> *)getAffectedWordsFromText:(NSString *)text
                                    modificationRange:(NSRange)range;
+ (NSDictionary *)getCurrentWord:(NSString *)text range:(NSRange)range;
@end
