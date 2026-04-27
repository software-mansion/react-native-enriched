import { Extension } from '@tiptap/core';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import { canJoin } from '@tiptap/pm/transform';

const MERGEABLE_TYPE_NAMES = new Set([
  'blockquote',
  'codeBlock',
  'unorderedList',
  'orderedList',
  'checkboxList',
]);

export const MergeAdjacentSameKindBlocksPlugin = Extension.create({
  name: 'mergeAdjacentSameKindBlocks',

  addProseMirrorPlugins() {
    return [
      new Plugin({
        key: new PluginKey('mergeAdjacentSameKindBlocks'),
        appendTransaction: (transactions, _oldState, newState) => {
          if (!transactions.some((t) => t.docChanged)) {
            return;
          }

          const tr = newState.tr;
          const joinPositions: number[] = [];

          newState.doc.descendants((node, pos) => {
            if (!MERGEABLE_TYPE_NAMES.has(node.type.name)) {
              return true;
            }

            const boundaryPos = pos + node.nodeSize;
            const $pos = newState.doc.resolve(boundaryPos);
            const after = $pos.nodeAfter;
            if (after && after.type === node.type) {
              joinPositions.push(boundaryPos);
            }
            return true;
          });

          let hasMerged = false;
          joinPositions
            .sort((a, b) => b - a)
            .forEach((pos) => {
              if (canJoin(tr.doc, pos)) {
                tr.join(pos);
                hasMerged = true;
              }
            });

          return hasMerged ? tr : undefined;
        },
      }),
    ];
  },
});
