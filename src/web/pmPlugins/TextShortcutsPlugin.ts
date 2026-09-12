import { Extension, type Editor } from '@tiptap/core';
import type { MarkType, Node } from '@tiptap/pm/model';
import { Plugin, PluginKey, TextSelection } from '@tiptap/pm/state';
import type { EditorView } from '@tiptap/pm/view';
import type { TextShortcut, TextShortcutStyle, HtmlStyle } from '../../types';
import {
  getCurrentAlignment,
  isAnyParagraphFormatActive,
  isFormatBlocked,
} from '../formats/formatRules';

export interface TextShortcutsPluginOptions {
  getTextShortcuts: () => TextShortcut[];
  getHtmlStyle: () => Required<HtmlStyle>;
}

const INLINE_STYLES = new Set<TextShortcutStyle>([
  'bold',
  'italic',
  'underline',
  'strikethrough',
  'inline_code',
]);

const ALIGNMENT_STYLES = new Set<TextShortcutStyle>([
  'left',
  'center',
  'right',
  'justify',
]);

// Maps every TextShortcutStyle to its corresponding TipTap extension name.
const TIPTAP_NAME: Record<TextShortcutStyle, string> = {
  bold: 'bold',
  italic: 'italic',
  underline: 'underline',
  strikethrough: 'strike',
  inline_code: 'code',
  h1: 'heading',
  h2: 'heading',
  h3: 'heading',
  h4: 'heading',
  h5: 'heading',
  h6: 'heading',
  blockquote: 'blockquote',
  codeblock: 'codeBlock',
  unordered_list: 'unorderedList',
  ordered_list: 'orderedList',
  checkbox_list: 'checkboxList',
  left: 'textAlign',
  center: 'textAlign',
  right: 'textAlign',
  justify: 'textAlign',
};

function applyParagraphCommand(style: string, editor: Editor): boolean {
  switch (style) {
    case 'h1':
      return editor.commands.toggleHeading({ level: 1 });
    case 'h2':
      return editor.commands.toggleHeading({ level: 2 });
    case 'h3':
      return editor.commands.toggleHeading({ level: 3 });
    case 'h4':
      return editor.commands.toggleHeading({ level: 4 });
    case 'h5':
      return editor.commands.toggleHeading({ level: 5 });
    case 'h6':
      return editor.commands.toggleHeading({ level: 6 });
    case 'blockquote':
      return editor.commands.toggleBlockquote();
    case 'codeblock':
      return editor.commands.toggleCodeBlock();
    case 'unordered_list':
      return editor.commands.toggleUnorderedList();
    case 'ordered_list':
      return editor.commands.toggleOrderedList();
    case 'checkbox_list':
      return editor.commands.toggleCheckboxList(false);
    case 'left':
    case 'center':
    case 'right':
    case 'justify':
      return editor.commands.setTextAlign(style);
    default:
      return false;
  }
}

/**
 * Returns the text content of the text block that
 * contains the given document position, along with the absolute start
 * position of that block's first character.
 */
function getBlockContext(
  doc: Node,
  pos: number
): { blockText: string; blockStart: number } | null {
  const $pos = doc.resolve(pos);

  if (!$pos.parent.isTextblock) return null;

  const blockStart = $pos.start();
  const blockEnd = $pos.end();

  // Use `leafText` so inline atom nodes (e.g. images) contribute a single
  // placeholder character, keeping string indices aligned with doc positions.
  const blockText = doc.textBetween(blockStart, blockEnd, undefined, '\ufffc');

  return { blockText, blockStart };
}

/**
 * Checks whether the opening delimiter found at paragraph-relative index
 * [delimIdx] is actually part of a longer inline trigger (e.g. `*` inside
 * `**`).
 */
function isDelimPartOfLongerTrigger(
  trigger: string,
  delimIdx: number,
  blockText: string,
  inlineShortcuts: TextShortcut[]
): boolean {
  const delimEnd = delimIdx + trigger.length;

  return inlineShortcuts.some(({ trigger: longerTrigger }) => {
    if (longerTrigger.length <= trigger.length) return false;
    if (!longerTrigger.endsWith(trigger)) return false;

    const longerStart = delimEnd - longerTrigger.length;

    return (
      longerStart >= 0 &&
      blockText.slice(longerStart, delimEnd) === longerTrigger
    );
  });
}

/**
 * Handles a paragraph-level shortcut (e.g. `"- "` → bullet list, `"# "` → H1).
 *
 * Fires only when the trigger is anchored at the very start of the current
 * text block and no paragraph style is already active on that block.
 * Alignment shortcuts are the exception: they may fire regardless of the
 * active paragraph style, as long as that alignment isn't already applied.
 */
