import type { Editor } from '@tiptap/core';
import type { Node } from '@tiptap/pm/model';
import { Fragment } from '@tiptap/pm/model';
import { TextSelection } from '@tiptap/pm/state';

import { nativePosToTiptapPos, tiptapPosToNativePos } from '../positionMapping';

type ChainedCommands = ReturnType<Editor['chain']>;

/**
 * Clears block styling with `clearNodes`, then wraps the selection’s blocks in a flat
 * `listTypeName` (one `itemTypeName` per block).
 *
 * We don't use toggleList because we've changed ListItem's content to
 * 'paragraph', in order not to allow nested lists. This however caused the
 * default toggle implementation to fail.
 *
 * SELECTION PRESERVATION: Modifying node boundaries here (destroying and
 * recreating blocks) causes ProseMirror's built-in selection to be invalid. To
 * fix this, we use our Android/iOS native coordinate system. Because the native
 * selection only cares about raw content and ignores Tiptap's node boundary
 * tokens, we store the cursor positions in the native format before the
 * transaction, and map them back to the new Tiptap document afterward.
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
    .clearNodes()
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
