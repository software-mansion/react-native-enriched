import Heading from '@tiptap/extension-heading';
import { toggleParagraphFormat } from './formatRules';

export const HEADING_LEVELS = [1, 2, 3, 4, 5, 6] as const;

export const EnrichedHeading = Heading.configure({
  levels: [...HEADING_LEVELS],
}).extend({
  addKeyboardShortcuts() {
    return {};
  },
  addInputRules() {
    return [];
  },

  addCommands() {
    return {
      ...this.parent?.(),
      toggleHeading:
        (attrs) =>
        ({ editor, commands, chain }) =>
          toggleParagraphFormat(
            editor,
            chain(),
            () => editor.isActive('heading', attrs),
            () => commands.setParagraph(),
            (c) => c.setHeading(attrs)
          ),
    };
  },
});
