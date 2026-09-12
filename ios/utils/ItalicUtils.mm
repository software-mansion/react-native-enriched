#import "ItalicUtils.h"
#import "extensions/FontExtension.h"

// slant used when a font has no italic face
static const CGFloat kObliquenessFallback = 0.2;

@interface ItalicUtils ()

+ (NSCharacterSet *)nonNeutralCharacters;

+ (ItalicKind)kindForCluster:(NSString *)cluster
                        font:(UIFont *)font
                  italicFont:(UIFont *)italicFont
               hasItalicFace:(BOOL)hasItalicFace;

+ (void)applyKind:(ItalicKind)kind
         toSegment:(NSRange)segment
     inTextStorage:(NSTextStorage *)textStorage
    withItalicFont:(UIFont *)italicFont;

@end

@implementation ItalicUtils

+ (void)applyItalicForFont:(UIFont *)font
             inTextStorage:(NSTextStorage *)textStorage
                   inRange:(NSRange)range {
  UIFont *italicFont = [font setItalic];
  BOOL hasItalicFace = [italicFont isItalic];

  NSMutableArray<NSValue *> *clusterRanges = [NSMutableArray array];
  NSMutableArray<NSNumber *> *clusterKinds = [NSMutableArray array];

  // we process each composed character sequence and classify it to a specific
  // ItalicKind
  [textStorage.string
      enumerateSubstringsInRange:range
                         options:NSStringEnumerationByComposedCharacterSequences
                      usingBlock:^(NSString *_Nullable cluster,
                                   NSRange clusterRange, NSRange _,
                                   BOOL *_Nonnull stop) {
                        if (cluster.length == 0) {
                          return;
                        }
                        [clusterRanges
                            addObject:[NSValue valueWithRange:clusterRange]];
                        [clusterKinds
                            addObject:@([self kindForCluster:cluster
                                                        font:font
                                                  italicFont:italicFont
                                               hasItalicFace:hasItalicFace])];
                      }];

  // merge neighbouring clusters of the same kind and apply the style
  NSUInteger index = 0;
  while (index < clusterKinds.count) {
    NSUInteger endIndex = index + 1;
    ItalicKind kind = (ItalicKind)[clusterKinds[index] integerValue];
    while (endIndex < clusterKinds.count &&
           (ItalicKind)[clusterKinds[endIndex] integerValue] == kind) {
      endIndex += 1;
    }

    NSRange startRange = [clusterRanges[index] rangeValue];
    NSRange endRange = [clusterRanges[endIndex - 1] rangeValue];
    NSRange segment = NSMakeRange(startRange.location,
                                  NSMaxRange(endRange) - startRange.location);

    [self applyKind:kind
             toSegment:segment
         inTextStorage:textStorage
        withItalicFont:italicFont];

    index = endIndex;
  }
}

// contains all characters except whitespaces, newlines,
// control characters and ZWS
+ (NSCharacterSet *)nonNeutralCharacters {
  static NSCharacterSet *nonNeutral = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSMutableCharacterSet *set =
        [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
    [set formUnionWithCharacterSet:[NSCharacterSet controlCharacterSet]];
    [set addCharactersInString:[NSString
                                   stringWithFormat:@"%C", (unichar)0x200B]];
    nonNeutral = [[set invertedSet] copy];
  });
  return nonNeutral;
}

+ (ItalicKind)kindForCluster:(NSString *)cluster
                        font:(UIFont *)font
                  italicFont:(UIFont *)italicFont
               hasItalicFace:(BOOL)hasItalicFace {
  if ([cluster rangeOfCharacterFromSet:[self nonNeutralCharacters]].location ==
      NSNotFound) {
    return ItalicKindNone;
  }

  // we just need to analyze the first unicode character to classify the whole
  // cluster
  unichar chars[2] = {0, 0};
  CFIndex count = 1;
  chars[0] = [cluster characterAtIndex:0];
  if (CFStringIsSurrogateHighCharacter(chars[0]) && cluster.length > 1) {
    chars[1] = [cluster characterAtIndex:1];
    count = 2;
  }

  if (chars[0] == (unichar)NSAttachmentCharacter) {
    return ItalicKindNone;
  }

  BOOL coveredByFont = [font coversCharacters:chars count:count];

  // italic style is supported - we use it
  if (coveredByFont && hasItalicFace && italicFont != nullptr &&
      [italicFont coversCharacters:chars count:count]) {
    return ItalicKindFont;
  }

  // italic is not supported, we use the slant instead
  return ItalicKindOblique;
}

+ (void)applyKind:(ItalicKind)kind
         toSegment:(NSRange)segment
     inTextStorage:(NSTextStorage *)textStorage
    withItalicFont:(UIFont *)italicFont {
  switch (kind) {
  case ItalicKindFont:
    [textStorage addAttribute:NSFontAttributeName
                        value:italicFont
                        range:segment];
    [textStorage removeAttribute:NSObliquenessAttributeName range:segment];
    break;
  case ItalicKindOblique:
    [textStorage addAttribute:NSObliquenessAttributeName
                        value:@(kObliquenessFallback)
                        range:segment];
    break;
  case ItalicKindNone:
    [textStorage removeAttribute:NSObliquenessAttributeName range:segment];
    break;
  }
}

@end
