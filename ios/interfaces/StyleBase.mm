#import "StyleBase.h"
#import "AttributeEntry.h"
#import "EnrichedTextInputView.h"
#import "OccurenceUtils.h"
#import "RangeUtils.h"

@implementation StyleBase

// This method gets overridden
+ (StyleType)getType {
  return None;
}

// This method gets overridden
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

- (instancetype)initWithInput:(EnrichedTextInputView *)input {
  self = [super init];
  _input = input;
  return self;
}

// aligns range to whole paragraph for the paragraph stlyes
- (NSRange)actualUsedRange:(NSRange)range {
  if (![self isParagraph])
    return range;
  return [_input->textView.textStorage.string paragraphRangeForRange:range];
}

- (void)toggle:(NSRange)range {
  NSRange actualRange = [self actualUsedRange:range];

  BOOL isPresent = [self detect:actualRange];
  if (actualRange.length >= 1) {
    isPresent ? [self remove:actualRange]
              : [self add:actualRange withTyping:YES];
  } else {
    isPresent ? [self removeTyping] : [self addTyping];
  }
}

- (void)add:(NSRange)range withTyping:(BOOL)withTyping {
  NSRange actualRange = [self actualUsedRange:range];

  if (![self isParagraph]) {
    [_input->textView.textStorage addAttribute:[self getKey]
                                         value:[self getValue]
                                         range:actualRange];
  } else {
    [_input->textView.textStorage
        enumerateAttribute:NSParagraphStyleAttributeName
                   inRange:actualRange
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  NSMutableParagraphStyle *pStyle =
                      [(NSParagraphStyle *)value mutableCopy];
                  if (pStyle == nullptr)
                    return;
                  pStyle.textLists = @[ [[NSTextList alloc]
                      initWithMarkerFormat:[self getValue]
                                   options:0] ];
                  [_input->textView.textStorage
                      addAttribute:NSParagraphStyleAttributeName
                             value:pStyle
                             range:range];
                }];

    // Only paragraph styles need additional typing attributes when toggling.
    if (withTyping) {
      [self addTyping];
    }
  }

  // Notify attributes manager of styling to be re-done.
  [self.input->attributesManager addDirtyRange:actualRange];
}

- (void)remove:(NSRange)range {
  NSRange actualRange = [self actualUsedRange:range];

  if (![self isParagraph]) {
    [_input->textView.textStorage removeAttribute:[self getKey]
                                            range:actualRange];
  } else {
    [_input->textView.textStorage
        enumerateAttribute:NSParagraphStyleAttributeName
                   inRange:actualRange
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  NSMutableParagraphStyle *pStyle =
                      [(NSParagraphStyle *)value mutableCopy];
                  if (pStyle == nullptr)
                    return;
                  pStyle.textLists = @[];
                  [_input->textView.textStorage
                      addAttribute:NSParagraphStyleAttributeName
                             value:pStyle
                             range:range];
                }];

    // Paragraph styles also need typing attributes removal.
    [self removeTyping];
  }

  // Notify attributes manager of styling to be re-done.
  [self.input->attributesManager addDirtyRange:actualRange];
}

- (void)addTyping {
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];

  if (![self isParagraph]) {
    newTypingAttrs[[self getKey]] = [self getValue];
  } else {
    NSMutableParagraphStyle *pStyle =
        [newTypingAttrs[NSParagraphStyleAttributeName] mutableCopy];
    pStyle.textLists =
        @[ [[NSTextList alloc] initWithMarkerFormat:[self getValue]
                                            options:0] ];
    newTypingAttrs[NSParagraphStyleAttributeName] = pStyle;
  }

  _input->textView.typingAttributes = newTypingAttrs;
}

- (void)removeTyping {
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];

  if (![self isParagraph]) {
    [newTypingAttrs removeObjectForKey:[self getKey]];
    // attributes manager also needs to be notified of custom attributes that
    // shouldn't be extended
    [_input->attributesManager didRemoveTypingAttribute:[self getKey]];
  } else {
    NSMutableParagraphStyle *pStyle =
        [newTypingAttrs[NSParagraphStyleAttributeName] mutableCopy];
    pStyle.textLists = @[];
    newTypingAttrs[NSParagraphStyleAttributeName] = pStyle;
  }

  _input->textView.typingAttributes = newTypingAttrs;
}

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
                        withInput:_input
                          inRange:range
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  } else {
    return [OccurenceUtils detect:[self getKey]
                        withInput:_input
                          atIndex:range.location
                    checkPrevious:[self isParagraph]
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  }
}

- (BOOL)any:(NSRange)range {
  return [OccurenceUtils any:[self getKey]
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

- (NSArray<StylePair *> *)all:(NSRange)range {
  return [OccurenceUtils all:[self getKey]
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

// This method gets overridden
- (void)applyStyling:(NSRange)range {
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
