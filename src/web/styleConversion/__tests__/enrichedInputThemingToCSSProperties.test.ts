import type { CSSProperties } from 'react';
import { enrichedInputThemingToCSSProperties } from '../enrichedInputThemingToCSSProperties';

describe('enrichedInputThemingToCSSProperties', () => {
  it('returns an empty object when no colors are passed', () => {
    expect(enrichedInputThemingToCSSProperties({})).toEqual({});
  });

  it('maps theme props to caretColor and CSS variables', () => {
    expect(
      enrichedInputThemingToCSSProperties({
        cursorColor: '#111',
        placeholderTextColor: '#222',
        selectionColor: '#333',
      })
    ).toEqual({
      'caretColor': '#111',
      '--eti-placeholder-text-color': '#222',
      '--eti-selection-color': '#333',
    } as CSSProperties);
  });
});
