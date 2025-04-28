#pragma once

#include <folly/dynamic.h>

namespace facebook::react {

    class ReactNativeRichTextEditorViewState {
    public:
        ReactNativeRichTextEditorViewState()
                : text_("") {}

        // Used by Kotlin to set current text value
        ReactNativeRichTextEditorViewState(ReactNativeRichTextEditorViewState const &previousState, folly::dynamic data)
                : text_(data["text"].getString()){};
        folly::dynamic getDynamic() const {
            return {};
        };

        std::string getText() const;

    private:
        const std::string text_{};
    };

} // namespace facebook::react
