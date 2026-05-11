const FULL_URL_REGEX =
  /https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_+.~#?&/=]*)/;
const WWW_REGEX =
  /www\.[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_+.~#?&/=]*)/;
const BARE_REGEX =
  /[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_+.~#?&/=]*)/;

/** Alternation (same as Android: left-most alternative wins per match). */
const DEFAULT_AUTOLINK_SUBSTRING_PATTERN = `(?:${FULL_URL_REGEX.source})|(?:${WWW_REGEX.source})|(?:${BARE_REGEX.source})`;

/**
 * Enables `matchAll` without treating the whole `\S+` token as the URL when
 * extra text is pasted in front (e.g. `asdfhttps://…`). Uses a fresh `RegExp`
 * per call — global regexes are stateful.
 */

export type AutolinkRangeInWord = {
  start: number;
  endExclusive: number;
  text: string;
};

function asGlobalRegex(re: RegExp): RegExp {
  return re.global
    ? re
    : new RegExp(re.source, `${re.flags.replace(/g/g, '')}g`);
}

/**
 * URL-like substrings inside a single whitespace-delimited token (`\S+`),
 * aligned with Android {@code regex.matcher(word).find()}.
 */
export function findAutolinkRangesInWord(
  word: string,
  linkRegex: RegExp | undefined
): readonly AutolinkRangeInWord[] {
  const re =
    linkRegex === undefined
      ? new RegExp(DEFAULT_AUTOLINK_SUBSTRING_PATTERN, 'gi')
      : asGlobalRegex(linkRegex);

  const out: AutolinkRangeInWord[] = [];
  for (const m of word.matchAll(re)) {
    const text = m[0] ?? '';
    if (text.length === 0 || m.index === undefined) continue;
    const start = m.index;
    out.push({
      start,
      endExclusive: start + text.length,
      text,
    });
  }
  return out;
}

export function matchAutolink(
  word: string,
  linkRegex: RegExp | undefined
): boolean {
  return findAutolinkRangesInWord(word, linkRegex).length > 0;
}

export function prepareUrl(word: string): string {
  if (/^https?:\/\//i.test(word)) return word;
  if (/^https?:/i.test(word)) {
    return `https://${word.replace(/^https?:/i, '')}`;
  }
  return `https://${word}`;
}
