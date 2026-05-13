import type { HtmlStyle, MentionStyleProperties } from '../types';

export function isMentionStyleRecord(
  mentionStyle: HtmlStyle['mention']
): mentionStyle is Record<string, MentionStyleProperties> {
  if (
    mentionStyle &&
    typeof mentionStyle === 'object' &&
    !Array.isArray(mentionStyle)
  ) {
    const keys = Object.keys(mentionStyle);
    return (
      keys.length > 0 &&
      keys.every(
        (key) =>
          typeof (mentionStyle as Record<string, unknown>)[key] === 'object' &&
          (mentionStyle as Record<string, unknown>)[key] !== null
      )
    );
  }
  return false;
}
