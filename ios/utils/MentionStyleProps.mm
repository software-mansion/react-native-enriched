#import "MentionStyleProps.h"
#import <React/RCTConversions.h>
#import "StringExtension.h"

@implementation MentionStyleProps

+ (MentionStyleProps *)getSingleMentionStylePropsFromFollyDynamic:(folly::dynamic)folly {
  facebook::react::SharedColor color = facebook::react::SharedColor(facebook::react::Color(folly["color"].asInt()));
  facebook::react::SharedColor bgColor = facebook::react::SharedColor(facebook::react::Color(folly["backgroundColor"].asInt()));
  std::string textDecorationLine = folly["textDecorationLine"].asString();
  
  MentionStyleProps *nativeProps = [[MentionStyleProps alloc] init];
  nativeProps.color = RCTUIColorFromSharedColor(color);
  nativeProps.backgroundColor = RCTUIColorFromSharedColor(bgColor);
  nativeProps.decorationLine = [[NSString fromCppString:textDecorationLine] isEqualToString:DecorationUnderline] ? DecorationUnderline : DecorationNone;
  
  return nativeProps;
}

+ (NSDictionary *)getSinglePropsFromFollyDynamic:(folly::dynamic)folly {
  MentionStyleProps *nativeProps = [MentionStyleProps getSingleMentionStylePropsFromFollyDynamic:folly];
  // the single props need to be somehow distinguishable in config
  NSDictionary *dict = @{@"all": nativeProps};
  return dict;
}

+ (NSDictionary *)getComplexPropsFromFollyDynamic:(folly::dynamic)folly {
  NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
  
  for(const auto& obj: folly.items()) {
    if(obj.first.isString() && obj.second.isObject()) {
      std::string key = obj.first.asString();
      MentionStyleProps *props = [MentionStyleProps getSingleMentionStylePropsFromFollyDynamic:obj.second];
      dict[[NSString fromCppString:key]] = props;
    }
  }
  
  return dict;
}

@end

