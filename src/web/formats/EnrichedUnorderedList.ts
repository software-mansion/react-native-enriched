import { BulletList } from '@tiptap/extension-list';
import { toggleParagraphFormat } from './formatRules';

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    enrichedUnorderedList: {
      toggleEnrichedUnorderedList: () => ReturnType;
    };
  }
}

export const EnrichedUnorderedList = BulletList.extend({
  parseHTML() {
    return [
      {
        tag: 'ul',
        getAttrs: (el) =>
          (el as HTMLElement).getAttribute('data-type') !== 'checkbox'
            ? null
            : false,
      },
    ];
  },

  addInputRules() {
    return [];
  },

  addKeyboardShortcuts() {
    return {};
  },

  addCommands() {
    return {
      ...this.parent?.(),
      toggleEnrichedUnorderedList:
        () =>
        ({ editor, commands }) =>
          toggleParagraphFormat(
            editor,
            () => editor.isActive('unorderedList'),
            () => commands.lift('listItem'),
            (c) => c.toggleBulletList()
          ),
    };
  },
});
