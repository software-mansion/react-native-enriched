#import <EditorConfig.h>
#import <React/RCTFont.h>

@implementation EditorConfig {
  UIColor *_primaryColor;
  NSNumber *_primaryFontSize;
  NSString *_primaryFontWeight;
  NSString *_primaryFontFamily;
  UIFont *_primaryFont;
  UIFont *_monospacedFont;
  BOOL _primaryFontNeedsRecreation;
  BOOL _monospacedFontNeedsRecreation;
  NSSet<NSNumber*> *_mentionIndicators;
  CGFloat _h1FontSize;
  CGFloat _h2FontSize;
  CGFloat _h3FontSize;
  UIColor *_blockquoteColor;
  CGFloat _blockquoteWidth;
  CGFloat _blockquoteGapWidth;
  UIColor *_inlineCodeFgColor;
  UIColor *_inlineCodeBgColor;
  CGFloat _orderedListGapWidth;
  CGFloat _orderedListMarginLeft;
  UIColor *_unorderedListBulletColor;
  CGFloat _unorderedListBulletSize;
  CGFloat _unorderedListGapWidth;
  CGFloat _unorderedListMarginLeft;
  UIColor *_linkColor;
  TextDecorationLineEnum _linkDecorationLine;
  NSDictionary *_mentionProperties;
}

- (instancetype) init {
  self = [super init];
  _primaryFontNeedsRecreation = YES;
  _monospacedFontNeedsRecreation = YES;
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  EditorConfig *copy = [[[self class] allocWithZone:zone] init];
  copy->_primaryColor = [_primaryColor copy];
  copy->_primaryFontSize = [_primaryFontSize copy];
  copy->_primaryFontWeight = [_primaryFontWeight copy];
  copy->_primaryFontFamily = [_primaryFontFamily copy];
  copy->_primaryFont = [_primaryFont copy];
  copy->_monospacedFont = [_monospacedFont copy];
  copy->_mentionIndicators = [_mentionIndicators copy];
  copy->_h1FontSize = _h1FontSize;
  copy->_h2FontSize = _h2FontSize;
  copy->_h3FontSize = _h3FontSize;
  copy->_inlineCodeFgColor = [_inlineCodeFgColor copy];
  copy->_inlineCodeBgColor = [_inlineCodeBgColor copy];
  copy->_blockquoteColor = [_blockquoteColor copy];
  copy->_blockquoteWidth = _blockquoteWidth;
  copy->_blockquoteGapWidth = _blockquoteGapWidth;
  copy->_inlineCodeFgColor = [_inlineCodeFgColor copy];
  copy->_inlineCodeBgColor = [_inlineCodeBgColor copy];
  copy->_orderedListGapWidth = _orderedListGapWidth;
  copy->_orderedListMarginLeft = _orderedListMarginLeft;
  copy->_unorderedListBulletColor = [_unorderedListBulletColor copy];
  copy->_unorderedListBulletSize = _unorderedListBulletSize;
  copy->_unorderedListGapWidth = _unorderedListGapWidth;
  copy->_unorderedListMarginLeft = _unorderedListMarginLeft;
  copy->_linkColor = [_linkColor copy];
  copy->_linkDecorationLine = [_linkDecorationLine copy];
  copy->_mentionProperties = [_mentionProperties mutableCopy];
  return copy;
}

- (UIColor *)primaryColor {
  return _primaryColor != nullptr ? _primaryColor : UIColor.blackColor;
}

- (void)setPrimaryColor:(UIColor *)newValue {
  _primaryColor = newValue;
}

- (NSNumber *)primaryFontSize {
  return _primaryFontSize != nullptr ? _primaryFontSize : @(14);
}

- (void)setPrimaryFontSize:(NSNumber *)newValue {
  _primaryFontSize = newValue;
  _primaryFontNeedsRecreation = YES;
  _monospacedFontNeedsRecreation = YES;
}

- (NSString *)primaryFontWeight {
  return _primaryFontWeight != nullptr ? _primaryFontWeight : [NSString stringWithFormat:@"%@", @(UIFontWeightRegular)];
}

- (void)setPrimaryFontWeight:(NSString *)newValue {
  _primaryFontWeight = newValue;
  _primaryFontNeedsRecreation = YES;
  _monospacedFontNeedsRecreation = YES;
}

- (NSString *)primaryFontFamily {
  return _primaryFontFamily;
}

- (void)setPrimaryFontFamily:(NSString *)newValue {
  _primaryFontFamily = newValue;
  _primaryFontNeedsRecreation = YES;
}

- (UIFont *)primaryFont {
  if(_primaryFontNeedsRecreation) {
    _primaryFontNeedsRecreation = NO;
    
    NSString *newFontWeight = [self primaryFontWeight];
    // fix RCTFontWeight conversion warnings:
    // sometimes changing font family comes with weight '0' if not specified
    // RCTConvert doesn't recognize this value so we just nullify it and it gets a default value
    if([newFontWeight isEqualToString:@"0"]) {
      newFontWeight = nullptr;
    }
    
    _primaryFont = [RCTFont updateFont:nullptr
      withFamily:[self primaryFontFamily]
      size:[self primaryFontSize]
      weight:newFontWeight
      style:nullptr
      variant:nullptr
      scaleMultiplier: 1];
  }
  return _primaryFont;
}

