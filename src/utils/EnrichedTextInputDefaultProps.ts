import type { TextShortcut } from '../types';

export const ENRICHED_TEXT_INPUT_DEFAULT_PROPS = {
  mentionIndicators: ['@'],
  editable: true,
  htmlStyle: {},
  autoCapitalize: 'sentences',
  scrollEnabled: true,
  androidExperimentalSynchronousEvents: false,
  useHtmlNormalizer: false,
  allowFontScaling: true,
  textShortcuts: [
    { trigger: '- ', style: 'unordered_list' },
    { trigger: '1. ', style: 'ordered_list' },
  ] as TextShortcut[],
} as const;
