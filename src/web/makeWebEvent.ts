import type { NativeSyntheticEvent, TargetedEvent } from 'react-native';
import type { BlurEvent, FocusEvent } from '../types';

export function makeWebEvent<T>(nativeEvent: T): NativeSyntheticEvent<T> {
  return { nativeEvent } as unknown as NativeSyntheticEvent<T>;
}

export function makeFocusEvent(): FocusEvent {
  return makeWebEvent({ target: -1 } as TargetedEvent);
}

export function makeBlurEvent(): BlurEvent {
  return makeWebEvent({ target: -1 } as TargetedEvent);
}
