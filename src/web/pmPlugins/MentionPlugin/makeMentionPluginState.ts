import type { StateField } from '@tiptap/pm/state';
import { isCaretInBlockedContext } from './isCaretInBlockedContext';
import type { MentionPluginOptions, TriggerState } from './types';

export function makeMentionPluginState(
  getIndicators: MentionPluginOptions['getIndicators']
): StateField<TriggerState> {
  return {
    init(): TriggerState {
      return { active: false };
    },

    apply(_tr, _prev, _old, newEditorState): TriggerState {
      const { selection } = newEditorState;
      if (!selection.empty) return { active: false };

      const $from = selection.$from;
      if (isCaretInBlockedContext($from, newEditorState.schema))
        return { active: false };

      const blockStart = $from.start();
      const text = newEditorState.doc.textBetween(
        blockStart,
        $from.pos,
        '\n',
        '\n'
      );

      const mentionType = newEditorState.schema.marks.mention;
      const indicators = getIndicators();
      const found = findLastValidMentionIndicator(text, indicators, (idx) => {
        if (!mentionType) return false;
        const $at = newEditorState.doc.resolve(blockStart + idx + 1);
        return Boolean(mentionType.isInSet($at.marks()));
      });

      if (!found) return { active: false };

      const query = text.slice(found.indexInText + 1);

      // Native platforms end the trigger after two spaces in the query.
      if ((query.match(/ /g) ?? []).length >= 2) return { active: false };

      return {
        active: true,
        indicator: found.indicator,
        from: blockStart + found.indexInText,
        to: $from.pos,
        query,
      };
    },
  };
}

function findLastValidMentionIndicator(
  text: string,
  indicators: readonly string[],
  isIndicatorInsideFinalizedMention: (indexInText: number) => boolean
): { indexInText: number; indicator: string } | null {
  for (let idx = text.length - 1; idx >= 0; idx--) {
    const ch = text[idx];
    if (!ch || !indicators.includes(ch)) continue;

    const isAtStart = idx === 0;
    const isAfterSpace = idx > 0 && text[idx - 1] === ' ';
    if (!isAtStart && !isAfterSpace) continue;

    // Skip indicators inside a finalized mention
    if (isIndicatorInsideFinalizedMention(idx)) continue;

    return { indexInText: idx, indicator: ch };
  }

  return null;
}
