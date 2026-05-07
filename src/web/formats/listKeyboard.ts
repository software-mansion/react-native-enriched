import { isTextSelection, type Editor, type JSONContent } from '@tiptap/core';

import { lineStartBackspace } from './wrappedBlockKeyboard';

function emptyListItemContent(itemName: string): JSONContent {
  return {
    type: itemName,
    content: [{ type: 'paragraph' }],
  };
}

// Enter: always extend the list — splitListItem fails on an empty last item (see TipTap splitListItem).
export function listEnter(editor: Editor, itemName: string): boolean {
  if (!editor.isActive(itemName)) {
    return false;
  }
  if (editor.chain().focus().splitListItem(itemName).scrollIntoView().run()) {
    return true;
  }

  const { selection } = editor.state;
  if (!selection.empty || !isTextSelection(selection)) {
    return false;
  }

  const $from = selection.$from;
  if ($from.parent.content.size > 0) {
    return false;
  }

  // Flat lists only: list item is always the parent block of the paragraph (depth − 1).
  const itemDepth = $from.depth - 1;
  if (itemDepth < 1) {
    return false;
  }
  const insertPos = $from.after(itemDepth);

  return editor
    .chain()
    .focus()
    .insertContentAt(insertPos, emptyListItemContent(itemName))
    .scrollIntoView()
    .run();
}

// Backspace: first press at line start lifts the list item; second press (paragraph below list) joins backward.
export function listBackspace(
  editor: Editor,
  itemName: string,
  wrapperNames: readonly string[]
): boolean {
  return lineStartBackspace(editor, {
    isActive: () => editor.isActive(itemName),
    lift: () => editor.chain().focus().liftListItem(itemName).run(),
    shouldJoinBefore: (beforeName) =>
      beforeName != null && wrapperNames.includes(beforeName),
  });
}
