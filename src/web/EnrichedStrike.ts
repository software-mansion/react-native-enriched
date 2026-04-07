import Strike from '@tiptap/extension-strike';

export const EnrichedStrike = Strike.extend({
  parseHTML() {
    return [{ tag: 's' }];
  },
  renderHTML({ HTMLAttributes }) {
    return ['s', HTMLAttributes, 0];
  },
});
