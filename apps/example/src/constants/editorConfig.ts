import type { HtmlStyle, OnChangeStateEvent } from 'react-native-enriched';

export type StylesState = OnChangeStateEvent;

export const DEFAULT_STYLE_STATE = {
  isActive: false,
  isConflicting: false,
  isBlocking: false,
};

export const DEFAULT_STYLES: StylesState = {
  bold: DEFAULT_STYLE_STATE,
  italic: DEFAULT_STYLE_STATE,
  underline: DEFAULT_STYLE_STATE,
  strikeThrough: DEFAULT_STYLE_STATE,
  inlineCode: DEFAULT_STYLE_STATE,
  h1: DEFAULT_STYLE_STATE,
  h2: DEFAULT_STYLE_STATE,
  h3: DEFAULT_STYLE_STATE,
  h4: DEFAULT_STYLE_STATE,
  h5: DEFAULT_STYLE_STATE,
  h6: DEFAULT_STYLE_STATE,
  blockQuote: DEFAULT_STYLE_STATE,
  codeBlock: DEFAULT_STYLE_STATE,
  orderedList: DEFAULT_STYLE_STATE,
  unorderedList: DEFAULT_STYLE_STATE,
  link: DEFAULT_STYLE_STATE,
  image: DEFAULT_STYLE_STATE,
  mention: DEFAULT_STYLE_STATE,
  checkboxList: DEFAULT_STYLE_STATE,
};

export const DEFAULT_LINK_STATE = {
  text: '',
  url: '',
  start: 0,
  end: 0,
};

export const LINK_REGEX =
  /^(?:enriched:\/\/\S+|(?:https?:\/\/)?(?:www\.)?swmansion\.com(?:\/\S*)?)$/i;

export const DEBUG_SCROLLABLE = false;

// Enabling this prop fixes input flickering while auto growing.
// However, it's still experimental and not tested well.
// Disabled for now, as it's causing some strange issues.
// See: https://github.com/software-mansion/react-native-enriched/issues/229
export const ANDROID_EXPERIMENTAL_SYNCHRONOUS_EVENTS = false;

export const htmlStyle: HtmlStyle = {
  h1: {
    fontSize: 72,
    bold: true,
  },
  h2: {
    fontSize: 60,
    bold: true,
  },
  h3: {
    fontSize: 50,
    bold: true,
  },
  h4: {
    fontSize: 40,
    bold: true,
  },
  h5: {
    fontSize: 30,
    bold: true,
  },
  h6: {
    fontSize: 24,
    bold: true,
  },
  blockquote: {
    borderColor: 'navy',
    borderWidth: 4,
    gapWidth: 16,
    color: 'navy',
  },
  codeblock: {
    color: 'green',
    borderRadius: 8,
    backgroundColor: 'grey',
  },
  code: {
    color: 'purple',
    backgroundColor: 'yellow',
  },
  a: {
    color: 'green',
    textDecorationLine: 'underline',
  },
  mention: {
    '#': {
      color: 'blue',
      backgroundColor: 'lightblue',
      textDecorationLine: 'underline',
    },
    '@': {
      color: 'green',
      backgroundColor: 'lightgreen',
      textDecorationLine: 'none',
    },
  },
  ol: {
    gapWidth: 16,
    marginLeft: 24,
    markerColor: 'navy',
    markerFontWeight: 'bold',
  },
  ul: {
    bulletColor: 'aquamarine',
    bulletSize: 8,
    marginLeft: 24,
    gapWidth: 16,
  },
  ulCheckbox: {
    boxSize: 24,
    gapWidth: 16,
    marginLeft: 24,
    boxColor: 'rgb(0, 26, 114)',
  },
};
