import { Extension } from '@tiptap/core';
import { Plugin, PluginKey } from '@tiptap/pm/state';

export const StripMarksOnImagePlugin = Extension.create({
  name: 'stripMarksOnImage',

  addProseMirrorPlugins() {
    return [
      new Plugin({
        key: new PluginKey('stripMarksOnImage'),
        appendTransaction: (transactions, _oldState, newState) => {
          if (!transactions.some((tr) => tr.docChanged)) {
            return null;
          }

          const tr = newState.tr;
          let modified = false;

          newState.doc.descendants((node, pos) => {
            if (node.type.name === 'image' && node.marks.length > 0) {
              node.marks.forEach((mark) => {
                tr.removeMark(pos, pos + node.nodeSize, mark);
              });
              modified = true;
            }
          });

          return modified ? tr : null;
        },
      }),
    ];
  },
});
