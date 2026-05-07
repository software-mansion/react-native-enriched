#import "AlignmentEntry.h"
#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"
#import <UIKit/UIKit.h>

@interface AlignmentUtils : NSObject

+ (void)applyAlignments:(NSArray<AlignmentEntry *> *)alignments
                 offset:(NSInteger)offset
                 toHost:(id<EnrichedViewHost>)host;

+ (NSString *)alignmentToString:(NSTextAlignment)alignment;

+ (NSTextAlignment)stringToAlignment:(NSString *)alignmentString;

+ (NSString *)currentAlignmentStringForInput:(EnrichedTextInputView *)input;

+ (NSTextAlignment)alignmentFromMarker:(NSString *)marker;

@end
