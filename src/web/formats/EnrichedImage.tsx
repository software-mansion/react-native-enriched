import type { CommandProps } from '@tiptap/core';
import Image from '@tiptap/extension-image';
import {
  NodeViewWrapper,
  ReactNodeViewRenderer,
  type ReactNodeViewProps,
} from '@tiptap/react';
import type { CSSProperties } from 'react';
import { useState } from 'react';

import { isImageBlocked } from './formatRules';

const INLINE_IMAGE_FALLBACK_SIZE = 80;

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

function EnrichedImageNodeView({ node }: ReactNodeViewProps) {
  const src = ((node.attrs.src as string | null | undefined) ?? '').trim();
  const w = dim(node.attrs.width) ?? INLINE_IMAGE_FALLBACK_SIZE;
  const h = dim(node.attrs.height) ?? INLINE_IMAGE_FALLBACK_SIZE;
  const [errored, setErrored] = useState(false);
  const showPlaceholder = src.length === 0 || errored;

  const sizeStyle: CSSProperties = {
    width: w,
    height: h,
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

  return (
    <NodeViewWrapper as="span" className="eti-inline-image">
      <img
        src={src}
        width={w}
        height={h}
        alt=""
        className="eti-inline-image-img"
        contentEditable={false}
        draggable={false}
        onError={() => setErrored(true)}
      />
    </NodeViewWrapper>
  );
}

export const EnrichedImage = Image.extend({
  addOptions() {
    const parent = this.parent?.();
    return {
      ...parent,
      inline: true,
      allowBase64: false,
      resize: false,
      HTMLAttributes: parent?.HTMLAttributes ?? {},
    };
  },

  renderHTML({ node }) {
    return [
      'img',
      {
        width: node.attrs.width,
        height: node.attrs.height,
        src: node.attrs.src,
      },
    ];
  },

  addNodeView() {
    return ReactNodeViewRenderer(EnrichedImageNodeView, { as: 'span' });
  },

  addInputRules() {
    return [];
  },

  addCommands() {
    return {
      ...this.parent?.(),
      setImage:
        (options: { src: string; width?: number; height?: number }) =>
        ({ editor, commands }: CommandProps) => {
          if (isImageBlocked(editor)) {
            return false;
          }
          return commands.insertContent({
            type: this.name,
            attrs: {
              src: options.src,
              width: options.width ?? null,
              height: options.height ?? null,
            },
          });
        },
    };
  },
});
