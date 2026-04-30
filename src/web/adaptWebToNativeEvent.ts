import type { NativeMethods, NativeSyntheticEvent } from 'react-native';

// When TipTap events are based on DOM events (e.g., FocusEvent), we adapt them
// to NativeSyntheticEvent where possible.  However, not all TipTap events
// originate from the DOM, so we also support creating NativeSyntheticEvent
// instances from scratch with sensible default values.
export function adaptWebToNativeEvent<T>(
  webEvent: React.SyntheticEvent | Event | null,
  nativeEventPayload: T
): NativeSyntheticEvent<T> {
  let isPropagationStopped = false;
  let isDefaultPrevented = webEvent ? webEvent.defaultPrevented : false;

  return {
    nativeEvent: nativeEventPayload,
    bubbles: webEvent?.bubbles ?? false,
    cancelable: webEvent?.cancelable ?? false,
    currentTarget: (webEvent?.currentTarget ?? {}) as unknown as NativeMethods,
    defaultPrevented: isDefaultPrevented,
    eventPhase: webEvent?.eventPhase ?? 0,
    isTrusted: webEvent?.isTrusted ?? true,
    target: (webEvent?.target ?? {}) as unknown as NativeMethods,
    timeStamp: webEvent?.timeStamp ?? Date.now(),
    type: webEvent?.type ?? 'customEvent',
    preventDefault: () => {
      isDefaultPrevented = true;
      webEvent?.preventDefault();
    },
    isDefaultPrevented: () => isDefaultPrevented,
    stopPropagation: () => {
      isPropagationStopped = true;
      webEvent?.stopPropagation();
    },
    isPropagationStopped: () => isPropagationStopped,
    persist: () => {},
  };
}
