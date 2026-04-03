import type { CSSProperties } from 'react';
import type { EnrichedInputStyle } from '../../types';
import { enrichedInputStyleToCSSProperties } from '../enrichedInputStyleToCSSProperties';

function convert(style: EnrichedInputStyle): CSSProperties {
  return enrichedInputStyleToCSSProperties(style);
}

describe('empty input', () => {
  it('returns an empty object for an empty style', () => {
    expect(convert({})).toEqual({});
  });
});

describe('dimension value conversion', () => {
  const cases: Array<{
    description: string;
    input: EnrichedInputStyle;
    expected: CSSProperties;
  }> = [
    {
      description: 'numeric width becomes px string',
      input: { width: 100 },
      expected: { width: '100px' },
    },
    {
      description: 'percentage width passes through unchanged',
      input: { width: '50%' },
      expected: { width: '50%' },
    },
    {
      description: 'numeric height becomes px string',
      input: { height: 200 },
      expected: { height: '200px' },
    },
    {
      description: 'auto height passes through unchanged',
      input: { height: 'auto' },
      expected: { height: 'auto' },
    },
    {
      description: 'numeric minWidth becomes px string',
      input: { minWidth: 50 },
      expected: { minWidth: '50px' },
    },
    {
      description: 'numeric maxWidth becomes px string',
      input: { maxWidth: 300 },
      expected: { maxWidth: '300px' },
    },
    {
      description: 'numeric minHeight becomes px string',
      input: { minHeight: 40 },
      expected: { minHeight: '40px' },
    },
    {
      description: 'numeric maxHeight becomes px string',
      input: { maxHeight: 400 },
      expected: { maxHeight: '400px' },
    },
    {
      description: 'numeric top becomes px string',
      input: { top: 10 },
      expected: { top: '10px' },
    },
    {
      description: 'numeric bottom becomes px string',
      input: { bottom: 20 },
      expected: { bottom: '20px' },
    },
    {
      description: 'numeric left becomes px string',
      input: { left: 5 },
      expected: { left: '5px' },
    },
    {
      description: 'numeric right becomes px string',
      input: { right: 15 },
      expected: { right: '15px' },
    },
    {
      description: 'numeric inset becomes px string',
      input: { inset: 8 },
      expected: { inset: '8px' },
    },
    {
      description: 'percentage inset passes through unchanged',
      input: { inset: '10%' },
      expected: { inset: '10%' },
    },
  ];

  it.each(cases)('$description', ({ input, expected }) => {
    expect(convert(input)).toEqual(expected);
  });
});

describe('marginHorizontal / marginVertical shorthands', () => {
  const cases: Array<{
    description: string;
    input: EnrichedInputStyle;
    expected: CSSProperties;
  }> = [
    {
      description:
        'marginHorizontal number expands to marginLeft + marginRight',
      input: { marginHorizontal: 16 },
      expected: { marginLeft: '16px', marginRight: '16px' },
    },
    {
      description:
        'marginHorizontal string expands to marginLeft + marginRight',
      input: { marginHorizontal: 'auto' },
      expected: { marginLeft: 'auto', marginRight: 'auto' },
    },
    {
      description: 'marginVertical number expands to marginTop + marginBottom',
      input: { marginVertical: 8 },
      expected: { marginTop: '8px', marginBottom: '8px' },
    },
    {
      description: 'marginVertical string expands to marginTop + marginBottom',
      input: { marginVertical: '5%' },
      expected: { marginTop: '5%', marginBottom: '5%' },
    },
    {
      description: 'both marginHorizontal and marginVertical expand correctly',
      input: { marginHorizontal: 16, marginVertical: 8 },
      expected: {
        marginLeft: '16px',
        marginRight: '16px',
        marginTop: '8px',
        marginBottom: '8px',
      },
    },
  ];

  it.each(cases)('$description', ({ input, expected }) => {
    expect(convert(input)).toEqual(expected);
  });

  it('marginHorizontal is not present in output', () => {
    expect(convert({ marginHorizontal: 16 })).not.toHaveProperty(
      'marginHorizontal'
    );
  });

  it('marginVertical is not present in output', () => {
    expect(convert({ marginVertical: 8 })).not.toHaveProperty('marginVertical');
  });
});

