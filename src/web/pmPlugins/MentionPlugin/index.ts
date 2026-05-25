import { Extension } from '@tiptap/core';
import { Slice } from '@tiptap/pm/model';
import { Plugin } from '@tiptap/pm/state';
import { makeMentionPluginState } from './makeMentionPluginState';
import { mentionPluginKey } from './mentionPluginKey';
import { removeMentionMarksIfSpansResized } from './removeMentionMarksIfSpansResized';
import { stripPartialMentionMarks } from './stripPartialMentionMarks';
import type { MentionPluginOptions, TriggerState } from './types';

export type { MentionPluginOptions, TriggerState } from './types';
export { mentionPluginKey } from './mentionPluginKey';
export { setMention } from './setMention';
export { startMention } from './startMention';
export { subscribeMentionEvents } from './subscribeMentionEvents';

export const MentionPlugin = Extension.create<MentionPluginOptions>({
  name: 'mentionTrigger',
  addOptions() {
    return {
      getIndicators: () => {
        throw new Error(
          'MentionPlugin.configure({ getIndicators }) is required'
        );
      },
    };
  },
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
        state: makeMentionPluginState(this.options.getIndicators),
        appendTransaction: removeMentionMarksIfSpansResized,
      }),
    ];
  },
});
