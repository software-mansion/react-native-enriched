import { Extension } from '@tiptap/core';
import { Fragment } from '@tiptap/pm/model';
import { PluginKey } from '@tiptap/pm/state';
import { Suggestion } from '@tiptap/suggestion';
import type { OnChangeMentionEvent } from '../../types';
import { ENRICHED_MENTION_MARK_NAME } from '../formats/EnrichedMention';
import { enrichedAtSuggestionMatchOpts } from './enrichedAtSuggestionMatch';

/** TipTap suggestion item shape (keyboard pick); host UI uses `setMention` instead. */
interface AtSuggestionItem {
  id: string;
  label: string;
}

export interface AtSuggestionLifecycleCallbacks {
  onStartMention?: (indicator: string) => void;
  onChangeMention?: (e: OnChangeMentionEvent) => void;
  onEndMention?: (indicator: string) => void;
}

export const enrichedAtSuggestionKey = new PluginKey('enrichedAtSuggestion');

/**
 * `@` suggestion plugin: fires the same lifecycle callbacks as native (`onStartMention`,
 * `onChangeMention`, `onEndMention`). Items are always empty — hosts filter data and
 * insert via `setMention`, matching the native API (no separate resolver prop).
 */
export function createAtSuggestionExtension(options: {
  callbacksRef: { current: AtSuggestionLifecycleCallbacks };
}): Extension {
  return Extension.create({
    name: 'atSuggestion',
    priority: 120,

    addProseMirrorPlugins() {
      return [
        Suggestion<AtSuggestionItem, AtSuggestionItem>({
          editor: this.editor,
          pluginKey: enrichedAtSuggestionKey,
          char: enrichedAtSuggestionMatchOpts.char,
          allowedPrefixes: [...enrichedAtSuggestionMatchOpts.allowedPrefixes],
          allowSpaces: enrichedAtSuggestionMatchOpts.allowSpaces,
          allowToIncludeChar: enrichedAtSuggestionMatchOpts.allowToIncludeChar,
          startOfLine: enrichedAtSuggestionMatchOpts.startOfLine,
          items: () => [],
          command: ({ editor, range, props }) => {
            const { state } = editor;
            const mentionType = state.schema.marks[ENRICHED_MENTION_MARK_NAME];
            if (!mentionType) {
              return;
            }

            const canonicalText = `@${props.label}`;
            const mentionMark = mentionType.create({
              indicator: '@',
              canonicalText,
              payload: JSON.stringify({ id: props.id }),
            });

            const fragment = Fragment.fromArray([
              state.schema.text(canonicalText, [mentionMark]),
              state.schema.text(' '),
            ]);

            editor
              .chain()
              .focus()
              .command(({ tr }) => {
                tr.replaceWith(range.from, range.to, fragment);
                return true;
              })
              .run();
          },
          render: () => {
            const cb = () => options.callbacksRef.current;

            return {
              onBeforeStart: () => {},
              onStart: () => cb().onStartMention?.('@'),
              onBeforeUpdate: () => {},
              onUpdate: (p) =>
                cb().onChangeMention?.({
                  indicator: '@',
                  text: p.query ?? '',
                }),
              onExit: () => cb().onEndMention?.('@'),
            };
          },
        }),
      ];
    },
  });
}
