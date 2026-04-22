import type { EnrichedTextHtmlStyle, HtmlStyle } from 'react-native-enriched';

const SHARED_BLOCK_STYLES = {
  h1: { fontSize: 22, bold: true },
  h2: { fontSize: 20, bold: true },
  h3: { fontSize: 18, bold: true },
  h4: { fontSize: 17, bold: true },
  h5: { fontSize: 16, bold: true },
  h6: { fontSize: 15, bold: true },
  ol: {
    gapWidth: 8,
    marginLeft: 16,
    markerFontWeight: 'bold' as const,
  },
  ul: {
    bulletSize: 6,
    marginLeft: 16,
    gapWidth: 8,
  },
  ulCheckbox: {
    boxSize: 18,
    gapWidth: 8,
    marginLeft: 16,
  },
};

// Style used inside the EnrichedTextInput (dark text on light background).
export const chatInputHtmlStyle: HtmlStyle = {
  ...SHARED_BLOCK_STYLES,
  blockquote: {
    borderColor: '#888',
    borderWidth: 3,
    gapWidth: 10,
    color: '#444',
  },
  codeblock: {
    color: '#111',
    borderRadius: 6,
    backgroundColor: '#e8e8e8',
  },
  code: {
    color: '#b33',
    backgroundColor: '#f2f2f2',
  },
  a: {
    color: '#0a66ff',
    textDecorationLine: 'underline',
  },
  mention: {
    '@': {
      color: '#0a66ff',
      backgroundColor: 'rgba(10, 102, 255, 0.12)',
      textDecorationLine: 'none',
    },
  },
  ol: {
    ...SHARED_BLOCK_STYLES.ol,
    markerColor: '#444',
  },
  ul: {
    ...SHARED_BLOCK_STYLES.ul,
    bulletColor: '#444',
  },
  ulCheckbox: {
    ...SHARED_BLOCK_STYLES.ulCheckbox,
    boxColor: '#444',
  },
};

// Incoming bubble: dark text on light gray background.
export const incomingHtmlStyle: EnrichedTextHtmlStyle = {
  ...SHARED_BLOCK_STYLES,
  blockquote: {
    borderColor: '#888',
    borderWidth: 3,
    gapWidth: 10,
    color: '#444',
  },
  codeblock: {
    color: '#111',
    borderRadius: 6,
    backgroundColor: '#dcdcdc',
  },
  code: {
    color: '#b33',
    backgroundColor: '#e5e5e5',
  },
  a: {
    color: '#0a66ff',
    textDecorationLine: 'underline',
    pressColor: '#003e9c',
  },
  mention: {
    '@': {
      color: '#0a66ff',
      backgroundColor: 'rgba(10, 102, 255, 0.12)',
      textDecorationLine: 'none',
      pressColor: '#003e9c',
      pressBackgroundColor: 'rgba(10, 102, 255, 0.25)',
    },
  },
  ol: {
    ...SHARED_BLOCK_STYLES.ol,
    markerColor: '#444',
  },
  ul: {
    ...SHARED_BLOCK_STYLES.ul,
    bulletColor: '#444',
  },
  ulCheckbox: {
    ...SHARED_BLOCK_STYLES.ulCheckbox,
    boxColor: '#444',
  },
};

// Outgoing bubble: white text on iMessage-style blue background.
export const outgoingHtmlStyle: EnrichedTextHtmlStyle = {
  ...SHARED_BLOCK_STYLES,
  blockquote: {
    borderColor: 'rgba(255, 255, 255, 0.7)',
    borderWidth: 3,
    gapWidth: 10,
    color: 'rgba(255, 255, 255, 0.85)',
  },
  codeblock: {
    color: '#ffffff',
    borderRadius: 6,
    backgroundColor: 'rgba(0, 0, 0, 0.18)',
  },
  code: {
    color: '#ffffff',
    backgroundColor: 'rgba(0, 0, 0, 0.18)',
  },
  a: {
    color: '#ffffff',
    textDecorationLine: 'underline',
    pressColor: '#e6f0ff',
  },
  mention: {
    '@': {
      color: '#ffffff',
      backgroundColor: 'rgba(255, 255, 255, 0.22)',
      textDecorationLine: 'none',
      pressColor: '#e6f0ff',
      pressBackgroundColor: 'rgba(255, 255, 255, 0.35)',
    },
  },
  ol: {
    ...SHARED_BLOCK_STYLES.ol,
    markerColor: '#ffffff',
  },
  ul: {
    ...SHARED_BLOCK_STYLES.ul,
    bulletColor: '#ffffff',
  },
  ulCheckbox: {
    ...SHARED_BLOCK_STYLES.ulCheckbox,
    boxColor: '#ffffff',
  },
};
