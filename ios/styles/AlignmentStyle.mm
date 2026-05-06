#import "AlignmentUtils.h"
#import "StyleHeaders.h"

@implementation AlignmentStyle

+ (StyleType)getType {
  return Alignment;
}

- (BOOL)isParagraph {
  return YES;
}

- (BOOL)isStoredAlignment:(NSTextAlignment)alignment {
  return alignment != NSTextAlignmentLeft &&
         alignment != NSTextAlignmentNatural;
}

- (void)setAlignment:(NSTextAlignment)alignment
               range:(NSRange)range
          withTyping:(BOOL)withTyping
      withDirtyRange:(BOOL)withDirtyRange {
  [self add:range
           withValue:[AlignmentUtils alignmentToString:alignment]
          withTyping:withTyping
      withDirtyRange:withDirtyRange];
}

- (void)add:(NSRange)range
         withValue:(NSString *)value
        withTyping:(BOOL)withTyping
    withDirtyRange:(BOOL)withDirtyRange {
  NSRange actualRange = [self actualUsedRange:range];
  NSTextAlignment alignment = [AlignmentUtils stringToAlignment:value];

  [self.host.textView.textStorage
      enumerateAttribute:NSParagraphStyleAttributeName
                 inRange:actualRange
                 options:0
              usingBlock:^(NSParagraphStyle *existingValue, NSRange subRange,
                           BOOL *stop) {
                NSMutableParagraphStyle *paragraphStyle =
                    existingValue ? [existingValue mutableCopy]
                                  : [[NSMutableParagraphStyle alloc] init];
                paragraphStyle.alignment = alignment;
                [self.host.textView.textStorage
                    addAttribute:NSParagraphStyleAttributeName
                           value:paragraphStyle
                           range:subRange];
              }];

  if (withTyping) {
    [self addTypingWithValue:value];
  }

  if (withDirtyRange) {
    [self.host.attributesManager addDirtyRange:actualRange];
  }
}

- (void)remove:(NSRange)range withDirtyRange:(BOOL)withDirtyRange {
  [self setAlignment:NSTextAlignmentLeft
               range:range
          withTyping:YES
      withDirtyRange:withDirtyRange];
}

- (void)addTypingWithValue:(NSString *)value {
  NSMutableDictionary *newTypingAttrs =
      [self.host.textView.typingAttributes mutableCopy];
  NSMutableParagraphStyle *paragraphStyle =
      [newTypingAttrs[NSParagraphStyleAttributeName] mutableCopy]
          ?: [[NSMutableParagraphStyle alloc] init];
  paragraphStyle.alignment = [AlignmentUtils stringToAlignment:value];
  newTypingAttrs[NSParagraphStyleAttributeName] = paragraphStyle;
  self.host.textView.typingAttributes = newTypingAttrs;
}

- (void)removeTyping {
  [self addTypingWithValue:@"left"];
}

- (BOOL)styleCondition:(id)value range:(NSRange)range {
  NSParagraphStyle *paragraphStyle = (NSParagraphStyle *)value;
  return paragraphStyle != nil &&
         [self isStoredAlignment:paragraphStyle.alignment];
}

- (BOOL)detect:(NSRange)range {
  return NO;
}

- (BOOL)any:(NSRange)range {
  return NO;
}

- (NSArray<StylePair *> *)all:(NSRange)range {
  NSMutableArray<StylePair *> *alignments = [[NSMutableArray alloc] init];

  [self.host.textView.textStorage
      enumerateAttribute:NSParagraphStyleAttributeName
                 inRange:range
                 options:0
              usingBlock:^(NSParagraphStyle *paragraphStyle, NSRange subRange,
                           BOOL *stop) {
                if (paragraphStyle == nil ||
                    ![self isStoredAlignment:paragraphStyle.alignment]) {
                  return;
                }

                StylePair *pair = [[StylePair alloc] init];
                pair.rangeValue = [NSValue valueWithRange:subRange];
                pair.styleValue =
                    [AlignmentUtils alignmentToString:paragraphStyle.alignment];
                [alignments addObject:pair];
              }];

  return alignments;
}

- (void)reapplyFromStylePair:(StylePair *)pair {
  [self add:[pair.rangeValue rangeValue]
           withValue:(NSString *)pair.styleValue
          withTyping:NO
      withDirtyRange:NO];
}

@end
