#import "FontUtils.h"
#import <React/RCTLog.h>

@implementation UIFont (FontUtils)

- (BOOL)isBold {
  return (self.fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold) == UIFontDescriptorTraitBold;
}

- (UIFont *)setBold {
  if([self isBold]) {
    return self;
  }
  UIFontDescriptorSymbolicTraits newTraits = (self.fontDescriptor.symbolicTraits | UIFontDescriptorTraitBold);
  UIFontDescriptor *fontDescriptor = [self.fontDescriptor fontDescriptorWithSymbolicTraits:newTraits];
  if(fontDescriptor != nullptr) {
    return [UIFont fontWithDescriptor:fontDescriptor size:0];
  } else {
    RCTLogWarn(@"[RichTextEditor]: Couldn't apply bold trait to the font.");
    return self;
  }
}

- (UIFont *)removeBold {
  if(![self isBold]) {
    return self;
  }
  UIFontDescriptorSymbolicTraits newTraits = (self.fontDescriptor.symbolicTraits ^ UIFontDescriptorTraitBold);
  UIFontDescriptor *fontDescriptor = [self.fontDescriptor fontDescriptorWithSymbolicTraits:newTraits];
  if(fontDescriptor != nullptr) {
    return [UIFont fontWithDescriptor:fontDescriptor size:0];
  } else {
    RCTLogWarn(@"[RichTextEditor]: Couldn't remove bold trait from the font.");
    return self;
  }
}

- (BOOL)isItalic {
  return (self.fontDescriptor.symbolicTraits & UIFontDescriptorTraitItalic) == UIFontDescriptorTraitItalic;
}

- (UIFont *)setItalic {
  if([self isItalic]) {
    return self;
  }
  UIFontDescriptorSymbolicTraits newTraits = (self.fontDescriptor.symbolicTraits | UIFontDescriptorTraitItalic);
  UIFontDescriptor *fontDescriptor = [self.fontDescriptor fontDescriptorWithSymbolicTraits:newTraits];
  if(fontDescriptor != nullptr) {
    return [UIFont fontWithDescriptor:fontDescriptor size:0];
  } else {
    RCTLogWarn(@"[RichTextEditor]: Couldn't apply italic trait to the font.");
    return self;
  }
}

- (UIFont *)removeItalic {
  if(![self isItalic]) {
    return self;
  }
  UIFontDescriptorSymbolicTraits newTraits = (self.fontDescriptor.symbolicTraits ^ UIFontDescriptorTraitItalic);
  UIFontDescriptor *fontDescriptor = [self.fontDescriptor fontDescriptorWithSymbolicTraits:newTraits];
  if(fontDescriptor != nullptr) {
    return [UIFont fontWithDescriptor:fontDescriptor size:0];
  } else {
    RCTLogWarn(@"[RichTextEditor]: Couldn't remove italic trait from the font.");
    return self;
  }
}

- (BOOL)isMonospace:(EditorConfig *)withConfig {
  return self.familyName == withConfig.monospacedFont.familyName;
}

- (UIFont *)withFontTraits:(UIFont *)from {
  UIFont* newFont = self;
  if([from isBold]) {
    newFont = [newFont setBold];
  }
  if([from isItalic]) {
    newFont = [newFont setItalic];
  }
  return newFont;
}

@end
