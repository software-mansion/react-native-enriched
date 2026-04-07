import Bold from '@tiptap/extension-bold';

export const EnrichedBold = Bold.extend({
  parseHTML() {
    return [{ tag: 'b' }];
  },
  renderHTML({ HTMLAttributes }) {
    return ['b', HTMLAttributes, 0];
  },
});
