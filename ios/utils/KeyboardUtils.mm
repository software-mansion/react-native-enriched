#import "KeyboardUtils.h"
#import "RCTTextInputUtils.h"

@implementation KeyboardUtils
+ (UIReturnKeyType)getUIReturnKeyTypeFromReturnKeyType:
    (NSString *)returnKeyType {
  if ([returnKeyType isEqualToString:@"done"])
    return UIReturnKeyDone;
  if ([returnKeyType isEqualToString:@"go"])
    return UIReturnKeyGo;
  if ([returnKeyType isEqualToString:@"next"])
    return UIReturnKeyNext;
  if ([returnKeyType isEqualToString:@"search"])
    return UIReturnKeySearch;
  if ([returnKeyType isEqualToString:@"send"])
    return UIReturnKeySend;
  if ([returnKeyType isEqualToString:@"emergency-call"])
    return UIReturnKeyEmergencyCall;
  if ([returnKeyType isEqualToString:@"google"])
    return UIReturnKeyGoogle;
  if ([returnKeyType isEqualToString:@"join"])
    return UIReturnKeyJoin;
  if ([returnKeyType isEqualToString:@"route"])
    return UIReturnKeyRoute;
  if ([returnKeyType isEqualToString:@"yahoo"])
    return UIReturnKeyYahoo;

  return UIReturnKeyDefault;
}

@end
