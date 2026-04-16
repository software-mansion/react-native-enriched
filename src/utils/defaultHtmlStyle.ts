import type { HtmlStyle } from '../types';

export const DEFAULT_HTML_STYLE: Required<HtmlStyle> = {
  h1: {
    fontSize: 32,
    bold: false,
  },
  h2: {
    fontSize: 24,
    bold: false,
  },
  h3: {
    fontSize: 20,
    bold: false,
  },
  h4: {
    fontSize: 16,
    bold: false,
  },
  h5: {
    fontSize: 14,
    bold: false,
  },
  h6: {
    fontSize: 12,
    bold: false,
  },
  blockquote: {
    borderColor: 'darkgray',
    borderWidth: 4,
    gapWidth: 16,
    color: undefined,
  },
  codeblock: {
    color: 'black',
    borderRadius: 8,
    backgroundColor: 'darkgray',
  },
  code: {
    color: 'red',
    backgroundColor: 'darkgray',
  },
  a: {
    color: 'blue',
    textDecorationLine: 'underline',
  },
  mention: {
    color: 'blue',
    backgroundColor: 'yellow',
    textDecorationLine: 'underline',
  },
  ol: {
    gapWidth: 16,
    marginLeft: 16,
    markerFontWeight: undefined,
    markerColor: undefined,
  },
  ul: {
    bulletColor: 'black',
    bulletSize: 8,
    marginLeft: 16,
    gapWidth: 16,
  },
  ulCheckbox: {
    boxSize: 24,
    gapWidth: 16,
    marginLeft: 16,
    boxColor: 'blue',
  },
};
