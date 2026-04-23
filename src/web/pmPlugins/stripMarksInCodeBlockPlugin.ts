import { Extension } from '@tiptap/core';
import { Plugin, PluginKey } from '@tiptap/pm/state';

export const StripMarksInCodeBlockPlugin = Extension.create({
  name: 'stripMarksInCodeBlock',

  addProseMirrorPlugins() {
    return [
      new Plugin({
        key: new PluginKey('stripMarksInCodeBlock'),
        appendTransaction: (transactions, _oldState, newState) => {
          if (!transactions.some((tr) => tr.docChanged)) return;

          const tr = newState.tr;

          const allMarks = Object.values(newState.schema.marks);

          newState.doc.descendants((node, pos) => {
            if (node.type.name === 'codeBlock') {
              allMarks.forEach((markType) => {
                tr.removeMark(pos + 1, pos + node.nodeSize - 1, markType);
              });
              return false;
            }

            return true;
          });

          return tr.steps.length > 0 ? tr : null;
        },
      }),
    ];
  },
});
