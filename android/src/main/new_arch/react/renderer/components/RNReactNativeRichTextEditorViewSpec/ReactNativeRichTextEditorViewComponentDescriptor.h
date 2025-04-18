#pragma once

#include <react/renderer/components/RNReactNativeRichTextEditorViewSpec/ReactNativeRichTextEditorShadowNode.h>
#include <react/debug/react_native_assert.h>
#include <react/renderer/core/ConcreteComponentDescriptor.h>

namespace facebook::react {

class ReactNativeRichTextEditorViewComponentDescriptor final
    : public ConcreteComponentDescriptor<ReactNativeRichTextEditorShadowNode> {
public:
  using ConcreteComponentDescriptor::ConcreteComponentDescriptor;
};

} // namespace facebook::react

