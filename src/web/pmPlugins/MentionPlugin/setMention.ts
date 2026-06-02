import { Fragment } from '@tiptap/pm/model';
import type { EditorState } from '@tiptap/pm/state';
import type { Editor } from '@tiptap/react';
import { isCaretInBlockedContext } from './isCaretInBlockedContext';
import { mentionPluginKey } from './mentionPluginKey';

// Insert a mention mark at the current active trigger range.
export function setMention(
  editor: Editor,
  indicator: string,
  text: string,
  attributes?: Record<string, string>
): void {
  const { state } = editor;
  const triggerState = mentionPluginKey.getState(state);

  if (!triggerState?.active) {
    console.warn(
      '[EnrichedMention] setMention called but there is no active mention trigger'
    );
    return;
  }

  const mentionType = state.schema.marks.mention;
  if (!mentionType) return;

  const $from = state.selection.$from;
  if (isCaretInBlockedContext($from, state.schema)) {
    console.warn(
      '[EnrichedMention] setMention called but caret is inside a blocked context'
    );
    return;
  }

  const { from, to } = triggerState;

  const extendedTo = Math.max(
    to,
    exclusiveEndThroughMatchingMentionTail(state, from, text)
  );

  const mentionMark = mentionType.create({
    indicator,
    text,
    attributes: attributes ?? {},
  });
  const baseMarks = state.doc
    .resolve(from)
    .marks()
    .filter((m) => m.type.name !== 'mention');
  const fragment = Fragment.fromArray([
    state.schema.text(text, mentionMark.addToSet(baseMarks)),
    state.schema.text(' ', baseMarks),
  ]);

  editor
    .chain()
    .focus()
    .command(({ tr }) => {
      tr.replaceWith(from, extendedTo, fragment);
      return true;
    })
    .run();
}

// If the user moved the caret back into a partial match, extend `to` over the
// matching tail to avoid leftover characters after the inserted mention.
function exclusiveEndThroughMatchingMentionTail(
  state: EditorState,
  from: number,
  text: string
): number {
  const parentEnd = state.doc.resolve(from).end();
  let scanPos = from;
  for (const ch of text) {
    const end = scanPos + ch.length;
    if (end > parentEnd || state.doc.textBetween(scanPos, end, '') !== ch) {
      break;
    }
    scanPos = end;
  }
  return scanPos;
}
