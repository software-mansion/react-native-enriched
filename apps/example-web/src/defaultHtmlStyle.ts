import type { HtmlStyle } from 'react-native-enriched';

export const defaultHtmlStyle: HtmlStyle = {
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
    color: '#008000',
    borderRadius: 8,
    backgroundColor: '#bfbfbf',
  },
  code: {
    color: 'purple',
    backgroundColor: 'yellow',
  },
};
