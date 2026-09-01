#import "EnrichedTextInputView.h"
#import "interfaces/AlignmentEntry.h"
#import "interfaces/StyleHeaders.h"
#import <UIKit/UIKit.h>

@interface AlignmentUtils : NSObject

+ (NSString *)alignmentToString:(NSTextAlignment)alignmentl;

+ (NSTextAlignment)stringToAlignment:(NSString *)alignmentString;

+ (NSString *)alignmentToMarker:(NSTextAlignment)alignment;

+ (NSTextAlignment)markerToAlignment:(NSString *)marker;

+ (NSString *)cssValueForAlignment:(NSTextAlignment)alignment;

+ (NSTextAlignment)alignmentFromStyleParams:(NSString *)params;

@end
