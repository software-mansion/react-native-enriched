import { isTextSelection, type Editor } from '@tiptap/core';
import type { ResolvedPos } from '@tiptap/pm/model';

/**
 * Same as prosemirror-commands `findCutBefore` (not exported from that package).
 * Resolves to the gap between this block and the block above it.
 */
export function findCutBefore($pos: ResolvedPos): ResolvedPos | null {
  if (!$pos.parent.type.spec.isolating) {
    for (let i = $pos.depth - 1; i >= 0; i--) {
      if ($pos.index(i) > 0) {
        return $pos.doc.resolve($pos.before(i + 1));
      }
      if ($pos.node(i).type.spec.isolating) {
        break;
      }
    }
  }
  return null;
}

/**
 * Enter / Backspace behavior for block-level wrappers that use `(paragraph)+` and can be
 * lifted with `lift(wrapperNodeName)` (e.g. blockquote, enriched code block).
 *
 * - Enter: only split inside the wrapper so the default handler does not exit the block.
 * - Backspace at line start inside the wrapper: lift the current paragraph out.
 * - Backspace at line start in a paragraph *below* the wrapper: use `joinTextblockBackward`
 *   so default `joinBackward` / `deleteBarrier` does not re-wrap the paragraph into the
 *   wrapper above.
 */
export function wrappedBlockEnter(
  editor: Editor,
  wrapperNodeName: string
): boolean {
  if (editor.isActive(wrapperNodeName)) {
    return editor.commands.splitBlock();
  }
  return false;
}

export function wrappedBlockBackspace(
  editor: Editor,
  wrapperNodeName: string
): boolean {
  const { selection } = editor.state;

  if (
    !isTextSelection(selection) ||
    !selection.$cursor ||
    selection.$cursor.parentOffset !== 0
  ) {
    return false;
  }

  if (editor.isActive(wrapperNodeName)) {
    return editor.chain().focus().lift(wrapperNodeName).run();
  }

  const $cut = findCutBefore(selection.$cursor);
  if ($cut?.nodeBefore?.type.name === wrapperNodeName) {
    return editor.chain().focus().joinTextblockBackward().run();
  }

  return false;
}