describe('paddingHorizontal / paddingVertical shorthands', () => {
  const cases: Array<{
    description: string;
    input: EnrichedInputStyle;
    expected: CSSProperties;
  }> = [
    {
      description:
        'paddingHorizontal number expands to paddingLeft + paddingRight',
      input: { paddingHorizontal: 12 },
      expected: { paddingLeft: '12px', paddingRight: '12px' },
    },
    {
      description:
        'paddingHorizontal string expands to paddingLeft + paddingRight',
      input: { paddingHorizontal: '10%' },
      expected: { paddingLeft: '10%', paddingRight: '10%' },
    },
    {
      description:
        'paddingVertical number expands to paddingTop + paddingBottom',
      input: { paddingVertical: 4 },
      expected: { paddingTop: '4px', paddingBottom: '4px' },
    },
    {
      description:
        'paddingVertical string expands to paddingTop + paddingBottom',
      input: { paddingVertical: '2%' },
      expected: { paddingTop: '2%', paddingBottom: '2%' },
    },
    {
      description:
        'both paddingHorizontal and paddingVertical expand correctly',
      input: { paddingHorizontal: 12, paddingVertical: 4 },
      expected: {
        paddingLeft: '12px',
        paddingRight: '12px',
        paddingTop: '4px',
        paddingBottom: '4px',
      },
    },
  ];

  it.each(cases)('$description', ({ input, expected }) => {
    expect(convert(input)).toEqual(expected);
  });

  it('paddingHorizontal is not present in output', () => {
    expect(convert({ paddingHorizontal: 12 })).not.toHaveProperty(
      'paddingHorizontal'
    );
  });

  it('paddingVertical is not present in output', () => {
    expect(convert({ paddingVertical: 4 })).not.toHaveProperty(
      'paddingVertical'
    );
  });
});

describe('shorthand vs specific precedence (RN behavior: specific wins)', () => {
  it('marginLeft overrides marginHorizontal', () => {
    expect(convert({ marginHorizontal: 20, marginLeft: 10 })).toMatchObject({
      marginLeft: '10px',
      marginRight: '20px',
    });
  });

  it('marginRight overrides marginHorizontal', () => {
    expect(convert({ marginHorizontal: 20, marginRight: 5 })).toMatchObject({
      marginLeft: '20px',
      marginRight: '5px',
    });
  });

  it('marginTop overrides marginVertical', () => {
    expect(convert({ marginVertical: 16, marginTop: 4 })).toMatchObject({
      marginTop: '4px',
      marginBottom: '16px',
    });
  });

  it('marginBottom overrides marginVertical', () => {
    expect(convert({ marginVertical: 16, marginBottom: 0 })).toMatchObject({
      marginTop: '16px',
      marginBottom: '0px',
    });
  });

  it('paddingLeft overrides paddingHorizontal', () => {
    expect(convert({ paddingHorizontal: 12, paddingLeft: 4 })).toMatchObject({
      paddingLeft: '4px',
      paddingRight: '12px',
    });
  });

  it('paddingTop overrides paddingVertical', () => {
    expect(convert({ paddingVertical: 8, paddingTop: 2 })).toMatchObject({
      paddingTop: '2px',
      paddingBottom: '8px',
    });
  });
});

