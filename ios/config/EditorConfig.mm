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
  if(![newValue isEqual:_primaryColor]) {
    _primaryColor = newValue;
  }
}

- (NSNumber *)primaryFontSize {
  return _primaryFontSize;
}

- (void)setPrimaryFontSize:(NSNumber *)newValue {
  if(![_primaryFontSize isEqualToNumber:newValue]) {
    _primaryFontSize = newValue;
    _primaryFontNeedsRecreation = YES;
    _monospacedFontNeedsRecreation = YES;
  }
}

- (NSString *)primaryFontWeight {
  return _primaryFontWeight;
}

- (void)setPrimaryFontWeight:(NSString *)newValue {
  if(![_primaryFontWeight isEqualToString:newValue]) {
    _primaryFontWeight = newValue;
    _primaryFontNeedsRecreation = YES;
    _monospacedFontNeedsRecreation = YES;
  }
}

- (NSString *)primaryFontFamily {
  return _primaryFontFamily;
}

- (void)setPrimaryFontFamily:(NSString *)newValue {
  if(![_primaryFontFamily isEqualToString:newValue]) {
    _primaryFontFamily = newValue;
    _primaryFontNeedsRecreation = YES;
  }
}

- (UIFont *)primaryFont {
  if(_primaryFontNeedsRecreation) {
    _primaryFontNeedsRecreation = NO;
    _primaryFont = [RCTFont updateFont:nullptr
      withFamily:[self primaryFontFamily]
      size:[self primaryFontSize]
      weight:[self primaryFontWeight]
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
