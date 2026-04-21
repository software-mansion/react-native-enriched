import type { Editor } from '@tiptap/core';
import type { Node } from '@tiptap/pm/model';
import { Fragment } from '@tiptap/pm/model';

/**
 * Clears block styling with `setParagraph`, then wraps the selection’s blocks in a flat
 * `listTypeName` (one `itemTypeName` per block). Uses `block.copy(block.content)` so text
 * is preserved (bare `copy()` clears children).
 *
 * Does not use `toggleList`: with `listItem` content `'paragraph'`, stock wrap often fails on
 * multiline selections; the replace step builds `list → listItem → paragraph` explicitly.
 */
export function applyWrappingListToSelection(
  editor: Editor,
  listTypeName: string,
  itemTypeName: string
): boolean {
  return editor
    .chain()
    .focus()
    .setParagraph()
    .command(({ tr, state }) => {
      const listType = state.schema.nodes[listTypeName];
      const itemType = state.schema.nodes[itemTypeName];
      if (!listType || !itemType) {
        return false;
      }

      const { $from, $to } = state.selection;
      const range = $from.blockRange($to);
      if (!range) {
        return false;
      }

      const listItems: Node[] = [];
      for (let i = range.startIndex; i < range.endIndex; i++) {
        const block = range.parent.child(i);
        listItems.push(
          itemType.create(null, Fragment.from(block.copy(block.content)))
        );
      }

      if (listItems.length === 0) {
        return false;
      }

      const list = listType.create(null, Fragment.from(listItems));
      tr.replaceWith(range.start, range.end, list);
      return true;
    })
    .run();
}
