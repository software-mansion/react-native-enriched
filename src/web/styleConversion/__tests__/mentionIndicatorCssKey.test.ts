import {
  indicatorToMentionCssKey,
  MENTION_STYLE_DEFAULT_KEY,
} from '../mentionIndicatorCssKey';

describe('indicatorToMentionCssKey', () => {
  it('maps default style key to default CSS key segment', () => {
    expect(indicatorToMentionCssKey(MENTION_STYLE_DEFAULT_KEY)).toBe('default');
  });

  it('encodes @ as Unicode code point', () => {
    expect(indicatorToMentionCssKey('@')).toBe('u0040');
  });

  it('encodes # as Unicode code point', () => {
    expect(indicatorToMentionCssKey('#')).toBe('u0023');
  });

  it('encodes empty string as u0000', () => {
    expect(indicatorToMentionCssKey('')).toBe('u0000');
  });
});
