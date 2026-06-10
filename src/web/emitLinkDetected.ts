import type { RefObject } from 'react';
import type { OnLinkDetected } from '../types';

export interface LinkEmitterState {
  linkRegex?: RegExp | null;
  onLinkDetected?: (e: OnLinkDetected) => void;
  lastEmitted: OnLinkDetected | null;
}

export type LinkEmitterRef = RefObject<LinkEmitterState>;

function isSamePayload(a: OnLinkDetected, b: OnLinkDetected): boolean {
  return (
    a.text === b.text &&
    a.url === b.url &&
    a.start === b.start &&
    a.end === b.end
  );
}

export function emitLinkDetected(
  state: LinkEmitterState,
  next: OnLinkDetected
): void {
  const prev = state.lastEmitted;
  if (prev && isSamePayload(prev, next)) return;
  state.lastEmitted = next;
  state.onLinkDetected?.(next);
}
