#pragma once

#include <react/renderer/components/view/ViewProps.h>
#include <react/renderer/core/PropsParserContext.h>
#include <react/renderer/graphics/Color.h>

namespace facebook::react {

    class EnrichedTextInputProps final : public ViewProps {
    public:
        EnrichedTextInputProps() = default;
        EnrichedTextInputProps(const PropsParserContext& context, const EnrichedTextInputProps &sourceProps, const RawProps &rawProps);

#pragma mark - Props

#ifdef RN_SERIALIZABLE_STATE
        ComponentName getDiffPropsImplementationTarget() const override;
        folly::dynamic getDiffProps(const Props* prevProps) const override;
#endif
    };

} // namespace facebook::react
