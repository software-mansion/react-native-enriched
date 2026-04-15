import { OrderedList } from '@tiptap/extension-list';
import { toggleParagraphFormat } from './formatRules';

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    enrichedOrderedList: {
      toggleEnrichedOrderedList: () => ReturnType;
    };
  }
}

export const EnrichedOrderedList = OrderedList.extend({
  addInputRules() {
    return [];
  },

  addKeyboardShortcuts() {
    return {};
  },

  addCommands() {
    return {
      ...this.parent?.(),
      toggleEnrichedOrderedList:
        () =>
        ({ editor, commands }) =>
          toggleParagraphFormat(
            editor,
            () => editor.isActive('orderedList'),
            () => commands.liftListItem('listItem'),
            (c) => c.toggleOrderedList()
          ),
    };
  },
});
