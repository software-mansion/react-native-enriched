import { findParentNodeClosestToPos } from '@tiptap/core';
import type { ResolvedPos, Schema } from '@tiptap/pm/model';
import { EXCLUDED_MARKS as EXCLUDED_MARKS_BY_MENTION } from '../../formats/EnrichedMention';

export function isCaretInBlockedContext(
  $from: ResolvedPos,
  schema: Schema
): boolean {
  for (const excludedMark of EXCLUDED_MARKS_BY_MENTION) {
    if (schema.marks[excludedMark]?.isInSet($from.marks())) return true;
  }

  return (
    findParentNodeClosestToPos($from, (n) => n.type.name === 'codeBlock') !=
    null
  );
}
