import { type CommandProps } from '@tiptap/core';
import { TaskList } from '@tiptap/extension-list';

import { applyWrappingListToSelection } from './applyWrappingListToSelection';

export const EnrichedTaskList = TaskList.extend({
  addCommands() {
    return {
      toggleTaskList:
        () =>
        ({ editor, commands, chain }: CommandProps) => {
          if (editor.isActive('taskList')) {
            return commands.setParagraph();
          }

          return applyWrappingListToSelection(
            editor,
            chain,
            'taskList',
            'taskItem',
            { checked: false }
          );
        },
    };
  },

  addKeyboardShortcuts() {
    return {};
  },
});
