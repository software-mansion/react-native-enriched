import { ListItem } from '@tiptap/extension-list';

import { listBackspace, listEnter } from './listKeyboard';

const LIST_WRAPPERS = ['bulletList', 'orderedList'] as const;

export const EnrichedListItem = ListItem.extend({
  content: 'paragraph',

  addKeyboardShortcuts() {
    return {
      Enter: ({ editor }) => listEnter(editor, 'listItem'),
      Backspace: ({ editor }) =>
        listBackspace(editor, 'listItem', LIST_WRAPPERS),
    };
  },
});
