#pragma once

#include <react/renderer/components/RNReactNativeRichTextEditorViewSpec/ReactNativeRichTextEditorShadowNode.h>
#include <react/debug/react_native_assert.h>
#include <react/renderer/core/ConcreteComponentDescriptor.h>

namespace facebook::react {

class ReactNativeRichTextEditorViewComponentDescriptor final
    : public ConcreteComponentDescriptor<ReactNativeRichTextEditorShadowNode> {
public:
    using ConcreteComponentDescriptor::ConcreteComponentDescriptor;

  void adopt(ShadowNode &shadowNode) const override {
    react_native_assert(dynamic_cast<ReactNativeRichTextEditorShadowNode *>(&shadowNode));

    const auto reactNativeRichTextEditorShadowNode = dynamic_cast<ReactNativeRichTextEditorShadowNode *>(&shadowNode);
    const auto state = reactNativeRichTextEditorShadowNode->getStateData();

    reactNativeRichTextEditorShadowNode->setSize({state.getWidth(), state.getHeight()});

    ConcreteComponentDescriptor::adopt(shadowNode);
  }
};

} // namespace facebook::react

