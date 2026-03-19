import type { Editor } from '@tiptap/core';

export default function getNormalizedHtml(editor: Editor): string {
  const content = editor.getHTML();

  return `<html>${content}</html>`;
}
