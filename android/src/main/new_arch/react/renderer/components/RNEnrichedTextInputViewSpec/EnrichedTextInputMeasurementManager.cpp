#include "EnrichedTextInputMeasurementManager.h"

#include <fbjni/fbjni.h>
#include <react/jni/ReadableNativeMap.h>
#include <react/renderer/core/conversions.h>

using namespace facebook::jni;

namespace facebook::react {

    Size EnrichedTextInputMeasurementManager::measure(
            SurfaceId surfaceId,
            int viewTag,
            LayoutConstraints layoutConstraints) const {
        const jni::global_ref<jobject>& fabricUIManager =
                contextContainer_->at<jni::global_ref<jobject>>("FabricUIManager");

        static const auto measure = facebook::jni::findClassStatic(
                "com/facebook/react/fabric/FabricUIManager")
                ->getMethod<jlong(
                        jint,
                        jstring,
                        ReadableMap::javaobject,
                        ReadableMap::javaobject,
                        ReadableMap::javaobject,
                        jfloat,
                        jfloat,
                        jfloat,
                        jfloat)>("measure");

        auto minimumSize = layoutConstraints.minimumSize;
        auto maximumSize = layoutConstraints.maximumSize;

        local_ref<JString> componentName = make_jstring("EnrichedTextInputView");

        folly::dynamic extra = folly::dynamic::object();
        extra["viewTag"] = viewTag;
        local_ref<ReadableNativeMap::javaobject> extraData = ReadableNativeMap::newObjectCxxArgs(extra);
        local_ref<ReadableMap::javaobject> extraDataRM = make_local(reinterpret_cast<ReadableMap::javaobject>(extraData.get()));

        auto measurement = yogaMeassureToSize(measure(
                fabricUIManager,
                surfaceId,
                componentName.get(),
                extraDataRM.get(),
                nullptr,
                nullptr,
                minimumSize.width,
                maximumSize.width,
                minimumSize.height,
                maximumSize.height));

        return measurement;
    }

} // namespace facebook::react
