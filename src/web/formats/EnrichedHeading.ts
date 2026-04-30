import Heading from '@tiptap/extension-heading';
import { toggleParagraphFormat } from './formatRules';

export const HEADING_LEVELS = [1, 2, 3, 4, 5, 6] as const;

export type HeadingTag = `h${(typeof HEADING_LEVELS)[number]}`;

export const HEADING_TAGS = HEADING_LEVELS.map(
  (n) => `h${n}` as HeadingTag
) as readonly HeadingTag[];

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
            () => editor.isActive('heading', attrs),
            () => commands.setParagraph(),
            (c) => c.setHeading(attrs),
            chain
          ),
    };
  },
});
