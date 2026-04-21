import { OrderedList } from '@tiptap/extension-list';

import { applyWrappingListToSelection } from './applyWrappingListToSelection';

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    enrichedOrderedList: {
      toggleEnrichedOrderedList: () => ReturnType;
    };
  }
}

export const EnrichedOrderedList = OrderedList.extend({
  addInputRules() {
    return [];
  },

  addKeyboardShortcuts() {
    return {};
  },

  addCommands() {
    return {
      toggleEnrichedOrderedList:
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
