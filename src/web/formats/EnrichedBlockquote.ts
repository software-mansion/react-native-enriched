import Blockquote from '@tiptap/extension-blockquote';

export const EnrichedBlockquote = Blockquote.extend({
  content: '(paragraph | heading)+',

  addInputRules() {
    return [];
  },
});
