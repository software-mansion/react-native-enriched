import { useRef, type PointerEvent, type MouseEvent } from 'react';

// Minimum pointer travel before we treat a mouse/pen gesture as a drag-scroll
// instead of a click.
const DRAG_THRESHOLD_PX = 5;

const DRAGGING_CLASS = 'is-drag-scrolling';

/**
 * Enables "grab and drag" horizontal scrolling on an overflow container for
 * mouse and pen input, while leaving touch to the browser's native pan and
 * leaving regular clicks on child elements intact.
 */
export function useDragScroll() {
  const ref = useRef<HTMLDivElement>(null);
  const drag = useRef({
    startX: 0,
    startScrollLeft: 0,
    pointerId: -1,
    active: false,
    suppressNextClick: false,
  });

  const onPointerDown = (e: PointerEvent<HTMLDivElement>) => {
    if (e.pointerType === 'touch') return;
    const el = ref.current;
    if (!el) return;
    drag.current = {
      startX: e.clientX,
      startScrollLeft: el.scrollLeft,
      pointerId: e.pointerId,
      active: false,
      suppressNextClick: false,
    };
  };

  const onPointerMove = (e: PointerEvent<HTMLDivElement>) => {
    const d = drag.current;
    const el = ref.current;
    if (!el || d.pointerId !== e.pointerId) return;

    const deltaX = e.clientX - d.startX;
    if (!d.active) {
      if (Math.abs(deltaX) < DRAG_THRESHOLD_PX) return;
      d.active = true;
      d.suppressNextClick = true;
      el.classList.add(DRAGGING_CLASS);
      try {
        el.setPointerCapture(e.pointerId);
      } catch {
        /* pointer already released */
      }
    }
    el.scrollLeft = d.startScrollLeft - deltaX;
  };

  const end = (e: PointerEvent<HTMLDivElement>) => {
    const d = drag.current;
    const el = ref.current;
    if (d.pointerId !== e.pointerId) return;
    if (d.active && el) {
      el.classList.remove(DRAGGING_CLASS);
      try {
        el.releasePointerCapture(e.pointerId);
      } catch {
        /* already released */
      }
    }
    d.pointerId = -1;
    d.active = false;
    // `suppressNextClick` is consumed by onClickCapture below.
  };

  // Capture-phase click handler: if the user just finished a drag, eat the
  // trailing click before any child can see it.
  const onClickCapture = (e: MouseEvent<HTMLDivElement>) => {
    if (drag.current.suppressNextClick) {
      e.stopPropagation();
      e.preventDefault();
      drag.current.suppressNextClick = false;
    }
  };

  return {
    ref,
    onPointerDown,
    onPointerMove,
    onPointerUp: end,
    onPointerCancel: end,
    onClickCapture,
  };
}
