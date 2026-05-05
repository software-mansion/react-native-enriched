import {
  Mark,
  mergeAttributes,
  getMarkRange,
  getMarksBetween,
} from '@tiptap/core';
import { Fragment } from '@tiptap/pm/model';
import type { EditorView } from '@tiptap/pm/view';
import type { Editor } from '@tiptap/react';
import type { OnMentionDetected } from '../../types';
import { findEnrichedAtSuggestionMatch } from '../pmPlugins/enrichedAtSuggestionMatch';
import { isLinkBlocked } from './formatRules';

export const ENRICHED_MENTION_MARK_NAME = 'enrichedMention';

export const EnrichedMention = Mark.create({
  name: ENRICHED_MENTION_MARK_NAME,
  inclusive: false,
  excludes: 'link code',

  addAttributes() {
    return {
      canonicalText: {
        default: '',
      },
      indicator: {
        default: '@',
      },
      payload: {
        default: '{}',
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'mention',
        getAttrs: (element) => {
          if (typeof element === 'string') {
            return false;
          }
          const el = element as HTMLElement;
          const canonicalText = el.getAttribute('text') ?? '';
          const indicator = el.getAttribute('indicator') ?? '@';
          const payload: Record<string, string> = {};
          const { attributes } = el;
          for (let i = 0; i < attributes.length; i++) {
            const attr = attributes.item(i);
            if (!attr) continue;
            if (attr.name === 'text' || attr.name === 'indicator') continue;
            payload[attr.name] = attr.value;
          }
          return {
            canonicalText,
            indicator,
            payload: JSON.stringify(payload),
          };
        },
      },
    ];
  },

  renderHTML({ mark }) {
    const attrs: Record<string, string> = {
      text: mark.attrs.canonicalText as string,
      indicator: mark.attrs.indicator as string,
    };
    try {
      const extra = JSON.parse(mark.attrs.payload as string) as Record<
        string,
        string
      >;
      Object.assign(attrs, extra);
    } catch {
      // ignore invalid payload JSON
    }
    return ['mention', mergeAttributes(attrs), 0];
  },

  addKeyboardShortcuts() {
    return {};
  },
});

export function handleEnrichedMentionClick(
  view: EditorView,
  pos: number,
  event: MouseEvent,
  onMentionDetected?: (payload: OnMentionDetected) => void
): boolean {
  if (!onMentionDetected) return false;

  const mentionType = view.state.schema.marks[ENRICHED_MENTION_MARK_NAME];
  if (!mentionType) return false;

  const $pos = view.state.doc.resolve(pos);
  const range = getMarkRange($pos, mentionType);
  if (!range) return false;

  const entry = getMarksBetween(range.from, range.to, view.state.doc).find(
    (e) => e.mark.type === mentionType
  );
  if (!entry) return false;

  const mark = entry.mark;
  let attributes: Record<string, string> = {};
  try {
    attributes = JSON.parse(mark.attrs.payload as string) as Record<
      string,
      string
    >;
  } catch {
    attributes = {};
  }

  onMentionDetected({
    text: mark.attrs.canonicalText as string,
    indicator: mark.attrs.indicator as string,
    attributes,
  });
  event.preventDefault();
  return true;
}

export function insertEnrichedMentionAtSelection(
  editor: Editor,
  indicator: string,
  canonicalText: string,
  attributes?: Record<string, string>
): boolean {
  if (canonicalText.length === 0 || indicator !== '@') {
    return false;
  }
  if (isLinkBlocked(editor)) {
    return false;
  }

  const { state } = editor;
  const mentionType = state.schema.marks[ENRICHED_MENTION_MARK_NAME];
  if (!mentionType) return false;

  const payload = JSON.stringify(attributes ?? {});
  const mentionMark = mentionType.create({
    indicator,
    canonicalText,
    payload,
  });

  const atMatch = findEnrichedAtSuggestionMatch(state.selection.$from);
  const { from, to } =
    atMatch != null
      ? { from: atMatch.range.from, to: atMatch.range.to }
      : state.selection;

  const fragment = Fragment.fromArray([
    state.schema.text(canonicalText, [mentionMark]),
    state.schema.text(' '),
  ]);

  return editor
    .chain()
    .focus()
    .command(({ tr }) => {
      tr.replaceWith(from, to, fragment);
      return true;
    })
    .run();
}
