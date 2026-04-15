import { Extension } from '@tiptap/core';
import {
  Plugin,
  PluginKey,
  type EditorState,
  type Transaction,
} from '@tiptap/pm/state';
import type { HtmlStyle } from '../../types';
import { HEADING_TAGS } from '../formats/EnrichedHeading';

export function transactionStripBoldInCssBoldHeadings(
  state: EditorState,
  htmlStyle: Required<HtmlStyle>
): Transaction | null {
  const boldType = state.schema.marks.bold;
  if (!boldType) return null;

  const tr = state.tr;
  state.doc.descendants((node, pos) => {
    if (node.type.name !== 'heading') return true;
    const level = node.attrs.level as number;
    if (level < 1 || level > HEADING_TAGS.length) return false;
    const key = HEADING_TAGS[level - 1]!;
    if (htmlStyle[key].bold) {
      tr.removeMark(pos + 1, pos + node.nodeSize - 1, boldType);
    }
    return false;
  });

  return tr.steps.length > 0 ? tr : null;
}

// When htmlStyle says a heading level is bold via CSS, redundant bold marks must be stripped
export function createStripBoldInStyledHeadingsPlugin(htmlStyleRef: {
  current: Required<HtmlStyle>;
}) {
  return Extension.create({
    name: 'stripBoldInStyledHeadings',
    addProseMirrorPlugins() {
      return [
        new Plugin({
          key: new PluginKey('stripBoldInStyledHeadings'),
          appendTransaction: (transactions, _oldState, newState) => {
            if (!transactions.some((tr) => tr.docChanged)) return;

            return transactionStripBoldInCssBoldHeadings(
              newState,
              htmlStyleRef.current
            );
          },
        }),
      ];
    },
  });
}
