import Code from '@tiptap/extension-code';

export const EnrichedCode = Code.extend({
  // Allow code to combine with other marks (bold, italic, underline, strike).
  excludes: 'link',
  priority: 1000,
  addInputRules() {
    return [];
  },
  addKeyboardShortcuts() {
    return {};
  },
});
