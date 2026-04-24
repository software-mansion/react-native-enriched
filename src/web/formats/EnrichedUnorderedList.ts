import { wrappingInputRule } from '@tiptap/core';
import { BulletList } from '@tiptap/extension-list';

import { applyWrappingListToSelection } from './applyWrappingListToSelection';

const BULLET_LIST_INPUT_REGEX = /^\s*-\s$/;

export const EnrichedUnorderedList = BulletList.extend({
  addInputRules() {
    return [
      wrappingInputRule({
        find: BULLET_LIST_INPUT_REGEX,
        type: this.type,
      }),
    ];
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