describe('logical property mapping', () => {
  const cases: Array<{
    description: string;
    input: EnrichedInputStyle;
    expected: CSSProperties;
  }> = [
    {
      description: 'start maps to insetInlineStart',
      input: { start: 10 },
      expected: { insetInlineStart: '10px' },
    },
    {
      description: 'end maps to insetInlineEnd',
      input: { end: 20 },
      expected: { insetInlineEnd: '20px' },
    },
    {
      description: 'marginStart maps to marginInlineStart',
      input: { marginStart: 8 },
      expected: { marginInlineStart: '8px' },
    },
    {
      description: 'marginEnd maps to marginInlineEnd',
      input: { marginEnd: 8 },
      expected: { marginInlineEnd: '8px' },
    },
    {
      description: 'paddingStart maps to paddingInlineStart',
      input: { paddingStart: 6 },
      expected: { paddingInlineStart: '6px' },
    },
    {
      description: 'paddingEnd maps to paddingInlineEnd',
      input: { paddingEnd: 6 },
      expected: { paddingInlineEnd: '6px' },
    },
    {
      description: 'borderStartWidth maps to borderInlineStartWidth',
      input: { borderStartWidth: 2 },
      expected: { borderInlineStartWidth: '2px', borderStyle: 'solid' },
    },
    {
      description: 'borderEndWidth maps to borderInlineEndWidth',
      input: { borderEndWidth: 2 },
      expected: { borderInlineEndWidth: '2px', borderStyle: 'solid' },
    },
  ];

  it.each(cases)('$description', ({ input, expected }) => {
    expect(convert(input)).toEqual(expected);
  });

  it.each([
    ['start', { start: 10 }],
    ['end', { end: 10 }],
    ['marginStart', { marginStart: 8 }],
    ['marginEnd', { marginEnd: 8 }],
    ['paddingStart', { paddingStart: 6 }],
    ['paddingEnd', { paddingEnd: 6 }],
    ['borderStartWidth', { borderStartWidth: 2 }],
    ['borderEndWidth', { borderEndWidth: 2 }],
  ])('source key %s is not present in output', (key, input) => {
    expect(convert(input)).not.toHaveProperty(key);
  });
});

describe('direct margin and padding properties', () => {
  const cases: Array<{
    description: string;
    input: EnrichedInputStyle;
    expected: CSSProperties;
  }> = [
    {
      description: 'margin number → px string',
      input: { margin: 16 },
      expected: { margin: '16px' },
    },
    {
      description: 'marginTop number → px string',
      input: { marginTop: 8 },
      expected: { marginTop: '8px' },
    },
    {
      description: 'marginBottom number → px string',
      input: { marginBottom: 8 },
      expected: { marginBottom: '8px' },
    },
    {
      description: 'marginLeft number → px string',
      input: { marginLeft: 4 },
      expected: { marginLeft: '4px' },
    },
    {
      description: 'marginRight number → px string',
      input: { marginRight: 4 },
      expected: { marginRight: '4px' },
    },
    {
      description: 'padding number → px string',
      input: { padding: 12 },
      expected: { padding: '12px' },
    },
    {
      description: 'paddingTop number → px string',
      input: { paddingTop: 6 },
      expected: { paddingTop: '6px' },
    },
    {
      description: 'paddingBottom number → px string',
      input: { paddingBottom: 6 },
      expected: { paddingBottom: '6px' },
    },
    {
      description: 'paddingLeft number → px string',
      input: { paddingLeft: 3 },
      expected: { paddingLeft: '3px' },
    },
    {
      description: 'paddingRight number → px string',
      input: { paddingRight: 3 },
      expected: { paddingRight: '3px' },
    },
  ];

  it.each(cases)('$description', ({ input, expected }) => {
    expect(convert(input)).toEqual(expected);
  });
});

describe('border width properties', () => {
  const cases: Array<{
    description: string;
    input: EnrichedInputStyle;
    expected: CSSProperties;
  }> = [
    {
      description: 'borderWidth number → px string',
      input: { borderWidth: 1 },
      expected: { borderWidth: '1px', borderStyle: 'solid' },
    },
    {
      description: 'borderTopWidth number → px string',
      input: { borderTopWidth: 2 },
      expected: { borderTopWidth: '2px', borderStyle: 'solid' },
    },
    {
      description: 'borderBottomWidth number → px string',
      input: { borderBottomWidth: 2 },
      expected: { borderBottomWidth: '2px', borderStyle: 'solid' },
    },
    {
      description: 'borderLeftWidth number → px string',
      input: { borderLeftWidth: 1 },
      expected: { borderLeftWidth: '1px', borderStyle: 'solid' },
    },
    {
      description: 'borderRightWidth number → px string',
      input: { borderRightWidth: 1 },
      expected: { borderRightWidth: '1px', borderStyle: 'solid' },
    },
  ];

  it.each(cases)('$description', ({ input, expected }) => {
    expect(convert(input)).toEqual(expected);
  });
});

