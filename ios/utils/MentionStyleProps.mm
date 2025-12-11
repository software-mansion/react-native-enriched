#import "MentionStyleProps.h"
#import "StringExtension.h"
#import <React/RCTConversions.h>

@implementation MentionStyleProps

+ (MentionStyleProps *)getSingleMentionStylePropsFromFollyDynamic:
    (folly::dynamic)folly {
  MentionStyleProps *nativeProps = [[MentionStyleProps alloc] init];

  if (folly["color"].isNumber()) {
    facebook::react::SharedColor color = facebook::react::SharedColor(
        facebook::react::Color(folly["color"].asInt()));
    nativeProps.color = RCTUIColorFromSharedColor(color);
  } else {
    nativeProps.color = [UIColor blueColor];
  }

  if (folly["backgroundColor"].isNumber()) {
    facebook::react::SharedColor bgColor = facebook::react::SharedColor(
        facebook::react::Color(folly["backgroundColor"].asInt()));
    nativeProps.backgroundColor = RCTUIColorFromSharedColor(bgColor);
  } else {
    nativeProps.backgroundColor = [UIColor yellowColor];
  }

  if (folly["textDecorationLine"].isString()) {
    std::string textDecorationLine = folly["textDecorationLine"].asString();
    nativeProps.decorationLine = [[NSString fromCppString:textDecorationLine]
                                     isEqualToString:DecorationUnderline]
                                     ? DecorationUnderline
                                     : DecorationNone;
  } else {
    nativeProps.decorationLine = DecorationUnderline;
  }

  return nativeProps;
}

+ (NSDictionary *)getSinglePropsFromFollyDynamic:(folly::dynamic)folly {
  MentionStyleProps *nativeProps =
      [MentionStyleProps getSingleMentionStylePropsFromFollyDynamic:folly];
  // the single props need to be somehow distinguishable in config
  NSDictionary *dict = @{@"all" : nativeProps};
  return dict;
}

+ (NSDictionary *)getComplexPropsFromFollyDynamic:(folly::dynamic)folly {
  NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

  for (const auto &obj : folly.items()) {
    if (obj.first.isString() && obj.second.isObject()) {
      std::string key = obj.first.asString();
      MentionStyleProps *props = [MentionStyleProps
          getSingleMentionStylePropsFromFollyDynamic:obj.second];
      dict[[NSString fromCppString:key]] = props;
    }
  }

  return dict;
}

@end
