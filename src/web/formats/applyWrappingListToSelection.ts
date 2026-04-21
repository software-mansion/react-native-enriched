import type { Editor } from '@tiptap/core';
import type { Node } from '@tiptap/pm/model';
import { Fragment } from '@tiptap/pm/model';
import { TextSelection } from '@tiptap/pm/state';

import { nativePosToTiptapPos, tiptapPosToNativePos } from '../positionMapping';

type ChainedCommands = ReturnType<Editor['chain']>;

/**
 * Clears block styling with `setParagraph`, then wraps the selection’s blocks in a flat
 * `listTypeName` (one `itemTypeName` per block).
 *
 * We don't use toggleList because we've changed ListItem's content to
 * 'paragraph' causing the default toggle behavior to fail.
 *
 *
 * Selection is preserved via {@link tiptapPosToNativePos} / {@link nativePosToTiptapPos}:
 * Operations in this function collapse PM positions causing the selection to be
 * invalid, because PM positions are effected by node boundaries and such. So we use the fact that
 * the equivalent native selection before and after the operation is the same.
 */
export function applyWrappingListToSelection(
  editor: Editor,
  chain: () => ChainedCommands,
  listTypeName: string,
  itemTypeName: string
): boolean {
  const { doc: docBefore, selection: selBefore } = editor.state;
  const nativeAnchor = tiptapPosToNativePos(docBefore, selBefore.anchor);
  const nativeHead = tiptapPosToNativePos(docBefore, selBefore.head);

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

      const docAfter = tr.doc;
      const pmAnchor = nativePosToTiptapPos(docAfter, nativeAnchor);
      const pmHead = nativePosToTiptapPos(docAfter, nativeHead);
      tr.setSelection(
        TextSelection.between(
          docAfter.resolve(pmAnchor),
          docAfter.resolve(pmHead)
        )
      );
      return true;
    })
    .run();
}
