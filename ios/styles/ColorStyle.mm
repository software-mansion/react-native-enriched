#import "StyleHeaders.h"
#import "EnrichedTextInputView.h"
#import "OccurenceUtils.h"
#import "FontExtension.h"
#import "StyleTypeEnum.h"
#import "ColorExtension.h"

@implementation ColorStyle {
    EnrichedTextInputView *_input;
}

+ (StyleType)getStyleType { return Colored; }

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  return self;
}

- (void)applyStyle:(NSRange)range {
}

- (void)applyStyle:(NSRange)range color:(UIColor *)color {
  BOOL isStylePresent = [self detectStyle:range color:color];
  
  if (range.length >= 1) {
      isStylePresent ? [self removeAttributes:range] : [self addAttributes:range color: color];
  } else {
      isStylePresent ? [self removeTypingAttributes] : [self addTypingAttributes: color];
  }
}

#pragma mark - Add attributes

- (void)addAttributes:(NSRange)range {
}

- (void)addAttributes:(NSRange)range color:(UIColor *)color {
  if (color == nil) return;
  [_input->textView.textStorage beginEditing];
  [_input->textView.textStorage addAttributes:@{
      NSForegroundColorAttributeName: color,
      NSUnderlineColorAttributeName: color,
      NSStrikethroughColorAttributeName: color
  } range:range];
  [_input->textView.textStorage endEditing];
  _color = color;
}

- (void)addTypingAttributes {
}

-(void)addTypingAttributes:(UIColor *)color {
  NSMutableDictionary *newTypingAttrs = [_input->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSForegroundColorAttributeName] = color;
  newTypingAttrs[NSUnderlineColorAttributeName] = color;
  newTypingAttrs[NSStrikethroughColorAttributeName] = color;
  _input->textView.typingAttributes = newTypingAttrs;
}

#pragma mark - Remove attributes

- (void)removeAttributes:(NSRange)range {
    NSTextStorage *textStorage = _input->textView.textStorage;
    
    LinkStyle *linkStyle = _input->stylesDict[@(Link)];
    InlineCodeStyle *inlineCodeStyle = _input->stylesDict[@(InlineCode)];
    BlockQuoteStyle *blockQuoteStyle = _input->stylesDict[@(BlockQuote)];
    MentionStyle *mentionStyle = _input->stylesDict[@(Mention)];
    
    NSArray<StylePair *> *linkOccurrences = [linkStyle findAllOccurences:range];
    NSArray<StylePair *> *inlineOccurrences = [inlineCodeStyle findAllOccurences:range];
    NSArray<StylePair *> *blockQuoteOccurrences = [blockQuoteStyle findAllOccurences:range];
    NSArray<StylePair *> *mentionOccurrences = [mentionStyle findAllOccurences:range];
    
    NSMutableSet<NSNumber *> *points = [NSMutableSet new];
    [points addObject:@(range.location)];
    [points addObject:@(NSMaxRange(range))];
    
    for (StylePair *pair in linkOccurrences) {
        [points addObject:@([pair.rangeValue rangeValue].location)];
        [points addObject:@(NSMaxRange([pair.rangeValue rangeValue]))];
    }
    for (StylePair *pair in inlineOccurrences) {
        [points addObject:@([pair.rangeValue rangeValue].location)];
        [points addObject:@(NSMaxRange([pair.rangeValue rangeValue]))];
    }
    for (StylePair *pair in blockQuoteOccurrences) {
        [points addObject:@([pair.rangeValue rangeValue].location)];
        [points addObject:@(NSMaxRange([pair.rangeValue rangeValue]))];
    }
    for (StylePair *pair in mentionOccurrences) {
        [points addObject:@([pair.rangeValue rangeValue].location)];
        [points addObject:@(NSMaxRange([pair.rangeValue rangeValue]))];
    }
    
    NSArray<NSNumber *> *sortedPoints = [points.allObjects sortedArrayUsingSelector:@selector(compare:)];
    
    [textStorage beginEditing];
    for (NSUInteger i = 0; i < sortedPoints.count - 1; i++) {
        NSUInteger start = sortedPoints[i].unsignedIntegerValue;
        NSUInteger end = sortedPoints[i + 1].unsignedIntegerValue;
        if (start >= end) continue;
        
        NSRange subrange = NSMakeRange(start, end - start);
        
        UIColor *baseColor = [self baseColorForLocation: subrange.location];
        
        [textStorage addAttribute:NSForegroundColorAttributeName value:baseColor range:subrange];
        [textStorage addAttribute:NSUnderlineColorAttributeName value:baseColor range:subrange];
        [textStorage addAttribute:NSStrikethroughColorAttributeName value:baseColor range:subrange];
    }
    [textStorage endEditing];
}

