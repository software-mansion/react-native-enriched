import type { CommandProps } from '@tiptap/core';
import Image from '@tiptap/extension-image';
import { ReactNodeViewRenderer } from '@tiptap/react';

import { EnrichedImageNodeView } from './EnrichedImageNodeView';
import { isImageBlocked } from './formatRules';

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
        src: node.attrs.src,
        width: node.attrs.width,
        height: node.attrs.height,
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
