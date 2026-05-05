import type { ResolvedPos } from '@tiptap/pm/model';
import { findSuggestionMatch } from '@tiptap/suggestion';

/** Mirrors TipTap Suggestion defaults: `@` works at fragment start or after a space (e.g. after another mention). */
export const ENRICHED_AT_SUGGESTION_CHAR = '@' as const;

export const enrichedAtSuggestionMatchOpts = {
  char: ENRICHED_AT_SUGGESTION_CHAR,
  allowSpaces: true,
  allowToIncludeChar: false,
  allowedPrefixes: [' '],
  startOfLine: false,
} as const;

export function findEnrichedAtSuggestionMatch($position: ResolvedPos) {
  return findSuggestionMatch({
    char: enrichedAtSuggestionMatchOpts.char,
    allowSpaces: enrichedAtSuggestionMatchOpts.allowSpaces,
    allowToIncludeChar: enrichedAtSuggestionMatchOpts.allowToIncludeChar,
    allowedPrefixes: [...enrichedAtSuggestionMatchOpts.allowedPrefixes],
    startOfLine: enrichedAtSuggestionMatchOpts.startOfLine,
    $position,
  });
}
