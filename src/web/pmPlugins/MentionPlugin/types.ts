import type { OnChangeMentionEvent, OnMentionDetected } from '../../../types';

export type TriggerState =
  | { active: false }
  | {
      active: true;
      indicator: string;
      from: number;
      to: number;
      query: string;
    };

export interface MentionPluginOptions {
  getIndicators: () => string[];
}

export interface MentionCallbacks {
  onStartMention?: (indicator: string) => void;
  onChangeMention?: (e: OnChangeMentionEvent) => void;
  onEndMention?: (indicator: string) => void;
  onMentionDetected?: (e: OnMentionDetected) => void;
}
