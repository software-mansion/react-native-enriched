#import <EditorConfig.h>
#import <React/RCTFont.h>

@implementation EditorConfig {
  UIColor *_primaryColor;
  NSNumber *_primaryFontSize;
  NSString *_primaryFontWeight;
  NSString *_primaryFontFamily;
  UIFont *_primaryFont;
  BOOL fontNeedsRecreation;
}

- (instancetype) init {
  self = [super init];
  fontNeedsRecreation = YES;
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
    fontNeedsRecreation = YES;
  }
}

- (NSString *)primaryFontWeight {
  return _primaryFontWeight;
}

- (void)setPrimaryFontWeight:(NSString *)newValue {
  if(![_primaryFontWeight isEqualToString:newValue]) {
    _primaryFontWeight = newValue;
    fontNeedsRecreation = YES;
  }
}

- (NSString *)primaryFontFamily {
  return _primaryFontFamily;
}

- (void)setPrimaryFontFamily:(NSString *)newValue {
  if(![_primaryFontFamily isEqualToString:newValue]) {
    _primaryFontFamily = newValue;
    fontNeedsRecreation = YES;
  }
}

- (UIFont *)primaryFont {
  if(fontNeedsRecreation) {
    fontNeedsRecreation = NO;
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

@end