- (void)removeTypingAttributes {
      NSMutableDictionary *newTypingAttrs = [_input->textView.typingAttributes mutableCopy];
      NSRange selectedRange = _input->textView.selectedRange;
      NSUInteger location = selectedRange.location;
      
      UIColor *baseColor = [self baseColorForLocation:location];
      
      newTypingAttrs[NSForegroundColorAttributeName] = baseColor;
      newTypingAttrs[NSUnderlineColorAttributeName] = baseColor;
      newTypingAttrs[NSStrikethroughColorAttributeName] = baseColor;
      _input->textView.typingAttributes = newTypingAttrs;
}

#pragma mark - Detection

-(BOOL)isInStyle:(NSRange) range styleType:(StyleType)styleType {
  id<BaseStyleProtocol> style = _input->stylesDict[@(styleType)];
  
  return (range.length > 0
          ? [style anyOccurence:range]
          : [style detectStyle:range]);
}

- (BOOL)inLinkAndForegroundColorIsLinkColor:(id)value :(NSRange)range {
  BOOL isInLink = [self isInStyle:range styleType: Link];
  
  return isInLink && [(UIColor *)value isEqualToColor:[_input->config linkColor]];
}

- (BOOL)inInlineCodeAndHasTheSameColor:(id)value :(NSRange)range {
  BOOL isInInlineCode = [self isInStyle:range styleType:InlineCode];
  
  return isInInlineCode && [(UIColor *)value isEqualToColor:[_input->config inlineCodeFgColor]];
}

- (BOOL)inBlockQuoteAndHasTheSameColor:(id)value :(NSRange)range {
  BOOL isInBlockQuote = [self isInStyle:range styleType:BlockQuote];
  
  return isInBlockQuote && [(UIColor *)value isEqualToColor:[_input->config blockquoteColor]];
}

- (BOOL)inMentionAndHasTheSameColor:(id)value :(NSRange)range {
  MentionStyle *mentionStyle = _input->stylesDict[@(Mention)];
  BOOL isInMention = [self isInStyle:range styleType:Mention];
  
  if (!isInMention) return NO;
  
  MentionParams *params = [mentionStyle getMentionParamsAt:range.location];
  if (params == nil) return NO;
  
  MentionStyleProps *styleProps = [_input->config mentionStylePropsForIndicator:params.indicator];
  
  return [(UIColor *)value isEqualToColor:styleProps.color];
}

- (BOOL)styleCondition:(id)value :(NSRange)range {
  if (value == nil) { return NO; }
  
  if ([(UIColor *)value isEqualToColor:_input->config.primaryColor]) { return NO; }
  if ([self inBlockQuoteAndHasTheSameColor:value :range]) { return NO; }
  if ([self inLinkAndForegroundColorIsLinkColor:value :range]) { return NO; }
  if ([self inInlineCodeAndHasTheSameColor:value :range]) { return NO; }
  if ([self inMentionAndHasTheSameColor:value :range]) { return NO; }
  
  return YES;
}

- (BOOL)detectStyle:(NSRange)range {
  UIColor *color = [self getColorInRange:range];
  
  return [self detectStyle:range color:color];
}

