import { TaskItem } from '@tiptap/extension-list';

import { listBackspace, listEnter } from './listKeyboard';

const TASK_LIST_WRAPPERS = [
  'taskList',
  'unorderedList',
  'orderedList',
] as const;

export const EnrichedTaskItem = TaskItem.extend({
  content: 'paragraph',

  addKeyboardShortcuts() {
    return {
      Enter: ({ editor }) => listEnter(editor, 'taskItem'),
      Backspace: ({ editor }) => {
        if (editor.isActive('listItem')) {
          return false;
        }
        return listBackspace(editor, 'taskItem', TASK_LIST_WRAPPERS);
      },
    };
  },
});
