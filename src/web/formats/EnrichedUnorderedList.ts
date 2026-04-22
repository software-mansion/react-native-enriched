import { BulletList } from '@tiptap/extension-list';
import { applyWrappingListToSelection } from './applyWrappingListToSelection';

export const EnrichedUnorderedList = BulletList.extend({
  addInputRules() {
    return [];
  },

  addKeyboardShortcuts() {
    return {};
  },

  addCommands() {
    return {
      toggleBulletList:
        () =>
        ({ editor, commands, chain }) => {
          if (editor.isActive('bulletList')) {
            return commands.setParagraph();
          }

          return applyWrappingListToSelection(
            editor,
            chain,
            'bulletList',
            'listItem'
          );
        },
    };
  },
});
