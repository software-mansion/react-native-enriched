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
    return [{ tag: 'ul' }];
  },

  addInputRules() {
    return [];
  },

  addKeyboardShortcuts() {
    return {};
  },

  addCommands() {
    return {
      toggleEnrichedUnorderedList:
        () =>
        ({ editor, commands }) =>
          toggleParagraphFormat(
            editor,
            () => editor.isActive('bulletList'),
            () => commands.liftListItem('listItem'),
            (c) => c.toggleList('bulletList', 'listItem')
          ),
    };
  },
});
