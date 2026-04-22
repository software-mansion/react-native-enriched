import { OrderedList } from '@tiptap/extension-list';

import { applyWrappingListToSelection } from './applyWrappingListToSelection';

export const EnrichedOrderedList = OrderedList.extend({
  addInputRules() {
    return [];
  },

  addKeyboardShortcuts() {
    return {};
  },

  addCommands() {
    return {
      toggleOrderedList:
        () =>
        ({ editor, commands, chain }) => {
          if (editor.isActive('orderedList')) {
            return commands.setParagraph();
          }

          return applyWrappingListToSelection(
            editor,
            chain,
            'orderedList',
            'listItem'
          );
        },
    };
  },
});
