#include <react/renderer/graphics/Size.h>

namespace facebook::react {

class EnrichedTextInputViewState {
public:
  EnrichedTextInputViewState() = default;

  explicit EnrichedTextInputViewState(Size contentSize)
      : contentSize_(contentSize) {}

  const Size &getContentSize() const { return contentSize_; }

private:
  Size contentSize_{};
};

} // namespace facebook::react
