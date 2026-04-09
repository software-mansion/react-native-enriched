#import "StyleUtils.h"

@implementation StyleUtils

+ (NSDictionary *)conflictMap {
  return @{
    @([BoldStyle getType]) : @[],
    @([ItalicStyle getType]) : @[],
    @([UnderlineStyle getType]) : @[],
    @([StrikethroughStyle getType]) : @[],
    @([InlineCodeStyle getType]) :
        @[ @([LinkStyle getType]), @([MentionStyle getType]) ],
    @([LinkStyle getType]) : @[
      @([InlineCodeStyle getType]), @([LinkStyle getType]),
      @([MentionStyle getType])
    ],
    @([MentionStyle getType]) :
        @[ @([InlineCodeStyle getType]), @([LinkStyle getType]) ],
    @([H1Style getType]) : @[
      @([H2Style getType]), @([H3Style getType]), @([H4Style getType]),
      @([H5Style getType]), @([H6Style getType]),
      @([UnorderedListStyle getType]), @([OrderedListStyle getType]),
      @([BlockQuoteStyle getType]), @([CodeBlockStyle getType]),
      @([CheckboxListStyle getType])
    ],
    @([H2Style getType]) : @[
      @([H1Style getType]), @([H3Style getType]), @([H4Style getType]),
      @([H5Style getType]), @([H6Style getType]),
      @([UnorderedListStyle getType]), @([OrderedListStyle getType]),
      @([BlockQuoteStyle getType]), @([CodeBlockStyle getType]),
      @([CheckboxListStyle getType])
    ],
    @([H3Style getType]) : @[
      @([H1Style getType]), @([H2Style getType]), @([H4Style getType]),
      @([H5Style getType]), @([H6Style getType]),
      @([UnorderedListStyle getType]), @([OrderedListStyle getType]),
      @([BlockQuoteStyle getType]), @([CodeBlockStyle getType]),
      @([CheckboxListStyle getType])
    ],
    @([H4Style getType]) : @[
      @([H1Style getType]), @([H2Style getType]), @([H3Style getType]),
      @([H5Style getType]), @([H6Style getType]),
      @([UnorderedListStyle getType]), @([OrderedListStyle getType]),
      @([BlockQuoteStyle getType]), @([CodeBlockStyle getType]),
      @([CheckboxListStyle getType])
    ],
    @([H5Style getType]) : @[
      @([H1Style getType]), @([H2Style getType]), @([H3Style getType]),
      @([H4Style getType]), @([H6Style getType]),
      @([UnorderedListStyle getType]), @([OrderedListStyle getType]),
      @([BlockQuoteStyle getType]), @([CodeBlockStyle getType]),
      @([CheckboxListStyle getType])
    ],
    @([H6Style getType]) : @[
      @([H1Style getType]), @([H2Style getType]), @([H3Style getType]),
      @([H4Style getType]), @([H5Style getType]),
      @([UnorderedListStyle getType]), @([OrderedListStyle getType]),
      @([BlockQuoteStyle getType]), @([CodeBlockStyle getType]),
      @([CheckboxListStyle getType])
    ],
    @([UnorderedListStyle getType]) : @[
      @([H1Style getType]), @([H2Style getType]), @([H3Style getType]),
      @([H4Style getType]), @([H5Style getType]), @([H6Style getType]),
      @([OrderedListStyle getType]), @([BlockQuoteStyle getType]),
      @([CodeBlockStyle getType]), @([CheckboxListStyle getType])
    ],
    @([OrderedListStyle getType]) : @[
      @([H1Style getType]), @([H2Style getType]), @([H3Style getType]),
      @([H4Style getType]), @([H5Style getType]), @([H6Style getType]),
      @([UnorderedListStyle getType]), @([BlockQuoteStyle getType]),
      @([CodeBlockStyle getType]), @([CheckboxListStyle getType])
    ],
    @([CheckboxListStyle getType]) : @[
      @([H1Style getType]), @([H2Style getType]), @([H3Style getType]),
      @([H4Style getType]), @([H5Style getType]), @([H6Style getType]),
      @([UnorderedListStyle getType]), @([OrderedListStyle getType]),
      @([BlockQuoteStyle getType]), @([CodeBlockStyle getType])
    ],
    @([BlockQuoteStyle getType]) : @[
      @([H1Style getType]), @([H2Style getType]), @([H3Style getType]),
      @([H4Style getType]), @([H5Style getType]), @([H6Style getType]),
      @([UnorderedListStyle getType]), @([OrderedListStyle getType]),
      @([CodeBlockStyle getType]), @([CheckboxListStyle getType])
    ],
    @([CodeBlockStyle getType]) : @[
      @([H1Style getType]), @([H2Style getType]), @([H3Style getType]),
      @([H4Style getType]), @([H5Style getType]), @([H6Style getType]),
      @([BoldStyle getType]), @([UnderlineStyle getType]),
      @([ItalicStyle getType]), @([StrikethroughStyle getType]),
      @([UnorderedListStyle getType]), @([OrderedListStyle getType]),
      @([BlockQuoteStyle getType]), @([InlineCodeStyle getType]),
      @([MentionStyle getType]), @([LinkStyle getType]),
      @([CheckboxListStyle getType])
    ],
    @([ImageStyle getType]) :
        @[ @([LinkStyle getType]), @([MentionStyle getType]) ]
  };
}

