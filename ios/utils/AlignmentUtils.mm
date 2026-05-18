#import "AlignmentUtils.h"
#import "RangeUtils.h"
#import "StyleHeaders.h"

@implementation AlignmentUtils

+ (NSString *)alignmentToString:(NSTextAlignment)alignment {
  switch (alignment) {
  case NSTextAlignmentLeft:
    return @"left";
  case NSTextAlignmentCenter:
    return @"center";
  case NSTextAlignmentRight:
    return @"right";
  case NSTextAlignmentJustified:
    return @"justify";
  case NSTextAlignmentNatural:
  default:
    return @"auto";
  }
}

+ (NSTextAlignment)stringToAlignment:(NSString *)alignmentString {
  NSString *normalized = [alignmentString lowercaseString];

  if ([normalized isEqualToString:@"left"]) {
    return NSTextAlignmentLeft;
  }
  if ([normalized isEqualToString:@"center"]) {
    return NSTextAlignmentCenter;
  }
  if ([normalized isEqualToString:@"right"]) {
    return NSTextAlignmentRight;
  }
  if ([normalized isEqualToString:@"justify"]) {
    return NSTextAlignmentJustified;
  }

  return NSTextAlignmentNatural;
}

+ (NSTextAlignment)markerToAlignment:(NSString *)marker {
  if ([marker isEqualToString:@"EnrichedAlignmentLeft"]) {
    return NSTextAlignmentLeft;
  } else if ([marker isEqualToString:@"EnrichedAlignmentCenter"]) {
    return NSTextAlignmentCenter;
  } else if ([marker isEqualToString:@"EnrichedAlignmentRight"]) {
    return NSTextAlignmentRight;
  } else if ([marker isEqualToString:@"EnrichedAlignmentJustified"]) {
    return NSTextAlignmentJustified;
  }
  return NSTextAlignmentNatural;
}

+ (NSString *)alignmentToMarker:(NSTextAlignment)alignment {
  if (alignment == NSTextAlignmentLeft) {
    return @"EnrichedAlignmentLeft";
  } else if (alignment == NSTextAlignmentCenter) {
    return @"EnrichedAlignmentCenter";
  } else if (alignment == NSTextAlignmentRight) {
    return @"EnrichedAlignmentRight";
  } else if (alignment == NSTextAlignmentJustified) {
    return @"EnrichedAlignmentJustified";
  }

  return @"EnrichedAlignmentNatural";
}

+ (NSString *)cssValueForAlignment:(NSTextAlignment)alignment {
  switch (alignment) {
  case NSTextAlignmentLeft:
    return @"left";
  case NSTextAlignmentCenter:
    return @"center";
  case NSTextAlignmentRight:
    return @"right";
  case NSTextAlignmentJustified:
    return @"justify";
  default:
    return nil;
  }
}

+ (NSTextAlignment)alignmentFromStyleParams:(NSString *)params {
  if (!params)
    return NSTextAlignmentNatural;

  NSString *pattern = @"text-align\\s*:\\s*(left|center|right|justify)";

  NSRegularExpression *regex = [NSRegularExpression
      regularExpressionWithPattern:pattern
                           options:NSRegularExpressionCaseInsensitive
                             error:nil];

  NSTextCheckingResult *match =
      [regex firstMatchInString:params
                        options:0
                          range:NSMakeRange(0, params.length)];

  if (match) {
    // rangeAtIndex:1 corresponds to the capture group
    // (left|center|right|justify)
    NSString *value =
        [[params substringWithRange:[match rangeAtIndex:1]] lowercaseString];
    return [AlignmentUtils stringToAlignment:value];
  }

  return NSTextAlignmentNatural;
}

@end