describe('number-only properties (no px suffix)', () => {
  const cases: Array<{
    description: string;
    input: EnrichedInputStyle;
    expected: CSSProperties;
  }> = [
    {
      description: 'flex passes through as number',
      input: { flex: 1 },
      expected: { flex: 1 },
    },
    {
      description: 'flexGrow passes through as number',
      input: { flexGrow: 2 },
      expected: { flexGrow: 2 },
    },
    {
      description: 'flexShrink passes through as number',
      input: { flexShrink: 0 },
      expected: { flexShrink: 0 },
    },
    {
      description: 'zIndex passes through as number',
      input: { zIndex: 10 },
      expected: { zIndex: 10 },
    },
    {
      description: 'opacity passes through as number',
      input: { opacity: 0.5 },
      expected: { opacity: 0.5 },
    },
    {
      description: 'aspectRatio number passes through as number',
      input: { aspectRatio: 1.5 },
      expected: { aspectRatio: 1.5 },
    },
    {
      description: 'aspectRatio string passes through unchanged',
      input: { aspectRatio: '16/9' },
      expected: { aspectRatio: '16/9' },
    },
  ];

  it.each(cases)('$description', ({ input, expected }) => {
    expect(convert(input)).toEqual(expected);
  });
});

describe('typography properties', () => {
  const cases: Array<{
    description: string;
    input: EnrichedInputStyle;
    expected: CSSProperties;
  }> = [
    {
      description: 'color string passes through',
      input: { color: '#ff0000' },
      expected: { color: '#ff0000' },
    },
    {
      description: 'fontFamily passes through',
      input: { fontFamily: 'Inter' },
      expected: { fontFamily: 'Inter' },
    },
    {
      description: 'fontSize number → px string',
      input: { fontSize: 16 },
      expected: { fontSize: '16px' },
    },
    {
      description: 'fontStyle passes through',
      input: { fontStyle: 'italic' },
      expected: { fontStyle: 'italic' },
    },
    {
      description: 'fontWeight string passes through',
      input: { fontWeight: 'bold' },
      expected: { fontWeight: 'bold' },
    },
    {
      description: 'fontWeight numeric string passes through',
      input: { fontWeight: '600' },
      expected: { fontWeight: '600' },
    },
    {
      description: 'lineHeight number → px string',
      input: { lineHeight: 24 },
      expected: { lineHeight: '24px' },
    },
    {
      description: 'letterSpacing number → px string',
      input: { letterSpacing: 1 },
      expected: { letterSpacing: '1px' },
    },
  ];

  it.each(cases)('$description', ({ input, expected }) => {
    expect(convert(input)).toEqual(expected);
  });
});

