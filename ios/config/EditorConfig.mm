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
  UIColor *_inlineCodeFgColor;
  UIColor *_inlineCodeBgColor;
  NSSet<NSNumber*> *_mentionIndicators;
}

- (instancetype) init {
  self = [super init];
  _primaryFontNeedsRecreation = YES;
  _monospacedFontNeedsRecreation = YES;
  return self;
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

- (NSSet<NSNumber*>*)mentionIndicators {
  return _mentionIndicators != nullptr ? _mentionIndicators : [[NSSet alloc] init];
}

- (void)setMentionIndicators:(NSSet<NSNumber*>*)newValue {
  _mentionIndicators = newValue;
}

@end
