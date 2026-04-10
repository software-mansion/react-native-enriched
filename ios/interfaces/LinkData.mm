#import "LinkData.h"

@implementation LinkData

- (id)copyWithZone:(NSZone *)zone {
  LinkData *copy = [[[self class] allocWithZone:zone] init];
  if (copy) {
    copy.text = [self.text copyWithZone:zone];
    copy.url = [self.url copyWithZone:zone];
    copy.isManual = self.isManual;
  }
  return copy;
}

- (BOOL)isEqualToLinkData:(LinkData *)linkData {
  if (!linkData) {
    return NO;
  }

  BOOL equalText = (!self.text && !linkData.text) ||
                   [self.text isEqualToString:linkData.text];
  BOOL equalUrl =
      (!self.url && !linkData.url) || [self.url isEqualToString:linkData.url];
  BOOL equalIsManual = (self.isManual == linkData.isManual);

  return equalText && equalUrl && equalIsManual;
}

@end
