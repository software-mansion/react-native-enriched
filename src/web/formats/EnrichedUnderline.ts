import Underline from '@tiptap/extension-underline';

export const EnrichedUnderline = Underline.extend({
  parseHTML() {
    return [{ tag: 'u' }];
  },
  renderHTML({ HTMLAttributes }) {
    return ['u', HTMLAttributes, 0];
  },
});
