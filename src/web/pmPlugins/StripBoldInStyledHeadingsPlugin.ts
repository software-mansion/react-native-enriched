import { Extension, type CommandProps } from '@tiptap/core';
import {
  Plugin,
  PluginKey,
  type EditorState,
  type Transaction,
} from '@tiptap/pm/state';
import type { HtmlStyle } from '../../types';
import { HEADING_TAGS } from '../formats/EnrichedHeading';

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    stripBoldInStyledHeadings: {
      // Remove redundant bold marks from headings whose level is already bold via `htmlStyle` CSS.
      normalizeBoldInStyledHeadings: () => ReturnType;
    };
  }
}

interface StripBoldInStyledHeadingsPluginOptions {
  getHtmlStyle: () => Required<HtmlStyle>;
}

function transactionStripBoldInCssBoldHeadings(
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

export const StripBoldInStyledHeadingsPlugin =
  Extension.create<StripBoldInStyledHeadingsPluginOptions>({
    name: 'stripBoldInStyledHeadings',
    addOptions() {
      return {
        getHtmlStyle: () => {
          throw new Error(
            'StripBoldInStyledHeadingsPlugin.configure({ getHtmlStyle }) is required'
          );
        },
      };
    },
    addCommands() {
      return {
        normalizeBoldInStyledHeadings:
          () =>
          ({ state, dispatch }: CommandProps) => {
            const htmlStyle = this.options.getHtmlStyle();
            const tr = transactionStripBoldInCssBoldHeadings(state, htmlStyle);
            if (!tr) return false;
            if (dispatch) dispatch(tr);
            return true;
          },
      };
    },
    addProseMirrorPlugins() {
      return [
        new Plugin({
          key: new PluginKey('stripBoldInStyledHeadings'),
          appendTransaction: (transactions, _oldState, newState) => {
            if (!transactions.some((tr) => tr.docChanged)) return;
            const htmlStyle = this.options.getHtmlStyle();

            return transactionStripBoldInCssBoldHeadings(newState, htmlStyle);
          },
        }),
      ];
    },
  });