describe('view appearance properties', () => {
  const cases: Array<{
    description: string;
    input: EnrichedInputStyle;
    expected: CSSProperties;
  }> = [
    {
      description: 'backgroundColor passes through',
      input: { backgroundColor: 'rgba(0,0,0,0.5)' },
      expected: { backgroundColor: 'rgba(0,0,0,0.5)' },
    },
    {
      description: 'borderColor passes through',
      input: { borderColor: '#ccc' },
      expected: { borderColor: '#ccc', borderStyle: 'solid' },
    },
    {
      description: 'borderRadius number → px string',
      input: { borderRadius: 8 },
      expected: { borderRadius: '8px' },
    },
    {
      description: 'borderTopLeftRadius number → px string',
      input: { borderTopLeftRadius: 4 },
      expected: { borderTopLeftRadius: '4px' },
    },
    {
      description: 'borderTopRightRadius number → px string',
      input: { borderTopRightRadius: 4 },
      expected: { borderTopRightRadius: '4px' },
    },
    {
      description: 'borderBottomLeftRadius number → px string',
      input: { borderBottomLeftRadius: 4 },
      expected: { borderBottomLeftRadius: '4px' },
    },
    {
      description: 'borderBottomRightRadius number → px string',
      input: { borderBottomRightRadius: 4 },
      expected: { borderBottomRightRadius: '4px' },
    },
    {
      description: 'borderStyle passes through',
      input: { borderStyle: 'dashed' },
      expected: { borderStyle: 'dashed' },
    },
    {
      description: 'opacity passes through',
      input: { opacity: 0.8 },
      expected: { opacity: 0.8 },
    },
    {
      description: 'display none passes through',
      input: { display: 'none' },
      expected: { display: 'none' },
    },
    {
      description: 'display flex passes through',
      input: { display: 'flex' },
      expected: { display: 'flex' },
    },
    {
      description: 'cursor passes through',
      input: { cursor: 'pointer' },
      expected: { cursor: 'pointer' },
    },
    {
      description: 'pointerEvents passes through',
      input: { pointerEvents: 'none' },
      expected: { pointerEvents: 'none' },
    },
  ];

  it.each(cases)('$description', ({ input, expected }) => {
    expect(convert(input)).toEqual(expected);
  });
});

describe('boxShadow passthrough', () => {
  it('boxShadow string passes through unchanged', () => {
    expect(convert({ boxShadow: '0px 2px 4px rgba(0,0,0,0.3)' })).toEqual({
      boxShadow: '0px 2px 4px rgba(0,0,0,0.3)',
    });
  });

  it('ios-only shadow props are ignored on web', () => {
    const result = convert({
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 2 },
      shadowOpacity: 0.3,
      shadowRadius: 4,
    });
    expect(result).toEqual({});
  });

  it('elevation is ignored on web', () => {
    expect(convert({ elevation: 4 })).toEqual({});
  });
});

describe('flexBasis', () => {
  const cases: Array<{
    description: string;
    input: EnrichedInputStyle;
    expected: CSSProperties;
  }> = [
    {
      description: 'flexBasis number → px string',
      input: { flexBasis: 100 },
      expected: { flexBasis: '100px' },
    },
    {
      description: 'flexBasis auto passes through',
      input: { flexBasis: 'auto' },
      expected: { flexBasis: 'auto' },
    },
    {
      description: 'flexBasis percentage passes through',
      input: { flexBasis: '50%' },
      expected: { flexBasis: '50%' },
    },
  ];

  it.each(cases)('$description', ({ input, expected }) => {
    expect(convert(input)).toEqual(expected);
  });
});

describe('position', () => {
  const cases: Array<{
    description: string;
    input: EnrichedInputStyle;
    expected: CSSProperties;
  }> = [
    {
      description: 'position absolute passes through',
      input: { position: 'absolute' },
      expected: { position: 'absolute' },
    },
    {
      description: 'position relative passes through',
      input: { position: 'relative' },
      expected: { position: 'relative' },
    },
  ];

  it.each(cases)('$description', ({ input, expected }) => {
    expect(convert(input)).toEqual(expected);
  });
});

describe('alignSelf', () => {
  const cases: Array<{
    description: string;
    input: EnrichedInputStyle;
    expected: CSSProperties;
  }> = [
    {
      description: 'alignSelf center passes through',
      input: { alignSelf: 'center' },
      expected: { alignSelf: 'center' },
    },
    {
      description: 'alignSelf stretch passes through',
      input: { alignSelf: 'stretch' },
      expected: { alignSelf: 'stretch' },
    },
  ];

  it.each(cases)('$description', ({ input, expected }) => {
    expect(convert(input)).toEqual(expected);
  });
});

