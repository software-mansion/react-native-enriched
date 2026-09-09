import { useEffect, useRef } from 'react';
import type { EnrichedTextInputProps } from '../..';
import { LINK_PRESSED_CLASSNAME } from '../constants/classNames';

export function useLinkPress(
  getOnLinkPress: () => EnrichedTextInputProps['onLinkPress']
) {
  const pressedLinkRef = useRef<HTMLElement | null>(null);

  const handleLinkPress = (event: PointerEvent): boolean => {
    if (!getOnLinkPress()) return false;
    const onPress = getOnLinkPress();
    if (!onPress) return false;
    const anchor = (event.target as HTMLElement).closest?.('a');
    if (!anchor) return false;
    const url = anchor.getAttribute('href');
    if (!url) return false;
    event.preventDefault();
    onPress({ url });
    return true;
  };

  const handleLinkMouseDown = (event: MouseEvent): boolean => {
    if (!getOnLinkPress()) return false;
    const anchor = (event.target as HTMLElement).closest?.('a');
    if (!anchor) return false;
    anchor.classList.add(LINK_PRESSED_CLASSNAME);
    pressedLinkRef.current = anchor;
    return false;
  };

  useEffect(() => {
    const clearPressedLink = () => {
      pressedLinkRef.current?.classList.remove(LINK_PRESSED_CLASSNAME);
      pressedLinkRef.current = null;
    };
    document.addEventListener('mouseup', clearPressedLink);
    return () => document.removeEventListener('mouseup', clearPressedLink);
  }, []);

  return { handleLinkPress, handleLinkMouseDown };
}
