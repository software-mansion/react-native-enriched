#include "ReactNativeRichTextEditorViewState.h"

namespace facebook::react {
    int ReactNativeRichTextEditorViewState::getForceHeightRecalculationCounter() const {
      return forceHeightRecalculationCounter_;
    }
    std::shared_ptr<void> ReactNativeRichTextEditorViewState::getComponentViewRef() const {
      return componentViewRef_;
    }
} // namespace facebook::react
