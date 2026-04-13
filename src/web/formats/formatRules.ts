import type { Editor } from '@tiptap/core';
import { HEADING_LEVELS } from './EnrichedHeading';

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

const BLOCKING_MAP: Record<string, string[]> = {
  enrichedCodeBlock: ['bold', 'italic', 'underline', 'strike', 'code'],
};

export function isAnyParagraphFormatActive(editor: Editor): boolean {
  return CONFLICTING_PARAGRAPH_FORMATS.some((f) => f.isActive(editor));
}

export function isFormatBlocked(tiptapName: string, editor: Editor): boolean {
  return Object.entries(BLOCKING_MAP).some(
    ([blocker, blocked]) =>
      blocked.includes(tiptapName) && editor.isActive(blocker)
  );
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
