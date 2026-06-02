import { Extension, type Editor } from '@tiptap/core';

import type { HtmlStyle } from '../../types';
import { isFormatBlocked } from '../formats/formatRules';

export interface ShortcutPluginOptions {
  getHtmlStyle: () => Required<HtmlStyle>;
}

function insertPlainTextFromClipboard(editor: Editor): Promise<void> {
  return navigator.clipboard.readText().then((text) => {
    if (editor.isDestroyed) return;
    editor.chain().focus().deleteSelection().insertContent(text).run();
  });
}

export const ShortcutPlugin = Extension.create<ShortcutPluginOptions>({
  name: 'shortcutPlugin',

  addOptions() {
    return {
      getHtmlStyle: () => {
        throw new Error(
          'ShortcutPlugin.configure({ getHtmlStyle }) is required'
        );
      },
    };
  },

  addKeyboardShortcuts() {
    const htmlStyle = () => this.options.getHtmlStyle();

    const mark =
      (name: string, run: (editor: Editor) => boolean) =>
      ({ editor }: { editor: Editor }) => {
        if (!editor.isEditable) return false;
        if (isFormatBlocked(name, editor, htmlStyle())) return true;
        return run(editor);
      };

    return {
      'Mod-Shift-v': ({ editor }) => {
        if (!editor.isEditable) return false;
        insertPlainTextFromClipboard(editor).catch(() => {});
        return true;
      },
      'Mod-Alt-Shift-c': ({ editor }) => {
        if (!editor.isEditable) return false;
        return editor.commands.toggleCodeBlock();
      },
      'Mod-Shift-c': mark('code', (editor) => editor.commands.toggleCode()),
      'Mod-Shift-x': mark('strike', (editor) => editor.commands.toggleStrike()),
      'Mod-b': mark('bold', (editor) => editor.commands.toggleBold()),
      'Mod-i': mark('italic', (editor) => editor.commands.toggleItalic()),
      'Mod-u': mark('underline', (editor) => editor.commands.toggleUnderline()),
      'Mod-Shift-7': ({ editor }) => {
        if (!editor.isEditable) return false;
        return editor.commands.toggleOrderedList();
      },
      'Mod-Shift-8': ({ editor }) => {
        if (!editor.isEditable) return false;
        return editor.commands.toggleUnorderedList();
      },
      'Mod-Shift-9': ({ editor }) => {
        if (!editor.isEditable) return false;
        return editor.commands.toggleCheckboxList(false);
      },
      'Mod-Alt-0': ({ editor }) => {
        if (!editor.isEditable) return false;
        return editor.commands.setParagraph();
      },
      'Mod-Alt-1': ({ editor }) => {
        if (!editor.isEditable) return false;
        return editor.commands.toggleHeading({ level: 1 });
      },
      'Mod-Alt-2': ({ editor }) => {
        if (!editor.isEditable) return false;
        return editor.commands.toggleHeading({ level: 2 });
      },
      'Mod-Alt-3': ({ editor }) => {
        if (!editor.isEditable) return false;
        return editor.commands.toggleHeading({ level: 3 });
      },
      'Mod-Alt-4': ({ editor }) => {
        if (!editor.isEditable) return false;
        return editor.commands.toggleHeading({ level: 4 });
      },
      'Mod-Alt-5': ({ editor }) => {
        if (!editor.isEditable) return false;
        return editor.commands.toggleHeading({ level: 5 });
      },
      'Mod-Alt-6': ({ editor }) => {
        if (!editor.isEditable) return false;
        return editor.commands.toggleHeading({ level: 6 });
      },
    };
  },
});
