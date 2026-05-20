import type { ReturnKeyTypeOptions } from 'react-native';

// Keywords for the HTML global [`enterkeyhint`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/enterkeyhint) attribute
export type EnterKeyHint =
  | 'enter'
  | 'done'
  | 'go'
  | 'next'
  | 'previous'
  | 'search'
  | 'send';

// Maps React Native `returnKeyType` to the HTML global `enterkeyhint` attribute
// if possible, otherwise falls back to enter.
export function returnKeyTypeToEnterKeyHint(
  returnKeyType: ReturnKeyTypeOptions | undefined
): EnterKeyHint {
  switch (returnKeyType) {
    case 'done':
    case 'go':
    case 'next':
    case 'previous':
    case 'search':
    case 'send':
      return returnKeyType;
    default:
      return 'enter';
  }
}
