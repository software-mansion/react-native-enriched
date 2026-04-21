import { BulletList } from '@tiptap/extension-list';
import { applyWrappingListToSelection } from './applyWrappingListToSelection';

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    enrichedUnorderedList: {
      toggleEnrichedUnorderedList: () => ReturnType;
    };
  }
}

export const EnrichedUnorderedList = BulletList.extend({
  parseHTML() {
    return [{ tag: 'ul' }];
  },

  addInputRules() {
    return [];
  },

  addKeyboardShortcuts() {
    return {};
  },

  addCommands() {
    return {
      toggleEnrichedUnorderedList:
        () =>
        ({ editor, commands, chain }) => {
          if (editor.isActive('bulletList')) {
            return commands.setParagraph();
          }

          return applyWrappingListToSelection(chain, 'bulletList', 'listItem');
        },
    };
  },
});
