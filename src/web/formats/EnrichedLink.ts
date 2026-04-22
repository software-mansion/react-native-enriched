import Link from '@tiptap/extension-link';
import type { CommandProps } from '@tiptap/core';
import type { Editor } from '@tiptap/react';

import { nativePosToTiptapPos } from '../positionMapping';
import { isLinkBlocked } from './formatRules';

export const EnrichedLink = Link.extend({
  excludes: 'code',

  renderHTML({ HTMLAttributes }) {
    return ['a', { href: HTMLAttributes.href }, 0];
  },

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

  addKeyboardShortcuts() {
    return {};
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
      unsetLink: () => (props: CommandProps) => {
        if (isLinkBlocked(props.editor)) {
          return false;
        }
        return parent?.unsetLink?.()(props) ?? false;
      },
    };
  },
});

export function setLink(
  editor: Editor,
  start: number,
  end: number,
  text: string,
  url: string
) {
  if (url.length === 0 || text.length === 0) {
    return;
  }
  if (isLinkBlocked(editor)) {
    return;
  }
  const { state } = editor;
  const doc = state.doc;
  const from = nativePosToTiptapPos(doc, start);
  const to = nativePosToTiptapPos(doc, end);
  const linkType = state.schema.marks.link;
  if (!linkType) return;
  const linkMark = linkType.create({ href: url });
  editor
    .chain()
    .focus()
    .command(({ tr, state: s }) => {
      const marksAtRangeStart = doc.resolve(from).marks();
      const marksWithLink = linkMark.addToSet(marksAtRangeStart);
      tr.delete(from, to);
      tr.insert(from, s.schema.text(text, marksWithLink));
      return true;
    })
    .run();
}

export function removeLink(editor: Editor, start: number, end: number) {
  const doc = editor.state.doc;
  const from = nativePosToTiptapPos(doc, start);
  const to = nativePosToTiptapPos(doc, end);
  editor.chain().focus().setTextSelection({ from, to }).unsetLink().run();
}
