import Italic from '@tiptap/extension-italic';

export const EnrichedItalic = Italic.extend({
  parseHTML() {
    return [{ tag: 'i' }];
  },
  renderHTML({ HTMLAttributes }) {
    return ['i', HTMLAttributes, 0];
  },
});