+ (NSDictionary *)blockingMap {
  return @{
    @([BoldStyle getType]) : @[ @([CodeBlockStyle getType]) ],
    @([ItalicStyle getType]) : @[ @([CodeBlockStyle getType]) ],
    @([UnderlineStyle getType]) : @[ @([CodeBlockStyle getType]) ],
    @([StrikethroughStyle getType]) : @[ @([CodeBlockStyle getType]) ],
    @([InlineCodeStyle getType]) :
        @[ @([CodeBlockStyle getType]), @([ImageStyle getType]) ],
    @([LinkStyle getType]) :
        @[ @([CodeBlockStyle getType]), @([ImageStyle getType]) ],
    @([MentionStyle getType]) :
        @[ @([CodeBlockStyle getType]), @([ImageStyle getType]) ],
    @([H1Style getType]) : @[],
    @([H2Style getType]) : @[],
    @([H3Style getType]) : @[],
    @([H4Style getType]) : @[],
    @([H5Style getType]) : @[],
    @([H6Style getType]) : @[],
    @([UnorderedListStyle getType]) : @[],
    @([OrderedListStyle getType]) : @[],
    @([CheckboxListStyle getType]) : @[],
    @([BlockQuoteStyle getType]) : @[],
    @([CodeBlockStyle getType]) : @[],
    @([ImageStyle getType]) : @[ @([InlineCodeStyle getType]) ]
  };
}

+ (NSDictionary *)stylesDictForHost:(id<EnrichedStyleHost>)host
                            isInput:(BOOL)isInput {
  NSArray<Class> *baseClasses = @[
    [BoldStyle class], [ItalicStyle class], [UnderlineStyle class],
    [StrikethroughStyle class], [InlineCodeStyle class], [LinkStyle class],
    [MentionStyle class], [H1Style class], [H2Style class], [H3Style class],
    [H4Style class], [H5Style class], [H6Style class],
    [UnorderedListStyle class], [OrderedListStyle class],
    [CheckboxListStyle class], [BlockQuoteStyle class], [CodeBlockStyle class],
    [ImageStyle class]
  ];

  NSArray<Class> *viewerClasses = @[
    [EnrichedTextBoldStyle class], [EnrichedTextItalicStyle class],
    [EnrichedTextUnderlineStyle class], [EnrichedTextStrikethroughStyle class],
    [EnrichedTextInlineCodeStyle class], [EnrichedTextLinkStyle class],
    [EnrichedTextMentionStyle class], [EnrichedTextH1Style class],
    [EnrichedTextH2Style class], [EnrichedTextH3Style class],
    [EnrichedTextH4Style class], [EnrichedTextH5Style class],
    [EnrichedTextH6Style class], [EnrichedTextUnorderedListStyle class],
    [EnrichedTextOrderedListStyle class], [EnrichedTextCheckboxListStyle class],
    [EnrichedTextBlockQuoteStyle class], [EnrichedTextCodeBlockStyle class],
    [EnrichedTextImageStyle class]
  ];

  NSMutableDictionary *dict = [NSMutableDictionary new];

  for (NSUInteger i = 0; i < baseClasses.count; i++) {
    // Choose the class based on the context
    Class targetClass = isInput ? baseClasses[i] : viewerClasses[i];

    // Instantiate and add to dictionary
    // We use [baseClasses[i] getType] for the key to ensure the
    // conflict maps (which use base types) always match.
    StyleBase *instance = [[targetClass alloc] initWithHost:host];
    dict[@([baseClasses[i] getType])] = instance;
  }

  return [dict copy];
}

