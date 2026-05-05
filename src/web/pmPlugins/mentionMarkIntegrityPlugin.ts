import { Extension } from '@tiptap/core';
import { Mark } from '@tiptap/pm/model';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import { ENRICHED_MENTION_MARK_NAME } from '../formats/EnrichedMention';

export const mentionMarkIntegrityKey = new PluginKey('mentionMarkIntegrity');

export const MentionMarkIntegrityPlugin = Extension.create({
  name: 'mentionMarkIntegrity',
  priority: 1100,

  addProseMirrorPlugins() {
    const mentionTypeName = ENRICHED_MENTION_MARK_NAME;

    return [
      new Plugin({
        key: mentionMarkIntegrityKey,
        appendTransaction(transactions, _oldState, newState) {
          if (!transactions.some((tr) => tr.docChanged)) {
            return null;
          }

          const mentionType = newState.schema.marks[mentionTypeName];
          if (!mentionType) return null;

          type Run = {
            from: number;
            to: number;
            mark: Mark;
            text: string;
          };

          let current: Run | null = null;
          const tr = newState.tr;

          const flush = () => {
            if (!current) return;
            const canonical = current.mark.attrs.canonicalText as string;
            if (current.text !== canonical) {
              tr.removeMark(current.from, current.to, mentionType);
            }
            current = null;
          };

          newState.doc.descendants((node, pos) => {
            if (!node.isText) {
              flush();
              return;
            }

            const mark = node.marks.find((m) => m.type === mentionType);
            if (!mark) {
              flush();
              return;
            }

            const from = pos;
            const to = pos + node.nodeSize;
            const slice = node.text ?? '';

            if (!current || !current.mark.eq(mark) || current.to !== from) {
              flush();
              current = { from, to, mark, text: slice };
            } else {
              current.to = to;
              current.text += slice;
            }
          });

          flush();

          return tr.steps.length > 0 ? tr : null;
        },
      }),
    ];
  },
});
