import type { Editor } from '@tiptap/core';
import type { HtmlStyle } from '../../types';
import { HEADING_LEVELS, HEADING_TAGS } from './EnrichedHeading';

type ChainedCommands = ReturnType<Editor['chain']>;

interface ConflictingParagraphFormat {
  isActive: (editor: Editor) => boolean;
  deactivate: (chain: ChainedCommands) => ChainedCommands;
}

const CONFLICTING_PARAGRAPH_FORMATS: ConflictingParagraphFormat[] = [
  {
    isActive: (editor) => editor.isActive('blockquote'),
    deactivate: (chain) => chain.lift('blockquote'),
  },
  {
    isActive: (editor) => editor.isActive('enrichedCodeBlock'),
    deactivate: (chain) => chain.lift('enrichedCodeBlock'),
  },
  {
    isActive: (editor) =>
      HEADING_LEVELS.some((level) => editor.isActive('heading', { level })),
    deactivate: (chain) => chain.setParagraph(),
  },
];

export function isAnyParagraphFormatActive(editor: Editor): boolean {
  return CONFLICTING_PARAGRAPH_FORMATS.some((f) => f.isActive(editor));
}

export function isFormatBlocked(
  tiptapName: string,
  editor: Editor,
  htmlStyle: Required<HtmlStyle>
): boolean {
  if (editor.isActive('enrichedCodeBlock')) {
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
  editor: Editor,
  chain: ChainedCommands,
  isActive: () => boolean,
  deactivate: () => boolean,
  activate: (c: ChainedCommands) => ChainedCommands
): boolean {
  if (isActive()) return deactivate();
  const conflict =
    CONFLICTING_PARAGRAPH_FORMATS.find((f) => f.isActive(editor)) ?? null;
  return activate(conflict ? conflict.deactivate(chain) : chain).run();
}
