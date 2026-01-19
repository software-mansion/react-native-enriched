#import <InputConfig.h>
#import <React/RCTFont.h>

@implementation InputConfig {
  UIColor *_primaryColor;
  NSNumber *_primaryFontSize;
  NSString *_primaryFontWeight;
  NSString *_primaryFontFamily;
  UIFont *_primaryFont;
  UIFont *_monospacedFont;
  BOOL _primaryFontNeedsRecreation;
  BOOL _monospacedFontNeedsRecreation;
  NSSet<NSNumber *> *_mentionIndicators;
  CGFloat _h1FontSize;
  BOOL _h1Bold;
  CGFloat _h2FontSize;
  BOOL _h2Bold;
  CGFloat _h3FontSize;
  BOOL _h3Bold;
  CGFloat _h4FontSize;
  BOOL _h4Bold;
  CGFloat _h5FontSize;
  BOOL _h5Bold;
  CGFloat _h6FontSize;
  BOOL _h6Bold;
  UIColor *_blockquoteBorderColor;
  CGFloat _blockquoteBorderWidth;
  CGFloat _blockquoteGapWidth;
  UIColor *_blockquoteColor;
  UIColor *_inlineCodeFgColor;
  UIColor *_inlineCodeBgColor;
  CGFloat _orderedListGapWidth;
  CGFloat _orderedListMarginLeft;
  NSString *_orderedListMarkerFontWeight;
  UIColor *_orderedListMarkerColor;
  UIFont *_orderedListMarkerFont;
  BOOL _olMarkerFontNeedsRecreation;
  UIColor *_unorderedListBulletColor;
  CGFloat _unorderedListBulletSize;
  CGFloat _unorderedListGapWidth;
  CGFloat _unorderedListMarginLeft;
  UIColor *_linkColor;
  TextDecorationLineEnum _linkDecorationLine;
  NSDictionary *_mentionProperties;
  UIColor *_codeBlockFgColor;
  CGFloat _codeBlockBorderRadius;
  UIColor *_codeBlockBgColor;
  LinkRegexConfig *_linkRegexConfig;
  NSRegularExpression *_parsedLinkRegex;
  CGFloat _checkboxListBoxSize;
  CGFloat _checkboxListGapWidth;
  CGFloat _checkboxListMarginLeft;
  UIColor *_checkboxListBoxColor;
  UIImage *_checkboxCheckedImage;
  UIImage *_checkboxUncheckedImage;
}

- (instancetype)init {
  self = [super init];
  _primaryFontNeedsRecreation = YES;
  _monospacedFontNeedsRecreation = YES;
  _olMarkerFontNeedsRecreation = YES;
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  InputConfig *copy = [[[self class] allocWithZone:zone] init];
  copy->_primaryColor = [_primaryColor copy];
  copy->_primaryFontSize = [_primaryFontSize copy];
  copy->_primaryFontWeight = [_primaryFontWeight copy];
  copy->_primaryFontFamily = [_primaryFontFamily copy];
  copy->_primaryFont = [_primaryFont copy];
  copy->_monospacedFont = [_monospacedFont copy];
  copy->_mentionIndicators = [_mentionIndicators copy];
  copy->_h1FontSize = _h1FontSize;
  copy->_h1Bold = _h1Bold;
  copy->_h2FontSize = _h2FontSize;
  copy->_h2Bold = _h2Bold;
  copy->_h3FontSize = _h3FontSize;
  copy->_h3Bold = _h3Bold;
  copy->_h4FontSize = _h4FontSize;
  copy->_h4Bold = _h4Bold;
  copy->_h5FontSize = _h5FontSize;
  copy->_h5Bold = _h5Bold;
  copy->_h6FontSize = _h6FontSize;
  copy->_h6Bold = _h6Bold;
  copy->_blockquoteBorderColor = [_blockquoteBorderColor copy];
  copy->_blockquoteBorderWidth = _blockquoteBorderWidth;
  copy->_blockquoteGapWidth = _blockquoteGapWidth;
  copy->_blockquoteColor = [_blockquoteColor copy];
  copy->_inlineCodeFgColor = [_inlineCodeFgColor copy];
  copy->_inlineCodeBgColor = [_inlineCodeBgColor copy];
  copy->_orderedListGapWidth = _orderedListGapWidth;
  copy->_orderedListMarginLeft = _orderedListMarginLeft;
  copy->_orderedListMarkerFontWeight = [_orderedListMarkerFontWeight copy];
  copy->_orderedListMarkerColor = [_orderedListMarkerColor copy];
  copy->_orderedListMarkerFont = [_orderedListMarkerFont copy];
  copy->_unorderedListBulletColor = [_unorderedListBulletColor copy];
  copy->_unorderedListBulletSize = _unorderedListBulletSize;
  copy->_unorderedListGapWidth = _unorderedListGapWidth;
  copy->_unorderedListMarginLeft = _unorderedListMarginLeft;
  copy->_linkColor = [_linkColor copy];
  copy->_linkDecorationLine = [_linkDecorationLine copy];
  copy->_mentionProperties = [_mentionProperties mutableCopy];
  copy->_codeBlockFgColor = [_codeBlockFgColor copy];
  copy->_codeBlockBgColor = [_codeBlockBgColor copy];
  copy->_codeBlockBorderRadius = _codeBlockBorderRadius;
  copy->_linkRegexConfig = [_linkRegexConfig copy];
  copy->_parsedLinkRegex = [_parsedLinkRegex copy];
  copy->_checkboxListBoxSize = _checkboxListBoxSize;
  copy->_checkboxListGapWidth = _checkboxListGapWidth;
  copy->_checkboxListMarginLeft = _checkboxListMarginLeft;
  copy->_checkboxListBoxColor = [_checkboxListBoxColor copy];
  copy->_checkboxCheckedImage = _checkboxCheckedImage;
  copy->_checkboxUncheckedImage = _checkboxUncheckedImage;
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
  _olMarkerFontNeedsRecreation = YES;
}

