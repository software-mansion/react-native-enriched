import type { Editor } from '@tiptap/react';

export function runSafelyInEditor<T>(
  editor: Editor | null,
  callback: (editor: Editor) => T
): T | null {
  if (editor && !editor.isDestroyed) {
    return callback(editor);
  }
  return null;
}