- (UIFont *)monospacedFont {
  if(_monospacedFontNeedsRecreation) {
    _monospacedFontNeedsRecreation = NO;
    _monospacedFont = [UIFont monospacedSystemFontOfSize: [[self primaryFontSize] floatValue]  weight: [[self primaryFontWeight] floatValue]];
  }
  return _monospacedFont;
}

- (NSSet<NSNumber*>*)mentionIndicators {
  return _mentionIndicators != nullptr ? _mentionIndicators : [[NSSet alloc] init];
}

- (void)setMentionIndicators:(NSSet<NSNumber*>*)newValue {
  _mentionIndicators = newValue;
}

- (CGFloat)h1FontSize {
  return _h1FontSize;
}

- (void)setH1FontSize:(CGFloat)newValue {
  _h1FontSize = newValue;
}

- (CGFloat)h2FontSize {
  return _h2FontSize;
}

- (void)setH2FontSize:(CGFloat)newValue {
  _h2FontSize = newValue;
}

- (CGFloat)h3FontSize {
  return _h3FontSize;
}

- (void)setH3FontSize:(CGFloat)newValue {
  _h3FontSize = newValue;
}

- (UIColor *)blockquoteColor {
  return _blockquoteColor;
}

- (void)setBlockquoteColor:(UIColor *)newValue {
  _blockquoteColor = newValue;
}

- (CGFloat)blockquoteWidth {
  return _blockquoteWidth;
}

- (void)setBlockquoteWidth:(CGFloat)newValue {
  _blockquoteWidth = newValue;
}


- (CGFloat)blockquoteGapWidth {
  return _blockquoteGapWidth;
}

- (void)setBlockquoteGapWidth:(CGFloat)newValue {
  _blockquoteGapWidth = newValue;
}

- (UIColor *)inlineCodeFgColor {
  return _inlineCodeFgColor;
}

- (void)setInlineCodeFgColor:(UIColor *)newValue {
  _inlineCodeFgColor = newValue;
}

- (UIColor *)inlineCodeBgColor {
  return _inlineCodeBgColor;
}

- (void)setInlineCodeBgColor:(UIColor *)newValue {
  _inlineCodeBgColor = newValue;
}

- (CGFloat)orderedListGapWidth {
  return _orderedListGapWidth;
}

- (void)setOrderedListGapWidth:(CGFloat)newValue {
  _orderedListGapWidth = newValue;
}

- (CGFloat)orderedListMarginLeft {
  return _orderedListMarginLeft;
}

- (void)setOrderedListMarginLeft:(CGFloat)newValue {
  _orderedListMarginLeft = newValue;
}

- (CGFloat)orderedListMarkerWidth {
  NSDictionary *markerAttributes = @{
    NSFontAttributeName: [self primaryFont],
    NSForegroundColorAttributeName: [self primaryColor]
  };
  // TODO: marker widths could be dynamic, for now we settle with (usually) the widest 2-digit marker
  return [@"88." sizeWithAttributes:markerAttributes].width;
}

- (UIColor *)unorderedListBulletColor {
  return _unorderedListBulletColor;
}

- (void)setUnorderedListBulletColor:(UIColor *)newValue {
  _unorderedListBulletColor = newValue;
}

- (CGFloat)unorderedListBulletSize {
  return _unorderedListBulletSize;
}

- (void)setUnorderedListBulletSize:(CGFloat)newValue {
  _unorderedListBulletSize = newValue;
}

- (CGFloat)unorderedListGapWidth {
  return _unorderedListGapWidth;
}

- (void)setUnorderedListGapWidth:(CGFloat)newValue {
  _unorderedListGapWidth = newValue;
}

- (CGFloat)unorderedListMarginLeft {
  return _unorderedListMarginLeft;
}

- (void)setUnorderedListMarginLeft:(CGFloat)newValue {
  _unorderedListMarginLeft = newValue;
}

- (UIColor *)linkColor {
  return _linkColor;
}

- (void)setLinkColor:(UIColor *)newValue {
  _linkColor = newValue;
}

- (TextDecorationLineEnum)linkDecorationLine {
  return _linkDecorationLine;
}

- (void)setLinkDecorationLine:(TextDecorationLineEnum)newValue {
  _linkDecorationLine = newValue;
}

- (void)setMentionStyleProps:(NSDictionary *)newValue {
  _mentionProperties = [newValue mutableCopy];
}

- (MentionStyleProps *)mentionStylePropsForIndicator:(NSString *)indicator {
  if(_mentionProperties.count == 1 && _mentionProperties[@"all"] != nullptr) {
    // single props for all the indicators
    return _mentionProperties[@"all"];
  } else if(_mentionProperties[indicator] != nullptr) {
    return _mentionProperties[indicator];
  }
  MentionStyleProps *fallbackProps = [[MentionStyleProps alloc] init];
  fallbackProps.color = [UIColor blueColor];
  fallbackProps.backgroundColor = [UIColor yellowColor];
  fallbackProps.decorationLine = DecorationUnderline;
  return fallbackProps;
}

@end
