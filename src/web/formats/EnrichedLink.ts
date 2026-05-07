import Link from '@tiptap/extension-link';
import type { CommandProps } from '@tiptap/core';
import type { Editor } from '@tiptap/react';

import { nativePosToTiptapPos } from '../positionMapping';
import { isLinkBlocked } from './formatRules';

export const EnrichedLink = Link.extend({
  excludes: 'link code',

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

export function removeLink(editor: Editor, start: number, end: number) {
  const { doc, selection: selectionBefore } = editor.state;
  const from = nativePosToTiptapPos(doc, start);
  const to = nativePosToTiptapPos(doc, end);
  editor
    .chain()
    .focus()
    .setTextSelection({ from, to })
    .unsetLink()
    .command(({ tr }) => {
      const mapped = selectionBefore.map(tr.doc, tr.mapping);
      if (mapped) {
        tr.setSelection(mapped);
      }
      return true;
    })
    .run();
}

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
  const { state } = editor;
  const doc = state.doc;
  const from = nativePosToTiptapPos(doc, start);
  const to = nativePosToTiptapPos(doc, end);

  if (isRangeLinkBlocked(editor, from, to)) {
    return;
  }

  const linkType = state.schema.marks.link;
  if (!linkType) return;
  const linkMark = linkType.create({ href: url });
  editor
    .chain()
    .focus()
    .command(({ tr, state: s }) => {
      if (from === to) {
        const marksAtRangeStart = doc.resolve(from).marks();
        const marksWithLink = linkMark.addToSet(marksAtRangeStart);
        tr.insert(from, s.schema.text(text, marksWithLink));
      } else {
        const currentText = doc.textBetween(from, to);

        if (text !== currentText) {
          const marksAtRangeStart = doc.resolve(from).marks();
          const marksWithLink = linkMark.addToSet(marksAtRangeStart);
          tr.replaceWith(from, to, s.schema.text(text, marksWithLink));
        } else {
          tr.addMark(from, to, linkMark);
        }
      }
      return true;
    })
    .run();
}

// We use this function instead of relying on editor.isActive('...') because it
// checks the current selection, not from and to passed by user
function isRangeLinkBlocked(editor: Editor, from: number, to: number): boolean {
  const { doc, schema } = editor.state;

  const hasInlineCode =
    schema.marks.code && doc.rangeHasMark(from, to, schema.marks.code);

  if (hasInlineCode) {
    return true;
  }

  let hasBlockedNode = false;
  const blockedNodes = ['codeBlock', 'image'];
  doc.nodesBetween(from, to, (node) => {
    if (hasBlockedNode) return false;
    if (blockedNodes.includes(node.type.name)) {
      hasBlockedNode = true;
      return false;
    }
    return true;
  });

  return hasBlockedNode;
}