- (NSString *)primaryFontWeight {
  return _primaryFontWeight != nullptr
             ? _primaryFontWeight
             : [NSString stringWithFormat:@"%@", @(UIFontWeightRegular)];
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
  _olMarkerFontNeedsRecreation = YES;
}

- (UIFont *)primaryFont {
  if (_primaryFontNeedsRecreation) {
    _primaryFontNeedsRecreation = NO;

    NSString *newFontWeight = [self primaryFontWeight];
    // fix RCTFontWeight conversion warnings:
    // sometimes changing font family comes with weight '0' if not specified
    // RCTConvert doesn't recognize this value so we just nullify it and it gets
    // a default value
    if ([newFontWeight isEqualToString:@"0"]) {
      newFontWeight = nullptr;
    }

    _primaryFont = [RCTFont updateFont:nullptr
                            withFamily:[self primaryFontFamily]
                                  size:[self primaryFontSize]
                                weight:newFontWeight
                                 style:nullptr
                               variant:nullptr
                       scaleMultiplier:1];
  }
  return _primaryFont;
}

- (UIFont *)monospacedFont {
  if (_monospacedFontNeedsRecreation) {
    _monospacedFontNeedsRecreation = NO;
    _monospacedFont = [UIFont
        monospacedSystemFontOfSize:[[self primaryFontSize] floatValue]
                            weight:[[self primaryFontWeight] floatValue]];
  }
  return _monospacedFont;
}

- (NSSet<NSNumber *> *)mentionIndicators {
  return _mentionIndicators != nullptr ? _mentionIndicators
                                       : [[NSSet alloc] init];
}

- (void)setMentionIndicators:(NSSet<NSNumber *> *)newValue {
  _mentionIndicators = newValue;
}

- (CGFloat)h1FontSize {
  return _h1FontSize;
}

- (void)setH1FontSize:(CGFloat)newValue {
  _h1FontSize = newValue;
}

- (BOOL)h1Bold {
  return _h1Bold;
}

- (void)setH1Bold:(BOOL)newValue {
  _h1Bold = newValue;
}

- (CGFloat)h2FontSize {
  return _h2FontSize;
}

- (void)setH2FontSize:(CGFloat)newValue {
  _h2FontSize = newValue;
}

- (BOOL)h2Bold {
  return _h2Bold;
}

- (void)setH2Bold:(BOOL)newValue {
  _h2Bold = newValue;
}

- (CGFloat)h3FontSize {
  return _h3FontSize;
}

- (void)setH3FontSize:(CGFloat)newValue {
  _h3FontSize = newValue;
}

- (BOOL)h3Bold {
  return _h3Bold;
}

- (void)setH3Bold:(BOOL)newValue {
  _h3Bold = newValue;
}

- (CGFloat)h4FontSize {
  return _h4FontSize;
}

- (void)setH4FontSize:(CGFloat)newValue {
  _h4FontSize = newValue;
}

- (BOOL)h4Bold {
  return _h4Bold;
}

- (void)setH4Bold:(BOOL)newValue {
  _h4Bold = newValue;
}

- (CGFloat)h5FontSize {
  return _h5FontSize;
}

- (void)setH5FontSize:(CGFloat)newValue {
  _h5FontSize = newValue;
}

