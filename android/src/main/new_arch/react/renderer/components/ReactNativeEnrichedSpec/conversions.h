#pragma once

#include <folly/dynamic.h>
#include <react/renderer/components/ReactNativeEnrichedSpec/Props.h>
#include <react/renderer/core/propsConversions.h>

#if REACT_NATIVE_MINOR_VERSION >= 81
#include <react/renderer/components/FBReactNativeSpec/Props.h>
#else
#include <react/renderer/components/rncore/Props.h>
#endif

namespace facebook::react {

#ifdef RN_SERIALIZABLE_STATE
inline folly::dynamic toDynamic(const EnrichedTextInputViewProps &props) {
  // Serialize only metrics affecting props
  folly::dynamic serializedProps = folly::dynamic::object();
  serializedProps["defaultValue"] = props.defaultValue;
  serializedProps["placeholder"] = props.placeholder;
  serializedProps["fontSize"] = props.fontSize;
  serializedProps["fontWeight"] = props.fontWeight;
  serializedProps["fontStyle"] = props.fontStyle;
  serializedProps["fontFamily"] = props.fontFamily;
  serializedProps["htmlStyle"] = toDynamic(props.htmlStyle);

  return serializedProps;
}
#elif REACT_NATIVE_MINOR_VERSION >= 79
inline folly::dynamic toDynamic(const EnrichedTextInputViewProps &props) {
  folly::dynamic serializedProps = folly::dynamic::object();
  serializedProps["defaultValue"] = props.defaultValue;
  serializedProps["placeholder"] = props.placeholder;
  serializedProps["fontSize"] = props.fontSize;
  serializedProps["fontWeight"] = props.fontWeight;
  serializedProps["fontStyle"] = props.fontStyle;
  serializedProps["fontFamily"] = props.fontFamily;
  // Ideally we should also serialize htmlStyle, but toDynamic function is not
  // generated in this RN version
  // As RN 0.79 and 0.80 is no longer supported, we can skip it for now

  return serializedProps;
}
#endif

} // namespace facebook::react
