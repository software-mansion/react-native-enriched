import Heading from '@tiptap/extension-heading';

export const EnrichedHeading = Heading.configure({
  levels: [1, 2, 3, 4, 5, 6],
}).extend({
  addKeyboardShortcuts() {
    return {};
  },
  addInputRules() {
    return [];
  },
});
