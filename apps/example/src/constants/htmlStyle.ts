import type { HtmlStyle } from 'react-native-enriched';

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
    backgroundColor: 'aquamarine',
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
