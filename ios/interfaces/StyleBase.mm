#import "StyleBase.h"
#import "AttributeEntry.h"
#import "OccurenceUtils.h"
#import "RangeUtils.h"
#import "ZeroWidthSpaceUtils.h"

@implementation StyleBase

// This method gets overridden
+ (StyleType)getType {
  return None;
}

// This method gets overridden for inline styles
- (NSString *)getKey {
  if ([self isParagraph]) {
    return NSParagraphStyleAttributeName;
  }
  return @"NoneAttribute";
}

// Basic inline styles will use this default value, paragraph styles will
// override it and parametrised ones completely don't use it
- (NSString *)getValue {
  return @"AnyValue";
}

// This method gets overridden
- (BOOL)isParagraph {
  return false;
}

- (BOOL)needsZWS {
  return NO;
}

- (instancetype)initWithHost:(id<EnrichedStyleHost>)host {
  self = [super init];
  _host = host;
  return self;
}

// aligns range to whole paragraph for the paragraph stlyes
- (NSRange)actualUsedRange:(NSRange)range {
  if (![self isParagraph])
    return range;
  return [self.host.textView.textStorage.string paragraphRangeForRange:range];
}

- (void)toggle:(NSRange)range {
  NSRange actualRange = [self actualUsedRange:range];

  BOOL isPresent = [self detect:actualRange];
  if (actualRange.length >= 1) {
    isPresent ? [self remove:actualRange withDirtyRange:YES]
              : [self add:actualRange withTyping:YES withDirtyRange:YES];
  } else {
    isPresent ? [self removeTyping] : [self addTypingWithValue:[self getValue]];
  }
}

- (void)add:(NSRange)range
        withTyping:(BOOL)withTyping
    withDirtyRange:(BOOL)withDirtyRange {
  [self add:range
           withValue:[self getValue]
          withTyping:withTyping
      withDirtyRange:withDirtyRange];
}

- (void)add:(NSRange)range
         withValue:(NSString *)value
        withTyping:(BOOL)withTyping
    withDirtyRange:(BOOL)withDirtyRange {
  NSRange actualRange = [self actualUsedRange:range];

  if (![self isParagraph]) {
    [self.host.textView.textStorage addAttribute:[self getKey]
                                           value:value
                                           range:actualRange];
  } else {
    [self.host.textView.textStorage
        enumerateAttribute:NSParagraphStyleAttributeName
                   inRange:actualRange
                   options:0
                usingBlock:^(id _Nullable existingValue, NSRange subRange,
                             BOOL *_Nonnull stop) {
                  NSMutableParagraphStyle *pStyle =
                      [(NSParagraphStyle *)existingValue mutableCopy];
                  if (pStyle == nullptr)
                    return;
                  pStyle.textLists =
                      @[ [[NSTextList alloc] initWithMarkerFormat:value
                                                          options:0] ];
                  [self.host.textView.textStorage
                      addAttribute:NSParagraphStyleAttributeName
                             value:pStyle
                             range:subRange];
                }];
  }

  if (withTyping) {
    [self addTypingWithValue:value];
  }

  // Notify attributes manager of styling to be re-done if needed.
  if (withDirtyRange) {
    [self.host.attributesManager addDirtyRange:actualRange];
  }
}

- (void)remove:(NSRange)range withDirtyRange:(BOOL)withDirtyRange {
  NSRange actualRange = [self actualUsedRange:range];

  if (![self isParagraph]) {
    [self.host.textView.textStorage removeAttribute:[self getKey]
                                              range:actualRange];
  } else {
    [self.host.textView.textStorage
        enumerateAttribute:NSParagraphStyleAttributeName
                   inRange:actualRange
                   options:0
                usingBlock:^(id _Nullable existingValue, NSRange subRange,
                             BOOL *_Nonnull stop) {
                  NSMutableParagraphStyle *pStyle =
                      [(NSParagraphStyle *)existingValue mutableCopy];
                  if (pStyle == nullptr)
                    return;
                  pStyle.textLists = @[];
                  [self.host.textView.textStorage
                      addAttribute:NSParagraphStyleAttributeName
                             value:pStyle
                             range:subRange];
                }];
  }
  [self removeTyping];

  // Notify attributes manager of styling to be re-done if needed.
  if (withDirtyRange) {
    [self.host.attributesManager addDirtyRange:actualRange];
  }
}

- (void)addTypingWithValue:(NSString *)value {
  NSMutableDictionary *newTypingAttrs =
      [self.host.textView.typingAttributes mutableCopy];

  if (![self isParagraph]) {
    newTypingAttrs[[self getKey]] = value;
  } else {
    NSMutableParagraphStyle *pStyle =
        [newTypingAttrs[NSParagraphStyleAttributeName] mutableCopy];
    pStyle.textLists = @[ [[NSTextList alloc] initWithMarkerFormat:value
                                                           options:0] ];
    newTypingAttrs[NSParagraphStyleAttributeName] = pStyle;
  }

  self.host.textView.typingAttributes = newTypingAttrs;
}

- (void)removeTyping {
  NSMutableDictionary *newTypingAttrs =
      [self.host.textView.typingAttributes mutableCopy];

  if (![self isParagraph]) {
    [newTypingAttrs removeObjectForKey:[self getKey]];
    // attributes manager also needs to be notified of custom attributes that
    // shouldn't be extended
    [self.host.attributesManager didRemoveTypingAttribute:[self getKey]];
  } else {
    NSMutableParagraphStyle *pStyle =
        [newTypingAttrs[NSParagraphStyleAttributeName] mutableCopy];
    pStyle.textLists = @[];
    newTypingAttrs[NSParagraphStyleAttributeName] = pStyle;
  }

  self.host.textView.typingAttributes = newTypingAttrs;
}

// custom styles (e.g. ImageStyle, MentionStyle) will likely need to override
// this method
- (BOOL)styleCondition:(id)value range:(NSRange)range {
  if (![self isParagraph]) {
    NSString *valueString = (NSString *)value;
    return valueString != nullptr &&
           [valueString isEqualToString:[self getValue]];
  } else {
    NSParagraphStyle *pStyle = (NSParagraphStyle *)value;
    return pStyle != nullptr && [pStyle.textLists.firstObject.markerFormat
                                    isEqualToString:[self getValue]];
  }
}

- (BOOL)detect:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:[self getKey]
                         withHost:self.host
                          inRange:range
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  } else {
    return [OccurenceUtils detect:[self getKey]
                         withHost:self.host
                          atIndex:range.location
                    checkPrevious:[self isParagraph]
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  }
}

- (BOOL)any:(NSRange)range {
  return [OccurenceUtils any:[self getKey]
                    withHost:self.host
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

- (NSArray<StylePair *> *)all:(NSRange)range {
  return [OccurenceUtils all:[self getKey]
                    withHost:self.host
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

// This method gets overridden
- (void)applyStyling:(NSRange)range {
}

// Called during dirty range re-application to restore a style from a saved
// StylePair
- (void)reapplyFromStylePair:(StylePair *)pair {
  NSRange range = [pair.rangeValue rangeValue];
  [self add:range withTyping:NO withDirtyRange:NO];
}

// Gets a custom attribtue entry for the typingAttributes.
// Only used with inline styles.
- (AttributeEntry *)getEntryIfPresent:(NSRange)range {
  if (![self detect:range]) {
    return nullptr;
  }

  AttributeEntry *entry = [[AttributeEntry alloc] init];
  entry.key = [self getKey];
  entry.value = [self getValue];
  return entry;
}

@end