function tryParagraphShortcut(
  view: EditorView,
  from: number,
  text: string,
  editor: Editor,
  shortcuts: TextShortcut[],
  htmlStyle: Required<HtmlStyle>
): boolean {
  const ctx = getBlockContext(view.state.doc, from);
  if (!ctx) return false;

  const { blockStart } = ctx;
  const offsetInBlock = from - blockStart;
  const anyParagraphFormatActive = isAnyParagraphFormatActive(editor);

  for (const { trigger, style } of shortcuts) {
    if (INLINE_STYLES.has(style)) continue;
    if (anyParagraphFormatActive && !ALIGNMENT_STYLES.has(style)) continue;
    if (!trigger) continue;

    const lastChar = trigger[trigger.length - 1]!;
    if (text !== lastChar) continue;

    const prefixLen = trigger.length - 1;

    // Trigger must be anchored at paragraph start
    if (offsetInBlock !== prefixLen) continue;

    // Verify the prefix characters already in the doc match the trigger prefix
    if (prefixLen > 0) {
      const docPrefix = view.state.doc.textBetween(blockStart, from);
      if (docPrefix !== trigger.slice(0, prefixLen)) continue;
    }

    if (ALIGNMENT_STYLES.has(style) && getCurrentAlignment(editor) === style)
      continue;
    if (isFormatBlocked(TIPTAP_NAME[style], editor, htmlStyle)) continue;

    const marksToPreserve = view.state.selection.$from.marks();

    // Delete the prefix that is already in the doc (the last char - text -
    // hasn't been inserted yet, so we only remove the prefix portion).
    const { tr } = view.state;
    if (prefixLen > 0) {
      tr.delete(blockStart, from);
    }
    view.dispatch(tr);

    if (marksToPreserve.length > 0) {
      view.dispatch(view.state.tr.setStoredMarks(marksToPreserve));
    }

    applyParagraphCommand(style, editor);
    return true;
  }

  return false;
}

/**
 * Handles an inline shortcut (e.g. `**text**` → bold).
 *
 * Inline shortcuts use symmetric delimiter pairs. When the closing delimiter
 * is completed, we search backwards for a matching opening delimiter and apply
 * the mark to the content between them, removing both delimiters.
 */
function tryInlineShortcut(
  view: EditorView,
  from: number,
  to: number,
  text: string,
  editor: Editor,
  shortcuts: TextShortcut[],
  htmlStyle: Required<HtmlStyle>
): boolean {
  const ctx = getBlockContext(view.state.doc, from);
  if (!ctx) return false;

  const { blockText, blockStart } = ctx;
  const offsetInBlock = from - blockStart;

  // Sort inline shortcuts longest-first so `**` is not pre-empted by `*`
  const inlineShortcuts = shortcuts
    .filter(
      ({ trigger, style }) => INLINE_STYLES.has(style) && trigger.length > 0
    )
    .sort((a, b) => b.trigger.length - a.trigger.length);

  for (const { trigger, style } of inlineShortcuts) {
    const markName = TIPTAP_NAME[style];
    if (markName === undefined) continue;

    const lastChar = trigger[trigger.length - 1]!;
    if (text !== lastChar) continue;

    // Verify the characters before the cursor complete the closing delimiter
    const prefixLen = trigger.length - 1;
    if (offsetInBlock < prefixLen) continue;

    if (prefixLen > 0) {
      const beforeCursor = blockText.slice(
        offsetInBlock - prefixLen,
        offsetInBlock
      );
      if (beforeCursor !== trigger.slice(0, prefixLen)) continue;
    }

    // Search backwards in the paragraph for an opening delimiter.
    // Only search up to where the closing prefix begins
    const searchIn = blockText.slice(0, offsetInBlock - prefixLen);
    const openIdx = searchIn.lastIndexOf(trigger);
    if (openIdx < 0) continue;

    if (
      isDelimPartOfLongerTrigger(trigger, openIdx, blockText, inlineShortcuts)
    ) {
      continue;
    }

    const contentStart = openIdx + trigger.length;
    const closeDelimPrefixStart = offsetInBlock - prefixLen;

    if (closeDelimPrefixStart <= contentStart) continue;

    if (isFormatBlocked(markName, editor, htmlStyle)) continue;

    const markType: MarkType | undefined = view.state.schema.marks[markName];
    if (!markType) continue;

    // Convert paragraph-relative indices to absolute doc positions
    const openDocStart = blockStart + openIdx;
    const contentDocStart = blockStart + contentStart;
    const closeDelimPrefixDocStart = blockStart + closeDelimPrefixStart;

    const { tr } = view.state;

    // delete closing delimiter
    tr.delete(closeDelimPrefixDocStart, to);

    // delete opening delimiter
    tr.delete(openDocStart, openDocStart + trigger.length);

    // mark the content
    const contentLength = closeDelimPrefixDocStart - contentDocStart;
    const finalStart = openDocStart;
    const finalEnd = openDocStart + contentLength;
    tr.addMark(finalStart, finalEnd, markType.create());

    // place cursor at end of content
    tr.setSelection(TextSelection.create(tr.doc, finalEnd));

    view.dispatch(tr);
    view.dispatch(view.state.tr.removeStoredMark(markType));
    return true;
  }

  return false;
}

export const TextShortcutsPlugin = Extension.create<TextShortcutsPluginOptions>(
  {
    name: 'textShortcutsPlugin',

    addOptions() {
      return {
        getTextShortcuts: () => [],
        getHtmlStyle: () => {
          throw new Error(
            'TextShortcutsPlugin.configure({ getHtmlStyle }) is required'
          );
        },
      };
    },

    addProseMirrorPlugins() {
      const getTextShortcuts = () => this.options.getTextShortcuts();
      const getHtmlStyle = () => this.options.getHtmlStyle();
      const getEditor = () => this.editor;

      return [
        new Plugin({
          key: new PluginKey('textShortcuts'),
          props: {
            handleTextInput(
              view: EditorView,
              from: number,
              to: number,
              text: string
            ): boolean {
              if (!view.editable) return false;

              const shortcuts = getTextShortcuts();
              if (shortcuts.length === 0) return false;

              const editor = getEditor();
              const htmlStyle = getHtmlStyle();

              return (
                tryParagraphShortcut(
                  view,
                  from,
                  text,
                  editor,
                  shortcuts,
                  htmlStyle
                ) ||
                tryInlineShortcut(
                  view,
                  from,
                  to,
                  text,
                  editor,
                  shortcuts,
                  htmlStyle
                )
              );
            },
          },
        }),
      ];
    },
  }
);
