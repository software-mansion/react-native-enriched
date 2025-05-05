#pragma once
#include <react/debug/react_native_assert.h>
#include <ReactNativeRichTextEditor/Props.h>
#include <react/renderer/core/ConcreteComponentDescriptor.h>
#include <ReactNativeRichTextEditor/ReactNativeRichTextEditorViewShadowNode.h>

// to be deleted
#include <iostream>

namespace facebook::react {
class ReactNativeRichTextEditorViewComponentDescriptor final : public ConcreteComponentDescriptor<ReactNativeRichTextEditorViewShadowNode> {
  public:
    using ConcreteComponentDescriptor::ConcreteComponentDescriptor;
    void adopt(ShadowNode &shadowNode) const override {
      react_native_assert(dynamic_cast<ReactNativeRichTextEditorViewShadowNode *>(&shadowNode));
      ConcreteComponentDescriptor::adopt(shadowNode);
    }
};

} // namespace facebook::react
