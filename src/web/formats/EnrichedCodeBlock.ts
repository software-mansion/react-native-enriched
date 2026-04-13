import Blockquote from '@tiptap/extension-blockquote';

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    enrichedCodeBlock: {
      toggleEnrichedCodeBlock: () => ReturnType;
    };
  }
}

// Native uses <codeblock><p>…</p></codeblock> — the same block+ structure as
// blockquote, so we extend Blockquote and swap the tag.
export const EnrichedCodeBlock = Blockquote.extend({
  name: 'enrichedCodeBlock',
  content: '(paragraph | heading)+',

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
        ({ commands }) =>
          commands.toggleWrap(this.name),
    };
  },

  addInputRules() {
    return [];
  },
});
