#import "EnrichedTextInputStyles.h"

NSDictionary<NSNumber *, id<BaseStyleProtocol>> *
EnrichedTextInputMakeStyles(__kindof EnrichedTextInputView *input) {
  return @{
    @([BoldStyle getStyleType])         : [[BoldStyle alloc] initWithInput:input],
    @([ItalicStyle getStyleType])       : [[ItalicStyle alloc] initWithInput:input],
    @([UnderlineStyle getStyleType])    : [[UnderlineStyle alloc] initWithInput:input],
    @([StrikethroughStyle getStyleType]): [[StrikethroughStyle alloc] initWithInput:input],
    @([InlineCodeStyle getStyleType])   : [[InlineCodeStyle alloc] initWithInput:input],
    @([LinkStyle getStyleType])         : [[LinkStyle alloc] initWithInput:input],
    @([MentionStyle getStyleType])      : [[MentionStyle alloc] initWithInput:input],
    @([H1Style getStyleType])           : [[H1Style alloc] initWithInput:input],
    @([H2Style getStyleType])           : [[H2Style alloc] initWithInput:input],
    @([H3Style getStyleType])           : [[H3Style alloc] initWithInput:input],
    @([UnorderedListStyle getStyleType]): [[UnorderedListStyle alloc] initWithInput:input],
    @([OrderedListStyle getStyleType])  : [[OrderedListStyle alloc] initWithInput:input],
    @([BlockQuoteStyle getStyleType])   : [[BlockQuoteStyle alloc] initWithInput:input],
    @([CodeBlockStyle getStyleType])    : [[CodeBlockStyle alloc] initWithInput:input],
    @([ImageStyle getStyleType])        : [[ImageStyle alloc] initWithInput:input],
  };
}

NSDictionary<NSNumber *, NSArray<NSNumber *> *> *EnrichedTextInputConflictingStyles(void) {
  static NSDictionary<NSNumber *, NSArray<NSNumber *> *> *dict;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dict = @{
      @([BoldStyle getStyleType])         : @[],
      @([ItalicStyle getStyleType])       : @[],
      @([UnderlineStyle getStyleType])    : @[],
      @([StrikethroughStyle getStyleType]): @[],
      @([InlineCodeStyle getStyleType])   : @[@([LinkStyle getStyleType]), @([MentionStyle getStyleType])],
      @([LinkStyle getStyleType])         : @[@([InlineCodeStyle getStyleType]), @([LinkStyle getStyleType]), @([MentionStyle getStyleType])],
      @([MentionStyle getStyleType])      : @[@([InlineCodeStyle getStyleType]), @([LinkStyle getStyleType])],
      @([H1Style getStyleType])           : @[@([H2Style getStyleType]), @([H3Style getStyleType]), @([UnorderedListStyle getStyleType]), @([OrderedListStyle getStyleType]), @([BlockQuoteStyle getStyleType]), @([CodeBlockStyle getStyleType])],
      @([H2Style getStyleType])           : @[@([H1Style getStyleType]), @([H3Style getStyleType]), @([UnorderedListStyle getStyleType]), @([OrderedListStyle getStyleType]), @([BlockQuoteStyle getStyleType]), @([CodeBlockStyle getStyleType])],
      @([H3Style getStyleType])           : @[@([H1Style getStyleType]), @([H2Style getStyleType]), @([UnorderedListStyle getStyleType]), @([OrderedListStyle getStyleType]), @([BlockQuoteStyle getStyleType]), @([CodeBlockStyle getStyleType])],
      @([UnorderedListStyle getStyleType]): @[@([H1Style getStyleType]), @([H2Style getStyleType]), @([H3Style getStyleType]), @([OrderedListStyle getStyleType]), @([BlockQuoteStyle getStyleType]), @([CodeBlockStyle getStyleType])],
      @([OrderedListStyle getStyleType])  : @[@([H1Style getStyleType]), @([H2Style getStyleType]), @([H3Style getStyleType]), @([UnorderedListStyle getStyleType]), @([BlockQuoteStyle getStyleType]), @([CodeBlockStyle getStyleType])],
      @([BlockQuoteStyle getStyleType])   : @[@([H1Style getStyleType]), @([H2Style getStyleType]), @([H3Style getStyleType]), @([UnorderedListStyle getStyleType]), @([OrderedListStyle getStyleType]), @([CodeBlockStyle getStyleType])],
      @([CodeBlockStyle getStyleType])    : @[
        @([H1Style getStyleType]), @([H2Style getStyleType]), @([H3Style getStyleType]),
        @([BoldStyle getStyleType]), @([ItalicStyle getStyleType]), @([UnderlineStyle getStyleType]), @([StrikethroughStyle getStyleType]),
        @([UnorderedListStyle getStyleType]), @([OrderedListStyle getStyleType]), @([BlockQuoteStyle getStyleType]),
        @([InlineCodeStyle getStyleType]), @([MentionStyle getStyleType]), @([LinkStyle getStyleType])
      ],
      @([ImageStyle getStyleType])        : @[@([LinkStyle getStyleType]), @([MentionStyle getStyleType])]
    };
  });
  return dict;
}

NSDictionary<NSNumber *, NSArray<NSNumber *> *> *EnrichedTextInputBlockingStyles(void) {
  static NSDictionary<NSNumber *, NSArray<NSNumber *> *> *dict;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dict = @{
      @([BoldStyle getStyleType])         : @[@([CodeBlockStyle getStyleType])],
      @([ItalicStyle getStyleType])       : @[@([CodeBlockStyle getStyleType])],
      @([UnderlineStyle getStyleType])    : @[@([CodeBlockStyle getStyleType])],
      @([StrikethroughStyle getStyleType]): @[@([CodeBlockStyle getStyleType])],
      @([InlineCodeStyle getStyleType])   : @[@([CodeBlockStyle getStyleType]), @([ImageStyle getStyleType])],
      @([LinkStyle getStyleType])         : @[@([CodeBlockStyle getStyleType]), @([ImageStyle getStyleType])],
      @([MentionStyle getStyleType])      : @[@([CodeBlockStyle getStyleType]), @([ImageStyle getStyleType])],
      @([H1Style getStyleType])           : @[],
      @([H2Style getStyleType])           : @[],
      @([H3Style getStyleType])           : @[],
      @([UnorderedListStyle getStyleType]): @[],
      @([OrderedListStyle getStyleType])  : @[],
      @([BlockQuoteStyle getStyleType])   : @[],
      @([CodeBlockStyle getStyleType])    : @[],
      @([ImageStyle getStyleType])        : @[@([InlineCodeStyle getStyleType])]
    };
  });
  return dict;
}
