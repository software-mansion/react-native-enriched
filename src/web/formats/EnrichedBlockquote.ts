import Blockquote from '@tiptap/extension-blockquote';
import { toggleParagraphFormat } from './formatRules';

export const EnrichedBlockquote = Blockquote.extend({
  content: '(paragraph)+',

  addInputRules() {
    return [];
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
