import Link from '@tiptap/extension-link';
import type { CommandProps } from '@tiptap/core';

import { isLinkBlocked } from './formatRules';

export const EnrichedLink = Link.extend({
  excludes: 'code',

  addOptions() {
    const parent = this.parent?.()!;
    return {
      ...parent,
      openOnClick: false,
      autolink: false,
      linkOnPaste: false,
      HTMLAttributes: {
        ...parent.HTMLAttributes,
        target: null,
        rel: null,
      },
    };
  },

  addPasteRules() {
    return [];
  },

  addCommands() {
    const parent = this.parent?.();
    return {
      ...parent,
      setLink: (attributes) => (props: CommandProps) => {
        if (isLinkBlocked(props.editor)) {
          return false;
        }
        return parent?.setLink?.(attributes)(props) ?? false;
      },
      toggleLink: (attributes) => (props: CommandProps) => {
        if (isLinkBlocked(props.editor)) {
          return false;
        }
        return parent?.toggleLink?.(attributes)(props) ?? false;
      },
    };
  },
});