describe('boxSizing', () => {
  const cases: Array<{
    description: string;
    input: EnrichedInputStyle;
    expected: CSSProperties;
  }> = [
    {
      description: 'boxSizing border-box passes through',
      input: { boxSizing: 'border-box' },
      expected: { boxSizing: 'border-box' },
    },
    {
      description: 'boxSizing content-box passes through',
      input: { boxSizing: 'content-box' },
      expected: { boxSizing: 'content-box' },
    },
  ];

  it.each(cases)('$description', ({ input, expected }) => {
    expect(convert(input)).toEqual(expected);
  });
});

describe('transform property', () => {
  it('string transform passes through unchanged', () => {
    expect(convert({ transform: 'rotate(45deg)' })).toEqual({
      transform: 'rotate(45deg)',
    });
  });

  it('string transform with multiple functions passes through unchanged', () => {
    expect(
      convert({ transform: 'translateX(10px) scale(1.5) rotate(90deg)' })
    ).toEqual({ transform: 'translateX(10px) scale(1.5) rotate(90deg)' });
  });

  it('transform is omitted when not provided', () => {
    expect(convert({ width: 100 })).not.toHaveProperty('transform');
  });

  it('RN array transform is converted to CSS string', () => {
    expect(
      convert({ transform: [{ translateX: 10 }, { rotate: '45deg' }] })
    ).toEqual({ transform: 'translateX(10px) rotate(45deg)' });
  });

  it('single-item array transform', () => {
    expect(convert({ transform: [{ scale: 1.5 }] })).toEqual({
      transform: 'scale(1.5)',
    });
  });

  it('all numeric transform functions get px suffix', () => {
    expect(
      convert({
        transform: [
          { translateX: 5 },
          { translateY: -10 },
          { perspective: 1000 },
        ],
      })
    ).toEqual({
      transform: 'translateX(5px) translateY(-10px) perspective(1000px)',
    });
  });

  it('scale transforms have no unit', () => {
    expect(convert({ transform: [{ scaleX: 2 }, { scaleY: 0.5 }] })).toEqual({
      transform: 'scaleX(2) scaleY(0.5)',
    });
  });

  it('angle transforms pass string value through', () => {
    expect(
      convert({
        transform: [
          { rotateX: '30deg' },
          { rotateY: '60deg' },
          { rotateZ: '90deg' },
          { skewX: '15deg' },
          { skewY: '10deg' },
        ],
      })
    ).toEqual({
      transform:
        'rotateX(30deg) rotateY(60deg) rotateZ(90deg) skewX(15deg) skewY(10deg)',
    });
  });

  it('matrix(6 values) uses 2D matrix()', () => {
    expect(convert({ transform: [{ matrix: [1, 0, 0, 1, 10, 20] }] })).toEqual({
      transform: 'matrix(1, 0, 0, 1, 10, 20)',
    });
  });

  it('matrix(16 values) uses matrix3d()', () => {
    const m = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 10, 20, 0, 1];
    expect(convert({ transform: [{ matrix: m }] })).toEqual({
      transform: `matrix3d(${m.join(', ')})`,
    });
  });
});

describe('transformOrigin property', () => {
  it('string transformOrigin passes through unchanged', () => {
    expect(convert({ transformOrigin: 'center' })).toEqual({
      transformOrigin: 'center',
    });
  });

  it('keyword pair transformOrigin passes through unchanged', () => {
    expect(convert({ transformOrigin: 'top left' })).toEqual({
      transformOrigin: 'top left',
    });
  });

  it('percentage transformOrigin passes through unchanged', () => {
    expect(convert({ transformOrigin: '50% 50%' })).toEqual({
      transformOrigin: '50% 50%',
    });
  });

  it('px-value transformOrigin passes through unchanged', () => {
    expect(convert({ transformOrigin: '10px 20px' })).toEqual({
      transformOrigin: '10px 20px',
    });
  });

  it('transformOrigin is omitted when not provided', () => {
    expect(convert({ width: 100 })).not.toHaveProperty('transformOrigin');
  });

  it('transform and transformOrigin work together', () => {
    expect(
      convert({ transform: 'rotate(45deg)', transformOrigin: 'top left' })
    ).toEqual({ transform: 'rotate(45deg)', transformOrigin: 'top left' });
  });
});

