import { Extension } from '@tiptap/core';
import type { Mark } from '@tiptap/pm/model';
import { Plugin, PluginKey } from '@tiptap/pm/state';

export const StrictMarksPlugin = Extension.create({
  name: 'strictMarksPlugin',

  addProseMirrorPlugins() {
    return [
      new Plugin({
        key: new PluginKey('strictMarks'),
        appendTransaction(transactions, _oldState, newState) {
          const { selection } = newState;
          const { empty, $from } = selection;

          // Only enforce on collapsed cursor
          if (!empty) return null;

          // Respect explicit toolbar clicks (transaction has no doc changes but sets marks)
          const isExplicitToggle = transactions.some(
            (tr) => !tr.docChanged && tr.storedMarks !== null
          );
          if (isExplicitToggle) return null;

          let strictMarks: readonly Mark[];

          // If the editor is completely empty, strip all marks.
          if (newState.doc.textContent.length === 0) {
            strictMarks = [];
          }
          // If there is a character on the left, strictly inherit its marks.
          else if ($from.nodeBefore) {
            strictMarks = $from.nodeBefore.marks;
          }
          // Start of a line/paragraph
          else {
            if ($from.nodeAfter) {
              // If there is text on the right, force plain text to stop right-to-left bleeding.
              strictMarks = [];
            } else {
              // If the line is completely empty (e.g. just pressed Enter),
              // respect ProseMirror's inherited marks carried over from the previous line.
              strictMarks = newState.storedMarks || $from.marks();
            }
          }

          // What ProseMirror wants to apply natively
          const activeMarks = newState.storedMarks || $from.marks();

          // Compare and skip if already matching
          const isSame =
            strictMarks.length === activeMarks.length &&
            strictMarks.every((m) => m.isInSet(activeMarks));

          if (isSame) return null;

          // Override ProseMirror with our strict marks
          return newState.tr.setStoredMarks(strictMarks);
        },
      }),
    ];
  },
});
