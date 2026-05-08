import Blockquote from '@tiptap/extension-blockquote';
import { toggleParagraphFormat } from './formatRules';
import {
  wrappedBlockBackspace,
  wrappedBlockEnter,
} from './wrappedBlockKeyboard';

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    codeBlock: {
      toggleCodeBlock: () => ReturnType;
    };
  }
}

// We extend Blockquote, not CodeBlock: this node wraps (paragraph)+; TipTap's CodeBlock is a leaf block, not a paragraph container.
export const EnrichedCodeBlock = Blockquote.extend({
  name: 'codeBlock',
  content: '(paragraph)+',

  parseHTML() {
    return [{ tag: 'codeblock' }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['codeblock', HTMLAttributes, 0];
  },

  addCommands() {
    return {
      toggleCodeBlock:
        () =>
        ({ editor, commands, chain }) =>
          toggleParagraphFormat(
            () => editor.isActive('codeBlock'),
            () => commands.lift('codeBlock'),
            (c) => c.toggleWrap('codeBlock'),
            chain
          ),
    };
  },

  addInputRules() {
    return [];
  },

  addKeyboardShortcuts() {
    return {
      Enter: ({ editor }) => wrappedBlockEnter(editor, 'codeBlock'),
      Backspace: ({ editor }) => wrappedBlockBackspace(editor, 'codeBlock'),
    };
  },
});
