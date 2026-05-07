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
    return @"left";
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

+ (NSString *)currentAlignmentStringForInput:(EnrichedTextInputView *)input {
  UITextView *textView = input->textView;
  NSParagraphStyle *paraStyle = nil;

  if (textView.textStorage.length > 0) {
    NSUInteger location =
        MIN(textView.selectedRange.location, textView.textStorage.length - 1);
    paraStyle = [textView.textStorage attribute:NSParagraphStyleAttributeName
                                        atIndex:location
                                 effectiveRange:nil];
  }

  if (paraStyle == nil) {
    paraStyle = textView.typingAttributes[NSParagraphStyleAttributeName];
  }

  NSTextAlignment alignment =
      paraStyle ? paraStyle.alignment : NSTextAlignmentNatural;
  return [AlignmentUtils alignmentToString:alignment];
}

@end
