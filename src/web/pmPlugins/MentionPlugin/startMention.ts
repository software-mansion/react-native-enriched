import type { Editor } from '@tiptap/react';

export function startMention(
  editor: Editor,
  indicator: string,
  indicators: string[]
): void {
  if (!indicators.includes(indicator)) {
    console.warn(
      `[EnrichedMention] startMention: "${indicator}" is not in mentionIndicators`
    );
  }
  editor.chain().focus().insertContent(indicator).run();
}
