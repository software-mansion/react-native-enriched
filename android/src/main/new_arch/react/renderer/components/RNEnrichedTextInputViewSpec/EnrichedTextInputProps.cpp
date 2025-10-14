#include "EnrichedTextInputProps.h"
#include <react/renderer/core/PropsParserContext.h>
#include <react/renderer/core/propsConversions.h>

namespace facebook::react {

    EnrichedTextInputProps::EnrichedTextInputProps(
            const PropsParserContext &context,
            const EnrichedTextInputProps &sourceProps,
            const RawProps &rawProps): ViewProps(context, sourceProps, rawProps) {}

#ifdef RN_SERIALIZABLE_STATE
    ComponentName EnrichedTextInputProps::getDiffPropsImplementationTarget() const {
  return "EnrichedTextInputView";
}

folly::dynamic EnrichedTextInputProps::getDiffProps(
    const Props* prevProps) const {
  static const auto defaultProps = EnrichedTextInputProps();
  const EnrichedTextInputProps* oldProps = prevProps == nullptr
      ? &defaultProps
      : static_cast<const EnrichedTextInputProps*>(prevProps);
  if (this == oldProps) {
    return folly::dynamic::object();
  }
  folly::dynamic result = HostPlatformViewProps::getDiffProps(prevProps);
  return result;
}
#endif

} // namespace facebook::react
