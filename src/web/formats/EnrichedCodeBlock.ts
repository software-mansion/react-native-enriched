import Blockquote from '@tiptap/extension-blockquote';
import { toggleParagraphFormat } from './formatRules';

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    enrichedCodeBlock: {
      toggleEnrichedCodeBlock: () => ReturnType;
    };
  }
}

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
});
