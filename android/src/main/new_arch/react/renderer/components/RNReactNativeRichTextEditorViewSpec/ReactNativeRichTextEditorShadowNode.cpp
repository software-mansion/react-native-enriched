#include "ReactNativeRichTextEditorShadowNode.h"

#include <react/renderer/core/LayoutContext.h>

namespace facebook::react {
extern const char ReactNativeRichTextEditorComponentName[] = "ReactNativeRichTextEditorView";
    void ReactNativeRichTextEditorShadowNode::setMeasurementsManager(
            const std::shared_ptr<RichTextEditorMeasurementManager>&
            measurementsManager) {
        ensureUnsealed();
        measurementsManager_ = measurementsManager;
    }

    void ReactNativeRichTextEditorShadowNode::updateYogaPropsIfNeeded(const std::string text) {
        if (text_ != text) {
            text_ = text;

            dirtyLayout();
            updateYogaProps();
        }
    }

    Size ReactNativeRichTextEditorShadowNode::measureContent(
            const LayoutContext &layoutContext,
            const LayoutConstraints &layoutConstraints) const {

        return measurementsManager_->measure(getSurfaceId(), getConcreteProps(), layoutConstraints);
    }

} // namespace facebook::react
