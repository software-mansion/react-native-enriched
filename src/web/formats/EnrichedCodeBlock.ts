import Blockquote from '@tiptap/extension-blockquote';
import { toggleParagraphFormat } from './formatRules';
import { Plugin, PluginKey } from '@tiptap/pm/state';

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
  addProseMirrorPlugins() {
    return [
      new Plugin({
        // Preventing selecting inline styles when enrichedCodeBlock is active
        // is not enough on its own, because it does not handle for example
        // pasting text with inline styles into the code block. This plugin
        // makes sure no inline styles are applied to the text inside the code
        // block when the code block is active.
        key: new PluginKey('stripMarksInEnrichedCodeBlock'),
        appendTransaction: (transactions, _oldState, newState) => {
          if (!transactions.some((tr) => tr.docChanged)) return;

          const tr = newState.tr;

          const allMarks = Object.values(newState.schema.marks);

          newState.doc.descendants((node, pos) => {
            if (node.type.name === this.name) {
              allMarks.forEach((markType) => {
                tr.removeMark(pos + 1, pos + node.nodeSize - 1, markType);
              });
              return false;
            }

            return true;
          });

          return tr.steps.length > 0 ? tr : null;
        },
      }),
    ];
  },
});
