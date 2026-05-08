import {
  findAutolinkRangesInWord,
  matchAutolink,
  prepareUrl,
} from './autolinkRegex';

describe('findAutolinkRangesInWord', () => {
  it('extracts embedded https URL without prefix junk', () => {
    const w = 'asdfhttps://www.example.com';
    const ranges = findAutolinkRangesInWord(w, undefined);
    expect(ranges).toHaveLength(1);
    expect(ranges[0]).toEqual({
      start: 4,
      endExclusive: w.length,
      text: 'https://www.example.com',
    });
    expect(prepareUrl(ranges[0]!.text)).toBe('https://www.example.com');
  });

  it('matches whole bare domain token', () => {
    const w = 'example.com';
    const ranges = findAutolinkRangesInWord(w, undefined);
    expect(ranges).toHaveLength(1);
    expect(ranges[0]?.text).toBe('example.com');
    expect(prepareUrl(ranges[0]!.text)).toBe('https://example.com');
  });

  it('supports custom regex with matchAll within word', () => {
    const re = /hello/gi;
    const ranges = findAutolinkRangesInWord('xHelloy', re);
    expect(ranges.some((r) => r.text === 'Hello')).toBe(true);
  });
});

describe('matchAutolink', () => {
  it('delegates to substring search', () => {
    expect(matchAutolink('asdfhttps://www.example.com', undefined)).toBe(true);
    expect(matchAutolink('zzz', undefined)).toBe(false);
  });
});