- (BOOL)detectStyle:(NSRange)range color:(UIColor *)color {
  if(range.length >= 1) {
    return [OccurenceUtils detect:NSForegroundColorAttributeName withInput:_input inRange:range
      withCondition: ^BOOL(id _Nullable value, NSRange range) {
        return [(UIColor *)value isEqualToColor:color] && [self styleCondition:value :range];
      }
    ];
  } else {
    return [OccurenceUtils detect:NSForegroundColorAttributeName withInput:_input atIndex:range.location checkPrevious:YES
      withCondition:^BOOL(id _Nullable value, NSRange range) {
        return [(UIColor *)value isEqualToColor:color] && [self styleCondition:value :range];
      }
    ];
  }
}

- (BOOL)detectExcludingColor:(UIColor *)excludedColor inRange:(NSRange)range {
    if (![self detectStyle:range]) {
        return NO;
    }
    UIColor *currentColor = [self getColorInRange:range];
    return currentColor != nil && ![currentColor isEqualToColor:excludedColor];
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSForegroundColorAttributeName withInput:_input inRange:range
    withCondition:^BOOL(id _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSForegroundColorAttributeName withInput:_input inRange:range
    withCondition:^BOOL(id _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

- (UIColor *)getColorAt:(NSUInteger)location {
  NSRange effectiveRange = NSMakeRange(0, 0);
  NSRange inputRange = NSMakeRange(0, _input->textView.textStorage.length);
  
  if(location == _input->textView.textStorage.length) {
    UIColor *typingColor = _input->textView.typingAttributes[NSForegroundColorAttributeName];
    return typingColor ?: [_input->config primaryColor];
  }
  
  return [_input->textView.textStorage
    attribute:NSForegroundColorAttributeName
    atIndex:location
    longestEffectiveRange: &effectiveRange
    inRange:inputRange
  ];
}

- (UIColor *)getColorInRange:(NSRange)range {
  NSUInteger location = range.location;
  NSUInteger length = range.length;
  
  NSRange effectiveRange = NSMakeRange(0, 0);
  NSRange inputRange = NSMakeRange(0, _input->textView.textStorage.length);
  
  if(location == _input->textView.textStorage.length) {
    UIColor *typingColor = _input->textView.typingAttributes[NSForegroundColorAttributeName];
    return typingColor ?: [_input->config primaryColor];
  }
  
  NSUInteger queryLocation = location;
  if (length == 0 && location > 0) {
      queryLocation = location - 1;
  }
  
  UIColor *color = [_input->textView.textStorage
    attribute:NSForegroundColorAttributeName
    atIndex:queryLocation
    longestEffectiveRange: &effectiveRange
    inRange:inputRange
  ];
  
  return color;
}

- (UIColor *)baseColorForLocation:(NSUInteger)location {
    BOOL inLink = [self isInStyle:NSMakeRange(location, 0) styleType:Link];
    BOOL inInlineCode = [self isInStyle:NSMakeRange(location, 0) styleType:InlineCode];
    BOOL inBlockQuote = [self isInStyle:NSMakeRange(location, 0) styleType:BlockQuote];
    BOOL inMention = [self isInStyle:NSMakeRange(location, 0) styleType:Mention];
    
    UIColor *baseColor = [_input->config primaryColor];
    if (inMention) {
        MentionStyle *mentionStyle = _input->stylesDict[@(Mention)];
        MentionParams *params = [mentionStyle getMentionParamsAt:location];
        if (params != nil) {
            MentionStyleProps *styleProps = [_input->config mentionStylePropsForIndicator:params.indicator];
            baseColor = styleProps.color;
        }
    } else if (inLink) {
        baseColor = [_input->config linkColor];
    } else if (inInlineCode) {
        baseColor = [_input->config inlineCodeFgColor];
    } else if (inBlockQuote) {
        baseColor = [_input->config blockquoteColor];
    }
    return baseColor;
}

@end
