import type { Editor } from '@tiptap/core';
import type { Node } from '@tiptap/pm/model';
import { Fragment } from '@tiptap/pm/model';

type ChainedCommands = ReturnType<Editor['chain']>;

/**
 * Clears block styling with `setParagraph`, then wraps the selection’s blocks in a flat
 * `listTypeName` (one `itemTypeName` per block).
 *
 * We don't use toggleList because we've changed ListItem's content to
 * 'paragraph' causing the default toggle behavior to fail.
 */
export function applyWrappingListToSelection(
  chain: () => ChainedCommands,
  listTypeName: string,
  itemTypeName: string
): boolean {
  return chain()
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
