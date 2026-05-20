import { wrappingInputRule, type CommandProps } from '@tiptap/core';
import { BulletList } from '@tiptap/extension-list';

import { applyWrappingListToSelection } from './applyWrappingListToSelection';

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    unorderedList: {
      toggleUnorderedList: () => ReturnType;
    };
  }
}

const BULLET_LIST_INPUT_REGEX = /^\s*-\s$/;

export const EnrichedUnorderedList = BulletList.extend({
  name: 'unorderedList',

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
      toggleUnorderedList:
        () =>
        ({ editor, commands, chain }: CommandProps) => {
          if (editor.isActive('unorderedList')) {
            return commands.setParagraph();
          }

          return applyWrappingListToSelection(
            editor,
            chain,
            'unorderedList',
            'listItem'
          );
        },
    };
  },
});
