import Blockquote from '@tiptap/extension-blockquote';
import { toggleParagraphFormat } from './formatRules';
import {
  wrappedBlockBackspace,
  wrappedBlockEnter,
} from './wrappedBlockKeyboard';

export const EnrichedBlockquote = Blockquote.extend({
  content: '(paragraph)+',

  addInputRules() {
    return [];
  },

  addKeyboardShortcuts() {
    return {
      Enter: ({ editor }) => wrappedBlockEnter(editor, 'blockquote'),
      Backspace: ({ editor }) => wrappedBlockBackspace(editor, 'blockquote'),
    };
  },

  addCommands() {
    return {
      ...this.parent?.(),
      toggleBlockquote:
        () =>
        ({ editor, commands, chain }) =>
          toggleParagraphFormat(
            editor,
            chain(),
            () => editor.isActive('blockquote'),
            () => commands.lift('blockquote'),
            (c) => c.toggleWrap('blockquote')
          ),
    };
  },
});
