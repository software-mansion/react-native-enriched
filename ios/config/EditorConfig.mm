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
  UIColor *_inlineCodeFgColor;
  UIColor *_inlineCodeBgColor;
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

- (UIColor *)inlineCodeFgColor {
  return _inlineCodeFgColor != nullptr ? _inlineCodeFgColor : [UIColor orangeColor];
}

- (void)setInlineCodeFgColor:(UIColor *)newValue {
  if(![newValue isEqual:_inlineCodeFgColor]) {
    _inlineCodeFgColor = newValue;
  }
}

- (UIColor *)inlineCodeBgColor {
  return _inlineCodeBgColor != nullptr ? _inlineCodeBgColor : [[UIColor systemGrayColor] colorWithAlphaComponent:0.6];
}

- (void)setInlineCodeBgColor:(UIColor *)newValue {
  if(![newValue isEqual:_inlineCodeBgColor]) {
    _inlineCodeBgColor = newValue;
  }
}

@end