- (BOOL)h5Bold {
  return _h5Bold;
}

- (void)setH5Bold:(BOOL)newValue {
  _h5Bold = newValue;
}

- (CGFloat)h6FontSize {
  return _h6FontSize;
}

- (void)setH6FontSize:(CGFloat)newValue {
  _h6FontSize = newValue;
}

- (BOOL)h6Bold {
  return _h6Bold;
}

- (void)setH6Bold:(BOOL)newValue {
  _h6Bold = newValue;
}

- (UIColor *)blockquoteBorderColor {
  return _blockquoteBorderColor;
}

- (void)setBlockquoteBorderColor:(UIColor *)newValue {
  _blockquoteBorderColor = newValue;
}

- (CGFloat)blockquoteBorderWidth {
  return _blockquoteBorderWidth;
}

- (void)setBlockquoteBorderWidth:(CGFloat)newValue {
  _blockquoteBorderWidth = newValue;
}

- (CGFloat)blockquoteGapWidth {
  return _blockquoteGapWidth;
}

- (void)setBlockquoteGapWidth:(CGFloat)newValue {
  _blockquoteGapWidth = newValue;
}

- (UIColor *)blockquoteColor {
  return _blockquoteColor;
}

- (void)setBlockquoteColor:(UIColor *)newValue {
  _blockquoteColor = newValue;
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

- (NSString *)orderedListMarkerFontWeight {
  return _orderedListMarkerFontWeight;
}

- (void)setOrderedListMarkerFontWeight:(NSString *)newValue {
  _orderedListMarkerFontWeight = newValue;
  _olMarkerFontNeedsRecreation = YES;
}

- (UIColor *)orderedListMarkerColor {
  return _orderedListMarkerColor;
}

- (void)setOrderedListMarkerColor:(UIColor *)newValue {
  _orderedListMarkerColor = newValue;
}

- (UIFont *)orderedListMarkerFont {
  if (_olMarkerFontNeedsRecreation) {
    _olMarkerFontNeedsRecreation = NO;

    NSString *newFontWeight = [self orderedListMarkerFontWeight];
    // fix RCTFontWeight conversion warnings:
    // sometimes changing font family comes with weight '0' if not specified
    // RCTConvert doesn't recognize this value so we just nullify it and it gets
    // a default value
    if ([newFontWeight isEqualToString:@"0"]) {
      newFontWeight = nullptr;
    }

    _orderedListMarkerFont = [RCTFont updateFont:nullptr
                                      withFamily:[self primaryFontFamily]
                                            size:[self primaryFontSize]
                                          weight:newFontWeight
                                           style:nullptr
                                         variant:nullptr
                                 scaleMultiplier:1];
  }
  return _orderedListMarkerFont;
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
  if (_mentionProperties.count == 1 && _mentionProperties[@"all"] != nullptr) {
    // single props for all the indicators
    return _mentionProperties[@"all"];
  } else if (_mentionProperties[indicator] != nullptr) {
    return _mentionProperties[indicator];
  }
  MentionStyleProps *fallbackProps = [[MentionStyleProps alloc] init];
  fallbackProps.color = [UIColor blueColor];
  fallbackProps.backgroundColor = [UIColor yellowColor];
  fallbackProps.decorationLine = DecorationUnderline;
  return fallbackProps;
}

- (UIColor *)codeBlockFgColor {
  return _codeBlockFgColor;
}

- (void)setCodeBlockFgColor:(UIColor *)newValue {
  _codeBlockFgColor = newValue;
}

- (UIColor *)codeBlockBgColor {
  return _codeBlockBgColor;
}

- (void)setCodeBlockBgColor:(UIColor *)newValue {
  _codeBlockBgColor = newValue;
}

- (CGFloat)codeBlockBorderRadius {
  return _codeBlockBorderRadius;
}

- (void)setCodeBlockBorderRadius:(CGFloat)newValue {
  _codeBlockBorderRadius = newValue;
}

- (LinkRegexConfig *)linkRegexConfig {
  return _linkRegexConfig;
}

- (void)setLinkRegexConfig:(LinkRegexConfig *)newValue {
  _linkRegexConfig = newValue;

  // try initializing the native regular expression if it applies
  if (_linkRegexConfig.isDefault || _linkRegexConfig.isDisabled) {
    return;
  }

  NSError *regexInitError;
  NSRegularExpressionOptions options =
      (_linkRegexConfig.caseInsensitive ? NSRegularExpressionCaseInsensitive
                                        : 0) |
      (_linkRegexConfig.dotAll ? NSRegularExpressionDotMatchesLineSeparators
                               : 0);
  NSRegularExpression *userRegex =
      [NSRegularExpression regularExpressionWithPattern:_linkRegexConfig.pattern
                                                options:options
                                                  error:&regexInitError];

  if (regexInitError) {
    RCTLogWarn(@"[EnrichedTextInput]: Couldn't parse the user-defined link "
               @"regex, falling back to a default regex.");
    _parsedLinkRegex = nullptr;
  } else {
    _parsedLinkRegex = userRegex;
  }
}

- (NSRegularExpression *)parsedLinkRegex {
  return _parsedLinkRegex;
}

- (CGFloat)checkboxListBoxSize {
  return _checkboxListBoxSize;
}

- (void)setCheckboxListBoxSize:(CGFloat)newValue {
  if (_checkboxListBoxSize != newValue) {
    _checkboxListBoxSize = newValue;
    // Invalidate checkbox images because box size changed
    _checkboxCheckedImage = nil;
    _checkboxUncheckedImage = nil;
  }
}

- (CGFloat)checkboxListGapWidth {
  return _checkboxListGapWidth;
}

- (void)setCheckboxListGapWidth:(CGFloat)newValue {
  _checkboxListGapWidth = newValue;
}

- (CGFloat)checkboxListMarginLeft {
  return _checkboxListMarginLeft;
}

- (void)setCheckboxListMarginLeft:(CGFloat)newValue {
  _checkboxListMarginLeft = newValue;
}

- (UIColor *)checkboxListBoxColor {
  return _checkboxListBoxColor;
}

- (void)setCheckboxListBoxColor:(UIColor *)newValue {
  if (_checkboxListBoxColor != newValue) {
    _checkboxListBoxColor = newValue;
    // Invalidate checkbox images because color changed
    _checkboxCheckedImage = nil;
    _checkboxUncheckedImage = nil;
  }
}

- (UIImage *)checkboxCheckedImage {
  if (!_checkboxCheckedImage) {
    _checkboxCheckedImage = [self generateCheckboxImage:YES];
  }
  return _checkboxCheckedImage;
}

- (UIImage *)checkboxUncheckedImage {
  if (!_checkboxUncheckedImage) {
    _checkboxUncheckedImage = [self generateCheckboxImage:NO];
  }
  return _checkboxUncheckedImage;
}

- (UIImage *)generateCheckboxImage:(BOOL)isChecked {
  CGFloat boxSize = self.checkboxListBoxSize;
  UIColor *boxColor = self.checkboxListBoxColor ?: [UIColor blackColor];

  UIGraphicsBeginImageContextWithOptions(CGSizeMake(boxSize, boxSize), NO, 0.0);
  CGRect localRect = CGRectMake(0, 0, boxSize, boxSize);
  CGFloat cornerRadius = boxSize * 0.15f;
  CGFloat strokeWidth = boxSize * 0.1f;
  CGRect insetRect =
      CGRectInset(localRect, strokeWidth / 2.0, strokeWidth / 2.0);

  // Draw Box
  UIBezierPath *boxPath = [UIBezierPath bezierPathWithRoundedRect:insetRect
                                                     cornerRadius:cornerRadius];
  [boxPath setLineWidth:strokeWidth];

  if (isChecked) {
    [[boxColor colorWithAlphaComponent:1.0] setFill];
    [boxPath fill];
    [[boxColor colorWithAlphaComponent:1.0] setStroke];
    [boxPath stroke];

    // Draw Checkmark
    UIBezierPath *checkPath = [UIBezierPath bezierPath];
    CGFloat startX = insetRect.origin.x + insetRect.size.width * 0.25;
    CGFloat startY = insetRect.origin.y + insetRect.size.height * 0.5;
    CGFloat midX = insetRect.origin.x + insetRect.size.width * 0.45;
    CGFloat midY = insetRect.origin.y + insetRect.size.height * 0.65;
    CGFloat endX = insetRect.origin.x + insetRect.size.width * 0.75;
    CGFloat endY = insetRect.origin.y + insetRect.size.height * 0.35;

    [checkPath moveToPoint:CGPointMake(startX, startY)];
    [checkPath addLineToPoint:CGPointMake(midX, midY)];
    [checkPath addLineToPoint:CGPointMake(endX, endY)];

    [checkPath setLineWidth:strokeWidth * 1.5];
    [[UIColor whiteColor] setStroke];
    [checkPath setLineCapStyle:kCGLineCapRound];
    [checkPath setLineJoinStyle:kCGLineJoinRound];
    [checkPath stroke];
  } else {
    [[boxColor colorWithAlphaComponent:1.0] setStroke];
    [boxPath stroke];
  }

  UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return result;
}

@end
