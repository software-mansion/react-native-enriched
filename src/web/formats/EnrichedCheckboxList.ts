import { type CommandProps } from '@tiptap/core';
import { TaskList } from '@tiptap/extension-list';

import { applyWrappingListToSelection } from './applyWrappingListToSelection';

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    checkboxList: {
      toggleCheckboxList: (checked: boolean) => ReturnType;
    };
  }
}

export const EnrichedCheckboxList = TaskList.extend({
  name: 'checkboxList',

  addOptions() {
    return {
      itemTypeName: 'checkboxItem',
      HTMLAttributes: {},
    };
  },

  addCommands() {
    return {
      toggleCheckboxList: (checked: boolean) => {
        return ({ editor, commands, chain }: CommandProps): boolean => {
          if (editor.isActive('checkboxList')) {
            return commands.setParagraph();
          }

          return applyWrappingListToSelection(
            editor,
            chain,
            'checkboxList',
            'checkboxItem',
            { checked }
          );
        };
      },
    };
  },

  addKeyboardShortcuts() {
    return {};
  },
});
