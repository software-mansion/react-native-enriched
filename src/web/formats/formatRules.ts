import type { Editor } from '@tiptap/core';
import type { HtmlStyle } from '../../types';
import { HEADING_LEVELS, HEADING_TAGS } from './EnrichedHeading';

type ChainedCommands = ReturnType<Editor['chain']>;

export function isAnyParagraphFormatActive(editor: Editor): boolean {
  return (
    editor.isActive('blockquote') ||
    editor.isActive('codeBlock') ||
    HEADING_LEVELS.some((level) => editor.isActive('heading', { level })) ||
    editor.isActive('orderedList') ||
    editor.isActive('unorderedList') ||
    editor.isActive('checkboxList')
  );
}

export function isLinkBlocked(editor: Editor): boolean {
  return editor.isActive('code') || editor.isActive('codeBlock');
}

export function isFormatBlocked(
  tiptapName: string,
  editor: Editor,
  htmlStyle: Required<HtmlStyle>
): boolean {
  if (tiptapName === 'link') {
    return isLinkBlocked(editor);
  }

  if (editor.isActive('codeBlock')) {
    return ['bold', 'italic', 'underline', 'strike', 'code'].includes(
      tiptapName
    );
  }
  for (const level of HEADING_LEVELS) {
    if (editor.isActive('heading', { level })) {
      const key = HEADING_TAGS[level - 1]!;
      if (tiptapName === 'bold' && htmlStyle[key].bold) return true;
    }
  }
  return false;
}

export function toggleParagraphFormat(
  isActive: () => boolean,
  deactivate: () => boolean,
  activate: (c: ChainedCommands) => ChainedCommands,
  chain: () => ChainedCommands
): boolean {
  if (isActive()) return deactivate();
  return activate(chain().clearNodes()).run();
}
