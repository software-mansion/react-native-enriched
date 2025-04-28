#pragma once

#include <folly/dynamic.h>

namespace facebook::react {

    class ReactNativeRichTextEditorViewState {
    public:
        ReactNativeRichTextEditorViewState()
                : nativeEventCounter_(0) {}

        // Used by Kotlin to set current text value
        ReactNativeRichTextEditorViewState(ReactNativeRichTextEditorViewState const &previousState, folly::dynamic data)
                : nativeEventCounter_((int)data["nativeEventCounter"].getInt()){};
        folly::dynamic getDynamic() const {
            return {};
        };

        int getNativeEventCounter() const;

    private:
        const int nativeEventCounter_{};
    };

} // namespace facebook::react
