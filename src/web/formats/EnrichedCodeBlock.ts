import Blockquote from '@tiptap/extension-blockquote';
import { toggleParagraphFormat } from './formatRules';
import {
  wrappedBlockBackspace,
  wrappedBlockEnter,
} from './wrappedBlockKeyboard';

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    enrichedCodeBlock: {
      toggleEnrichedCodeBlock: () => ReturnType;
    };
  }
}

// We extend Blockquote, not CodeBlock: this node wraps (paragraph)+; TipTap's CodeBlock is a leaf block, not a paragraph container.
export const EnrichedCodeBlock = Blockquote.extend({
  name: 'enrichedCodeBlock',
  content: '(paragraph)+',

  parseHTML() {
    return [{ tag: 'codeblock' }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['codeblock', HTMLAttributes, 0];
  },

  addCommands() {
    return {
      toggleEnrichedCodeBlock:
        () =>
        ({ editor, commands, chain }) =>
          toggleParagraphFormat(
            editor,
            chain(),
            () => editor.isActive('enrichedCodeBlock'),
            () => commands.lift('enrichedCodeBlock'),
            (c) => c.toggleWrap('enrichedCodeBlock')
          ),
    };
  },

  addInputRules() {
    return [];
  },

  addKeyboardShortcuts() {
    return {
      Enter: ({ editor }) => wrappedBlockEnter(editor, 'enrichedCodeBlock'),
      Backspace: ({ editor }) =>
        wrappedBlockBackspace(editor, 'enrichedCodeBlock'),
    };
  },
});
