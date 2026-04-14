import { Extension } from '@tiptap/core';
import { Mark, type ResolvedPos } from '@tiptap/pm/model';
import { Plugin, PluginKey, type EditorState } from '@tiptap/pm/state';

function resolveStrictMarks(
  $from: ResolvedPos,
  oldState: EditorState,
  newState: EditorState,
  docChanged: boolean,
  textLengthChanged: boolean
): readonly Mark[] {
  // Editor completely empty
  if (newState.doc.textContent.length === 0) {
    return textLengthChanged
      ? []
      : (oldState.storedMarks ?? newState.storedMarks ?? []);
  }

  // Character to the left: strictly inherit from it
  if ($from.nodeBefore) {
    return $from.nodeBefore.marks;
  }

  // Start of line with text to the right
  if ($from.nodeAfter) {
    if (!docChanged) {
      return []; // Pure cursor movement: kill RTL mark bleeding
    }
    const old$ = oldState.selection.$from;
    const { nodeBefore: oldBefore, nodeAfter: oldAfter } = old$;
    // Styled|plain boundary after Enter/paste/etc.: inherit the left inline's marks so
    // bold, code, and other marks behave the same on a new paragraph.
    if (
      oldBefore &&
      oldAfter &&
      !Mark.sameSet(oldBefore.marks, oldAfter.marks)
    ) {
      return oldBefore.marks;
    }
    return $from.nodeAfter.marks;
  }

  // Completely empty line
  if (textLengthChanged) {
    const prevEndPos = $from.before() - 1;
    return prevEndPos > 0 ? newState.doc.resolve(prevEndPos).marks() : [];
  }
  if (oldState.storedMarks) {
    return oldState.storedMarks; // Structural nav (Enter/Backspace): keep explicit marks
  }
  return newState.storedMarks ?? $from.marks();
}

export const StrictMarksPlugin = Extension.create({
  name: 'strictMarksPlugin',
  addProseMirrorPlugins() {
    return [
      new Plugin({
        key: new PluginKey('strictMarks'),
        appendTransaction(transactions, oldState, newState) {
          const { selection } = newState;

          if (!selection.empty) return null;

          const docChanged = !oldState.doc.eq(newState.doc);
          const isExplicitToggle =
            !docChanged && transactions.some((tr) => tr.storedMarks !== null);
          if (isExplicitToggle) return null;

          const { $from } = selection;
          const textLengthChanged =
            oldState.doc.textContent.length !== newState.doc.textContent.length;

          const strictMarks = resolveStrictMarks(
            $from,
            oldState,
            newState,
            docChanged,
            textLengthChanged
          );

          const activeMarks = newState.storedMarks ?? $from.marks();
          if (Mark.sameSet(strictMarks, activeMarks)) return null;

          return newState.tr.setStoredMarks(strictMarks);
        },
      }),
    ];
  },
});