describe('border style defaulting', () => {
  it('defaults borderStyle to solid when borderWidth is set without borderStyle', () => {
    expect(convert({ borderWidth: 2, borderColor: 'red' })).toMatchObject({
      borderWidth: '2px',
      borderColor: 'red',
      borderStyle: 'solid',
    });
  });

  it('does not add borderStyle when no border width or color is set', () => {
    expect(convert({ backgroundColor: 'white' })).not.toHaveProperty(
      'borderStyle'
    );
  });

  it('respects explicit borderStyle when provided', () => {
    expect(convert({ borderWidth: 2, borderStyle: 'dashed' })).toMatchObject({
      borderStyle: 'dashed',
    });
  });
});

describe('outline style defaulting', () => {
  it('defaults outlineStyle to solid when outlineWidth is set without outlineStyle', () => {
    expect(convert({ outlineWidth: 10 })).toMatchObject({
      outlineWidth: '10px',
      outlineStyle: 'solid',
    });
  });

  it('does not add outlineStyle when outlineWidth is not set', () => {
    expect(convert({ backgroundColor: 'white' })).not.toHaveProperty(
      'outlineStyle'
    );
  });

  it('respects explicit outlineStyle when provided', () => {
    expect(convert({ outlineWidth: 2, outlineStyle: 'dotted' })).toMatchObject({
      outlineStyle: 'dotted',
    });
  });
});

describe('combined properties', () => {
  it('handles a typical card-like style object', () => {
    const input: EnrichedInputStyle = {
      backgroundColor: '#fff',
      borderRadius: 12,
      padding: 16,
      marginHorizontal: 8,
      boxShadow: '0px 2px 6px rgba(0,0,0,0.15)',
    };

    const result = convert(input);

    expect(result).toMatchObject({
      backgroundColor: '#fff',
      borderRadius: '12px',
      padding: '16px',
      marginLeft: '8px',
      marginRight: '8px',
      boxShadow: '0px 2px 6px rgba(0,0,0,0.15)',
    });
    expect(result).not.toHaveProperty('marginHorizontal');
  });

  it('handles a full typography style', () => {
    const input: EnrichedInputStyle = {
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: '500',
      lineHeight: 20,
      letterSpacing: 0.5,
      color: '#333',
    };

    expect(convert(input)).toEqual({
      fontFamily: 'Inter',
      fontSize: '14px',
      fontWeight: '500',
      lineHeight: '20px',
      letterSpacing: '0.5px',
      color: '#333',
    });
  });

  it('handles an absolutely positioned overlay', () => {
    const input: EnrichedInputStyle = {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      zIndex: 100,
      opacity: 0.9,
    };

    expect(convert(input)).toEqual({
      position: 'absolute',
      top: '0px',
      left: '0px',
      right: '0px',
      bottom: '0px',
      zIndex: 100,
      opacity: 0.9,
    });
  });

  it('handles flex layout', () => {
    const input: EnrichedInputStyle = {
      flex: 1,
      flexGrow: 1,
      flexShrink: 0,
      flexBasis: 'auto',
      alignSelf: 'center',
    };

    expect(convert(input)).toEqual({
      flex: 1,
      flexGrow: 1,
      flexShrink: 0,
      flexBasis: 'auto',
      alignSelf: 'center',
    });
  });
});

describe('extraOptions.scrollEnabled', () => {
  it('sets overflowY to auto when scrollEnabled is true', () => {
    expect(convert({})).not.toHaveProperty('overflowY');
    expect(
      enrichedInputStyleToCSSProperties({}, { scrollEnabled: true })
    ).toMatchObject({
      overflowY: 'auto',
    });
  });

  it('sets overflowY to hidden when scrollEnabled is false', () => {
    expect(
      enrichedInputStyleToCSSProperties({}, { scrollEnabled: false })
    ).toMatchObject({
      overflowY: 'hidden',
    });
  });
});
