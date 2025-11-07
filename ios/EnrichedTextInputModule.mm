//
//  EnrichedTextInputModule.m
//  ReactNativeEnriched
//
//  Created by Ivan Ignathuk on 04/11/2025.
//

#import "EnrichedTextInputModule.h"
#import "EnrichedTextInputView.h"

static UIView *findViewByReactTag(NSInteger reactTag, RCTBridge *bridge) {
  if (bridge.uiManager) {
    UIView *view = [bridge.uiManager viewForReactTag:@(reactTag)];
    if (view) {
      return view;
    }
  }

  return nil;
}

@implementation EnrichedTextInputModule

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeEnrichedTextInputModuleSpecJSI>(params);
}

- (nonnull NSString *)getHTMLValue:(NSInteger)inputTag {
  __block NSString *value = @"";

  dispatch_sync(dispatch_get_main_queue(), ^{
      UIView *view = findViewByReactTag(inputTag, self.bridge);
      if ([view isKindOfClass:[EnrichedTextInputView class]]) {
        EnrichedTextInputView *enrichedTextView = (EnrichedTextInputView *)view;
        value = [enrichedTextView getHTMLValue];
      }
    });

  return value;
}

+ (NSString *)moduleName { 
  return @"EnrichedTextInputModule";
}

@end
