#pragma once

#include <folly/dynamic.h>

namespace facebook::react {

    class ReactNativeRichTextEditorViewState {
    public:
        ReactNativeRichTextEditorViewState()
                : forceHeightRecalculationCounter_(0) {}

        // Used by Kotlin to set current text value
        ReactNativeRichTextEditorViewState(ReactNativeRichTextEditorViewState const &previousState, folly::dynamic data)
                : forceHeightRecalculationCounter_((int)data["forceHeightRecalculationCounter"].getInt()){};
        folly::dynamic getDynamic() const {
            return {};
        };

        int getForceHeightRecalculationCounter() const;

    private:
        const int forceHeightRecalculationCounter_{};
    };

} // namespace facebook::react
