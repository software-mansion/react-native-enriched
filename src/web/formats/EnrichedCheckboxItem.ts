import { TaskItem } from '@tiptap/extension-list';

import { listBackspace, listEnter } from './listKeyboard';

const CHECKBOX_LIST_WRAPPERS = [
  'checkboxList',
  'unorderedList',
  'orderedList',
] as const;

export const EnrichedCheckboxItem = TaskItem.extend({
  name: 'checkboxItem',

  addOptions() {
    return {
      nested: false,
      HTMLAttributes: {},
      taskListTypeName: 'checkboxList',
    };
  },

  content: 'paragraph',

  addKeyboardShortcuts() {
    return {
      Enter: ({ editor }) => listEnter(editor, 'checkboxItem'),
      Backspace: ({ editor }) => {
        if (editor.isActive('listItem')) {
          return false;
        }
        return listBackspace(editor, 'checkboxItem', CHECKBOX_LIST_WRAPPERS);
      },
    };
  },
});
