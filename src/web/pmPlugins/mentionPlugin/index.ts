import { Extension } from '@tiptap/core';
import { Slice } from '@tiptap/pm/model';
import { Plugin } from '@tiptap/pm/state';
import { makeMentionPluginState } from './makeMentionPluginState';
import { mentionPluginKey } from './mentionPluginKey';
import { removeMentionMarksIfSpanLengthChanged } from './removeMentionMarksIfSpansResized';
import { stripPartialMentionMarks } from './stripPartialMentionMarks';
import type { MentionPluginOptions, TriggerState } from './types';

export type { MentionPluginOptions, TriggerState } from './types';
export { mentionPluginKey } from './mentionPluginKey';
export { setMention } from './setMention';
export { startMention } from './startMention';
export { subscribeMentionEvents } from './subscribeMentionEvents';

export function createMentionPlugin(options: MentionPluginOptions): Extension {
  return Extension.create({
    name: 'mentionTrigger',
    addProseMirrorPlugins() {
      return [
        new Plugin<TriggerState>({
          key: mentionPluginKey,
          props: {
            transformPasted(slice: Slice): Slice {
              return new Slice(
                stripPartialMentionMarks(slice.content),
                slice.openStart,
                slice.openEnd
              );
            },
          },
          state: makeMentionPluginState(options),
          appendTransaction: removeMentionMarksIfSpanLengthChanged,
        }),
      ];
    },
  });
}
