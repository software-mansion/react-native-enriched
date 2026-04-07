import Code from '@tiptap/extension-code';

export const EnrichedCode = Code.extend({
  // Allow code to combine with other marks (bold, italic, underline, strike).
  excludes: '',
  priority: 1000,
});
