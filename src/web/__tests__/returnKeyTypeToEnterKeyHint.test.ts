import { returnKeyTypeToEnterKeyHint } from '../returnKeyTypeToEnterKeyHint';

describe('returnKeyTypeToEnterKeyHint', () => {
  test.each([
    [undefined, 'enter'],
    ['default', 'enter'],
    ['done', 'done'],
    ['go', 'go'],
    ['next', 'next'],
    ['previous', 'previous'],
    ['search', 'search'],
    ['send', 'send'],
    ['google', 'enter'],
    ['yahoo', 'enter'],
  ] as const)('%j → %s', (input, expected) => {
    expect(returnKeyTypeToEnterKeyHint(input)).toBe(expected);
  });
});
