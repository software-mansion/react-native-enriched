import { Extension } from '@tiptap/core';
import type { Mark } from '@tiptap/pm/model';
import { Plugin, PluginKey } from '@tiptap/pm/state';

export const StrictMarksPlugin = Extension.create({
  name: 'strictMarksPlugin',
  addProseMirrorPlugins() {
    return [
      new Plugin({
        key: new PluginKey('strictMarks'),
        appendTransaction(transactions, oldState, newState) {
          const { selection } = newState;

          // Only enforce on collapsed cursor
          if (!selection.empty) return null;

          // Respect explicit toolbar clicks
          const docChanged = !oldState.doc.eq(newState.doc);
          const isExplicitToggle =
            !docChanged && transactions.some((tr) => tr.storedMarks !== null);
          if (isExplicitToggle) return null;

          const { $from } = selection;
          const textLengthChanged =
            oldState.doc.textContent.length !== newState.doc.textContent.length;

          let strictMarks: readonly Mark[];

          // Editor is completely empty
          if (newState.doc.textContent.length === 0) {
            strictMarks = textLengthChanged
              ? [] // User deleted the last character
              : oldState.storedMarks || newState.storedMarks || []; // Structural nav
          }
          // Character to the left exists -> Strictly inherit from it
          else if ($from.nodeBefore) {
            strictMarks = $from.nodeBefore.marks;
          }
          // Start of a line, but text exists to the right
          else if ($from.nodeAfter) {
            if (!docChanged) {
              strictMarks = []; // Pure cursor movement, kill RTL bleeding
            } else if (oldState.selection.$from.parentOffset === 0) {
              strictMarks = []; // Push-down (Enter pressed before text)
            } else {
              strictMarks = $from.nodeAfter.marks; // Split a line in the middle
            }
          }
          // Completely empty line (no text before or after)
          else {
            if (textLengthChanged) {
              // Inherit marks by resolving the position exactly at the end of the previous node.
              const prevEndPos = $from.before() - 1;
              strictMarks =
                prevEndPos > 0 ? newState.doc.resolve(prevEndPos).marks() : [];
            } else if (oldState.storedMarks) {
              strictMarks = oldState.storedMarks; // Structural nav (Enter/Backspace), keep explicit marks
            } else {
              strictMarks = newState.storedMarks || $from.marks(); // Respect inherited marks
            }
          }

          // Compare and apply if changed
          const activeMarks = newState.storedMarks || $from.marks();
          const isSame =
            strictMarks.length === activeMarks.length &&
            strictMarks.every((m) => m.isInSet(activeMarks));

          if (isSame) return null;

          return newState.tr.setStoredMarks(strictMarks);
        },
      }),
    ];
  },
});