// returns false when style shouldn't be applied and true when it can be
+ (BOOL)handleStyleBlocksAndConflicts:(StyleType)type
                                range:(NSRange)range
                              forHost:(id<EnrichedStyleHost>)host {
  // handle blocking styles: if any is present we do not apply the toggled style
  NSArray<NSNumber *> *blocking =
      [self getPresentStyleTypesFrom:host.blockingStyles[@(type)]
                               range:range
                             forHost:host];
  if (blocking.count != 0) {
    return NO;
  }

  // handle conflicting styles: remove styles within the range
  NSArray<NSNumber *> *conflicting =
      [self getPresentStyleTypesFrom:host.conflictingStyles[@(type)]
                               range:range
                             forHost:host];
  if (conflicting.count != 0) {
    for (NSNumber *type in conflicting) {
      StyleBase *style = host.stylesDict[type];

      if ([style isParagraph]) {
        // for paragraph styles we can just call remove since it will pick up
        // proper paragraph range
        [style remove:range withDirtyRange:YES];
      } else {
        // for inline styles we have to differentiate betweeen normal and typing
        // attributes removal
        range.length >= 1 ? [style remove:range withDirtyRange:YES]
                          : [style removeTyping];
      }
    }
  }
  return YES;
}

+ (NSArray *)getPresentStyleTypesFrom:(NSArray *)types
                                range:(NSRange)range
                              forHost:(id<EnrichedStyleHost>)host {
  NSMutableArray<NSNumber *> *resultArray =
      [[NSMutableArray<NSNumber *> alloc] init];
  for (NSNumber *type in types) {
    StyleBase *style = host.stylesDict[type];

    if (range.length >= 1) {
      if ([style any:range]) {
        [resultArray addObject:type];
      }
    } else {
      if ([style detect:range]) {
        [resultArray addObject:type];
      }
    }
  }
  return resultArray;
}

+ (void)addStyleBlock:(StyleType)blocking
                   to:(StyleType)blocked
              forHost:(id<EnrichedStyleHost>)host {
  NSMutableArray *blocksArr = [host.blockingStyles[@(blocked)] mutableCopy];
  if (![blocksArr containsObject:@(blocking)]) {
    [blocksArr addObject:@(blocking)];
    host.blockingStyles[@(blocked)] = blocksArr;
  }
}

+ (void)removeStyleBlock:(StyleType)blocking
                    from:(StyleType)blocked
                 forHost:(id<EnrichedStyleHost>)host {
  NSMutableArray *blocksArr = [host.blockingStyles[@(blocked)] mutableCopy];
  if ([blocksArr containsObject:@(blocking)]) {
    [blocksArr removeObject:@(blocking)];
    host.blockingStyles[@(blocked)] = blocksArr;
  }
}

+ (void)addStyleConflict:(StyleType)conflicting
                      to:(StyleType)conflicted
                 forHost:(id<EnrichedStyleHost>)host {
  NSMutableArray *conflictsArr =
      [host.conflictingStyles[@(conflicted)] mutableCopy];
  if (![conflictsArr containsObject:@(conflicting)]) {
    [conflictsArr addObject:@(conflicting)];
    host.conflictingStyles[@(conflicted)] = conflictsArr;
  }
}

+ (void)removeStyleConflict:(StyleType)conflicting
                       from:(StyleType)conflicted
                    forHost:(id<EnrichedStyleHost>)host {
  NSMutableArray *conflictsArr =
      [host.conflictingStyles[@(conflicted)] mutableCopy];
  if ([conflictsArr containsObject:@(conflicting)]) {
    [conflictsArr removeObject:@(conflicting)];
    host.conflictingStyles[@(conflicted)] = conflictsArr;
  }
}

@end
