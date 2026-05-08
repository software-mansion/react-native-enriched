import { isTextSelection, type Editor } from '@tiptap/core';
import type { ResolvedPos } from '@tiptap/pm/model';

// Same as prosemirror-commands `findCutBefore` (not exported from that package)
// Resolves to the gap between this block and the block above it.
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

/** Line start → lift current block or join with the block above (wrapped blocks + lists). */
export function lineStartBackspace(
  editor: Editor,
  options: {
    isActive: () => boolean;
    lift: () => boolean;
    shouldJoinBefore: (nodeNameBefore: string | undefined) => boolean;
  }
): boolean {
  const { selection } = editor.state;

  if (
    !isTextSelection(selection) ||
    !selection.$cursor ||
    selection.$cursor.parentOffset !== 0
  ) {
    return false;
  }

  if (options.isActive()) {
    return options.lift();
  }

  const $cut = findCutBefore(selection.$cursor);
  const beforeName = $cut?.nodeBefore?.type.name;
  if (options.shouldJoinBefore(beforeName)) {
    return editor.chain().focus().joinTextblockBackward().run();
  }

  return false;
}

// Enter only splits inside the wrapper so the default handler does not exit the block.
export function wrappedBlockEnter(
  editor: Editor,
  wrapperNodeName: string
): boolean {
  if (editor.isActive(wrapperNodeName)) {
    return editor.commands.splitBlock();
  }
  return false;
}

// Backspace at line start inside the wrapper lifts the current paragraph out.
// Backspace at line start in a paragraph below the wrapper uses `joinTextblockBackward`
// so default `joinBackward` / `deleteBarrier` does not re-wrap the paragraph into the
// wrapper above.
export function wrappedBlockBackspace(
  editor: Editor,
  wrapperNodeName: string
): boolean {
  return lineStartBackspace(editor, {
    isActive: () => editor.isActive(wrapperNodeName),
    lift: () => editor.chain().focus().lift(wrapperNodeName).run(),
    shouldJoinBefore: (beforeName) => beforeName === wrapperNodeName,
  });
}
