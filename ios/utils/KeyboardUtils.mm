#import "KeyboardUtils.h"
#import "RCTTextInputUtils.h"

@implementation KeyboardUtils
+ (UIReturnKeyType)getUIReturnKeyTypeFromReturnKeyType:
    (NSString *)returnKeyType {
  NSMutableDictionary *uiReturnKeyTypes = [NSMutableDictionary dictionary];

  uiReturnKeyTypes[@"done"] = @(UIReturnKeyDone);
  uiReturnKeyTypes[@"go"] = @(UIReturnKeyGo);
  uiReturnKeyTypes[@"next"] = @(UIReturnKeyNext);
  uiReturnKeyTypes[@"search"] = @(UIReturnKeySearch);
  uiReturnKeyTypes[@"send"] = @(UIReturnKeySend);
  uiReturnKeyTypes[@"default"] = @(UIReturnKeyDefault);
  uiReturnKeyTypes[@"none"] = @(UIReturnKeyDefault);
  uiReturnKeyTypes[@"previous"] = @(UIReturnKeyDefault);
  uiReturnKeyTypes[@"emergency-call"] = @(UIReturnKeyEmergencyCall);
  uiReturnKeyTypes[@"google"] = @(UIReturnKeyGoogle);
  uiReturnKeyTypes[@"join"] = @(UIReturnKeyJoin);
  uiReturnKeyTypes[@"route"] = @(UIReturnKeyRoute);
  uiReturnKeyTypes[@"yahoo"] = @(UIReturnKeyYahoo);

  id value = uiReturnKeyTypes[returnKeyType];

  if (value) {
    UIReturnKeyType returnKey = (UIReturnKeyType)[value integerValue];

    return returnKey;
  }

  return UIReturnKeyDefault;
}

@end
