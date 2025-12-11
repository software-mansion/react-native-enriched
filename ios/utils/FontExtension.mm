#import "FontExtension.h"
#import <React/RCTLog.h>

@implementation UIFont (FontExtension)

- (BOOL)isBold {
  return (self.fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold) ==
         UIFontDescriptorTraitBold;
}

- (UIFont *)setBold {
  if ([self isBold]) {
    return self;
  }
  UIFontDescriptorSymbolicTraits newTraits =
      (self.fontDescriptor.symbolicTraits | UIFontDescriptorTraitBold);
  UIFontDescriptor *fontDescriptor =
      [self.fontDescriptor fontDescriptorWithSymbolicTraits:newTraits];
  if (fontDescriptor != nullptr) {
    return [UIFont fontWithDescriptor:fontDescriptor size:0];
  } else {
    RCTLogWarn(@"[EnrichedTextInput]: Couldn't apply bold trait to the font.");
    return self;
  }
}

- (UIFont *)removeBold {
  if (![self isBold]) {
    return self;
  }
  UIFontDescriptorSymbolicTraits newTraits =
      (self.fontDescriptor.symbolicTraits ^ UIFontDescriptorTraitBold);
  UIFontDescriptor *fontDescriptor =
      [self.fontDescriptor fontDescriptorWithSymbolicTraits:newTraits];
  if (fontDescriptor != nullptr) {
    return [UIFont fontWithDescriptor:fontDescriptor size:0];
  } else {
    RCTLogWarn(
        @"[EnrichedTextInput]: Couldn't remove bold trait from the font.");
    return self;
  }
}

- (BOOL)isItalic {
  return (self.fontDescriptor.symbolicTraits & UIFontDescriptorTraitItalic) ==
         UIFontDescriptorTraitItalic;
}

- (UIFont *)setItalic {
  if ([self isItalic]) {
    return self;
  }
  UIFontDescriptorSymbolicTraits newTraits =
      (self.fontDescriptor.symbolicTraits | UIFontDescriptorTraitItalic);
  UIFontDescriptor *fontDescriptor =
      [self.fontDescriptor fontDescriptorWithSymbolicTraits:newTraits];
  if (fontDescriptor != nullptr) {
    return [UIFont fontWithDescriptor:fontDescriptor size:0];
  } else {
    RCTLogWarn(
        @"[EnrichedTextInput]: Couldn't apply italic trait to the font.");
    return self;
  }
}

- (UIFont *)removeItalic {
  if (![self isItalic]) {
    return self;
  }
  UIFontDescriptorSymbolicTraits newTraits =
      (self.fontDescriptor.symbolicTraits ^ UIFontDescriptorTraitItalic);
  UIFontDescriptor *fontDescriptor =
      [self.fontDescriptor fontDescriptorWithSymbolicTraits:newTraits];
  if (fontDescriptor != nullptr) {
    return [UIFont fontWithDescriptor:fontDescriptor size:0];
  } else {
    RCTLogWarn(
        @"[EnrichedTextInput]: Couldn't remove italic trait from the font.");
    return self;
  }
}

- (UIFont *)withFontTraits:(UIFont *)from {
  UIFont *newFont = self;
  if ([from isBold]) {
    newFont = [newFont setBold];
  }
  if ([from isItalic]) {
    newFont = [newFont setItalic];
  }
  return newFont;
}

- (UIFont *)setSize:(CGFloat)size {
  UIFontDescriptor *newFontDescriptor =
      [self.fontDescriptor fontDescriptorWithSize:size];
  if (newFontDescriptor != nullptr) {
    return [UIFont fontWithDescriptor:newFontDescriptor size:0];
  } else {
    RCTLogWarn(
        @"[EnrichedTextInput]: Couldn't apply heading style to the font.");
    return self;
  }
}

@end
