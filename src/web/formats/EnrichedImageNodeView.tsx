import { NodeViewWrapper, type ReactNodeViewProps } from '@tiptap/react';
import type { CSSProperties } from 'react';
import { useState } from 'react';

const IMAGE_FALLBACK_SIZE = 80;

const BROKEN_IMAGE_PATH_D =
  'M200,840Q167,840 143.5,816.5Q120,793 120,760L120,200Q120,167 143.5,143.5Q167,120 200,120L760,120Q793,120 816.5,143.5Q840,167 840,200L840,760Q840,793 816.5,816.5Q793,840 760,840L200,840ZM240,503L400,343L560,503L720,343L760,383L760,200Q760,200 760,200Q760,200 760,200L200,200Q200,200 200,200Q200,200 200,200L200,463L240,503ZM200,760L760,760Q760,760 760,760Q760,760 760,760L760,496L720,456L560,616L400,456L240,616L200,576L200,760Q200,760 200,760Q200,760 200,760ZM200,760L200,760Q200,760 200,760Q200,760 200,760L200,496L200,576L200,463L200,383L200,200Q200,200 200,200Q200,200 200,200L200,200Q200,200 200,200Q200,200 200,200L200,463L200,463L200,576L200,576L200,760Q200,760 200,760Q200,760 200,760Z';

function BrokenImageGlyph() {
  return (
    <svg
      viewBox="0 0 960 960"
      width="100%"
      height="100%"
      preserveAspectRatio="none"
      aria-hidden
      focusable="false"
      className="eti-inline-image-broken-glyph"
    >
      <path fill="currentColor" d={BROKEN_IMAGE_PATH_D} />
    </svg>
  );
}

function dim(value: unknown): number | undefined {
  if (value == null) return undefined;
  if (typeof value === 'number' && !Number.isNaN(value)) return value;
  const n = parseFloat(String(value));
  return Number.isNaN(n) ? undefined : n;
}

export function EnrichedImageNodeView({ node }: ReactNodeViewProps) {
  const src = ((node.attrs.src as string | null | undefined) ?? '').trim();
  const rawW = dim(node.attrs.width);
  const rawH = dim(node.attrs.height);
  const [errored, setErrored] = useState(false);
  const showPlaceholder = src.length === 0 || errored;

  const placeholderW = rawW ?? IMAGE_FALLBACK_SIZE;
  const placeholderH = rawH ?? IMAGE_FALLBACK_SIZE;

  const sizeStyle: CSSProperties = {
    width: placeholderW,
    height: placeholderH,
  };

  if (showPlaceholder) {
    return (
      <NodeViewWrapper
        as="span"
        className="eti-inline-image eti-inline-image--placeholder"
        style={sizeStyle}
        data-eti-image-placeholder=""
      >
        <BrokenImageGlyph />
      </NodeViewWrapper>
    );
  }

  let imgDims: { width?: number; height?: number };
  let imgStyle: CSSProperties | undefined;

  if (rawW != null && rawH != null) {
    imgDims = { width: rawW, height: rawH };
    imgStyle = undefined;
  } else if (rawH != null) {
    imgDims = { height: rawH };
    imgStyle = { width: 'auto' };
  } else {
    imgDims = { width: rawW ?? IMAGE_FALLBACK_SIZE };
    imgStyle = { height: 'auto' };
  }

  return (
    <NodeViewWrapper as="span" className="eti-inline-image">
      <img
        {...imgDims}
        src={src}
        alt=""
        className="eti-inline-image-img"
        style={imgStyle}
        contentEditable={false}
        draggable={false}
        onError={() => setErrored(true)}
      />
    </NodeViewWrapper>
  );
}
