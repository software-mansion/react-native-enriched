import { wrappingInputRule } from '@tiptap/core';
import { OrderedList } from '@tiptap/extension-list';

import { applyWrappingListToSelection } from './applyWrappingListToSelection';

const ORDERED_LIST_INPUT_REGEX = /^1\.\s$/;

export const EnrichedOrderedList = OrderedList.extend({
  addInputRules() {
    return [
      wrappingInputRule({
        find: ORDERED_LIST_INPUT_REGEX,
        type: this.type,
      }),
    ];
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
