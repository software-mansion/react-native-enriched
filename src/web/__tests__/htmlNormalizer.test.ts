/*
 * Port of cpp/tests/GumboParserTest.cpp. Each describe() mirrors a TEST() group
 * from the C++ suite. The expected outputs are the same as the native
 * normalizer's outputs
 */
import { normalizeHtml } from '../normalization/htmlNormalizer';

describe('htmlNormalizer', () => {
  describe('TagRemappings', () => {
    test.each([
      ['<strong>x</strong>', '<b>x</b>'],
      ['<em>x</em>', '<i>x</i>'],
      ['<del>x</del>', '<s>x</s>'],
      ['<strike>x</strike>', '<s>x</s>'],
      ['<ins>x</ins>', '<u>x</u>'],
      ['<pre>x</pre>', '<codeblock><p>x</p></codeblock>'],
    ])('%s → %s', (input, expected) => {
      expect(normalizeHtml(input)).toBe(expected);
    });
  });

  describe('GoogleDocsWrapper', () => {
    test.each([
      ['<b id="docs-internal-guid-1234567890">x</b>', 'x'],
      ['<b id="docs-internal-guid-1234567890"></b>', ''],
    ])('%s → %s', (input, expected) => {
      expect(normalizeHtml(input)).toBe(expected);
    });
  });

  describe('TagOmissions', () => {
    test.each([
      ["<meta name='author' content='John Doe'>", ''],
      ['<style></style>', ''],
      ['<script></script>', ''],
      ['<title></title>', ''],
      ["<link rel='stylesheet' href='styles.css'>", ''],
      ['<html></html>', ''],
      ['<body></body>', ''],
      ['<head></head>', ''],
      // Nested tags
      ['<html><head></head><body></body></html>', ''],
      ['<html><body><p>x</p></body></html>', '<p>x</p>'],
      ['<html><p>x</p></html>', '<p>x</p>'],
      ['<body><p>x</p></body>', '<p>x</p>'],
    ])('%s → %s', (input, expected) => {
      expect(normalizeHtml(input)).toBe(expected);
    });
  });

  describe('TableOmissions', () => {
    test.each([
      ['<table></table>', ''],
      ['<thead></thead>', ''],
      ['<tbody></tbody>', ''],
      ['<tfoot></tfoot>', ''],
      ['<tr></tr>', ''],
      ['<td></td>', ''],
      ['<th></th>', ''],
      ['<caption></caption>', ''],
      ['<colgroup></colgroup>', ''],
      ['<col></col>', ''],
      [
        '<table style="width:100%"><tr><td>Emil</td><td>Tobias</td><td>Linus</td></tr></table>',
        '<p>Emil Tobias Linus</p>',
      ],
      [
        '<table><tr><td>Emil</td><td>Tobias</td><td>Linus</td></tr><tr><td>16</td><td>14</td><td>10</td></tr></table>',
        '<p>Emil Tobias Linus</p><p>16 14 10</p>',
      ],
      [
        '<table><tr><th>Person 1</th><th>Person 2</th><th>Person 3</th></tr><tr><td>Emil</td><td>Tobias</td><td>Linus</td></tr><tr><td>16</td><td>14</td><td>10</td></tr></table>',
        '<p>Person 1 Person 2 Person 3</p><p>Emil Tobias Linus</p><p>16 14 10</p>',
      ],
    ])('%s → %s', (input, expected) => {
      expect(normalizeHtml(input)).toBe(expected);
    });
  });

  describe('SpanRemappings', () => {
    test.each([
      // Bold
      ['<span style="font-weight: bold;">x</span>', '<b>x</b>'],
      ['<span style="font-weight: bold">x</span>', '<b>x</b>'],
      ["<span style='font-weight: bold'>x</span>", '<b>x</b>'],

      // Italic
      ['<span style="font-style: italic;">x</span>', '<i>x</i>'],
      ['<span style="font-style: italic">x</span>', '<i>x</i>'],
      ["<span style='font-style: italic'>x</span>", '<i>x</i>'],

      // Underline
      ['<span style="text-decoration: underline;">x</span>', '<u>x</u>'],
      ['<span style="text-decoration: underline">x</span>', '<u>x</u>'],
      ["<span style='text-decoration: underline'>x</span>", '<u>x</u>'],

      // Strikethrough
      ['<span style="text-decoration: line-through;">x</span>', '<s>x</s>'],
      ['<span style="text-decoration: line-through">x</span>', '<s>x</s>'],
      ["<span style='text-decoration: line-through'>x</span>", '<s>x</s>'],

      // Bold + Italic (either order)
      [
        '<span style="font-weight: bold; font-style: italic;">x</span>',
        '<b><i>x</i></b>',
      ],
      [
        '<span style="font-weight: bold; font-style: italic">x</span>',
        '<b><i>x</i></b>',
      ],
      [
        "<span style='font-weight: bold; font-style: italic'>x</span>",
        '<b><i>x</i></b>',
      ],
      [
        '<span style="font-style: italic; font-weight: bold;">x</span>',
        '<b><i>x</i></b>',
      ],
      [
        '<span style="font-style: italic; font-weight: bold">x</span>',
        '<b><i>x</i></b>',
      ],
      [
        "<span style='font-style: italic; font-weight: bold'>x</span>",
        '<b><i>x</i></b>',
      ],

      // Bold + Underline (either order)
      [
        '<span style="font-weight: bold; text-decoration: underline;">x</span>',
        '<b><u>x</u></b>',
      ],
      [
        '<span style="font-weight: bold; text-decoration: underline">x</span>',
        '<b><u>x</u></b>',
      ],
      [
        "<span style='font-weight: bold; text-decoration: underline'>x</span>",
        '<b><u>x</u></b>',
      ],
      [
        '<span style="text-decoration: underline; font-weight: bold;">x</span>',
        '<b><u>x</u></b>',
      ],
      [
        '<span style="text-decoration: underline; font-weight: bold">x</span>',
        '<b><u>x</u></b>',
      ],
      [
        "<span style='text-decoration: underline; font-weight: bold'>x</span>",
        '<b><u>x</u></b>',
      ],

      // Bold + Strikethrough (either order)
      [
        '<span style="font-weight: bold; text-decoration: line-through;">x</span>',
        '<b><s>x</s></b>',
      ],
      [
        '<span style="font-weight: bold; text-decoration: line-through">x</span>',
        '<b><s>x</s></b>',
      ],
      [
        "<span style='font-weight: bold; text-decoration: line-through'>x</span>",
        '<b><s>x</s></b>',
      ],
      [
        '<span style="text-decoration: line-through; font-weight: bold;">x</span>',
        '<b><s>x</s></b>',
      ],
      [
        '<span style="text-decoration: line-through; font-weight: bold">x</span>',
        '<b><s>x</s></b>',
      ],
      [
        "<span style='text-decoration: line-through; font-weight: bold'>x</span>",
        '<b><s>x</s></b>',
      ],

      // Underline + Strikethrough (either order)
      [
        '<span style="text-decoration: underline; text-decoration: line-through;">x</span>',
        '<u><s>x</s></u>',
      ],
      [
        '<span style="text-decoration: underline; text-decoration: line-through">x</span>',
        '<u><s>x</s></u>',
      ],
      [
        "<span style='text-decoration: underline; text-decoration: line-through'>x</span>",
        '<u><s>x</s></u>',
      ],
      [
        '<span style="text-decoration: line-through; text-decoration: underline;">x</span>',
        '<u><s>x</s></u>',
      ],
      [
        '<span style="text-decoration: line-through; text-decoration: underline">x</span>',
        '<u><s>x</s></u>',
      ],
      [
        "<span style='text-decoration: line-through; text-decoration: underline'>x</span>",
        '<u><s>x</s></u>',
      ],

      // Three-way combinations
      [
        '<span style="font-weight: bold; font-style: italic; text-decoration: underline;">x</span>',
        '<b><i><u>x</u></i></b>',
      ],
      [
        '<span style="font-weight: bold; font-style: italic; text-decoration: underline">x</span>',
        '<b><i><u>x</u></i></b>',
      ],
      [
        "<span style='font-weight: bold; font-style: italic; text-decoration: underline'>x</span>",
        '<b><i><u>x</u></i></b>',
      ],
      [
        "<span style='font-weight: bold; text-decoration: underline; font-style: italic;'>x</span>",
        '<b><i><u>x</u></i></b>',
      ],
      [
        "<span style='text-decoration: underline; font-weight: bold; font-style: italic;'>x</span>",
        '<b><i><u>x</u></i></b>',
      ],
      [
        "<span style='text-decoration: line-through; font-weight: bold; font-style: italic;'>x</span>",
        '<b><i><s>x</s></i></b>',
      ],
    ])('%s → %s', (input, expected) => {
      expect(normalizeHtml(input)).toBe(expected);
    });
  });

  describe('EnrichedTagRemappings', () => {
    test.each([
      // Block elements
      ['<codeblock>x</codeblock>', '<codeblock><p>x</p></codeblock>'],
      ['<codeblock><p>x</p></codeblock>', '<codeblock><p>x</p></codeblock>'],
      ['<blockquote>x</blockquote>', '<blockquote><p>x</p></blockquote>'],
      [
        '<blockquote><p>x</p></blockquote>',
        '<blockquote><p>x</p></blockquote>',
      ],

      // Headings
      ['<h1>x</h1>', '<h1>x</h1>'],
      ['<h2>x</h2>', '<h2>x</h2>'],
      ['<h3>x</h3>', '<h3>x</h3>'],
      ['<h4>x</h4>', '<h4>x</h4>'],
      ['<h5>x</h5>', '<h5>x</h5>'],
      ['<h6>x</h6>', '<h6>x</h6>'],

      // Self-closing tags
      ['<br>', '<br>'],
      [
        '<img src="x" width="100" height="100" />',
        '<img src="x" width="100" height="100" />',
      ],
      [
        "<img src='x' width='100' height='100' />",
        '<img src="x" width="100" height="100" />',
      ],

      // Lists
      ['<ul><li>x</li></ul>', '<ul><li>x</li></ul>'],
      ['<ol><li>x</li></ol>', '<ol><li>x</li></ol>'],

      // Checkbox lists
      [
        "<ul data-type='checkbox'><li>x</li></ul>",
        '<ul data-type="checkbox"><li>x</li></ul>',
      ],
      [
        '<ul data-type="checkbox"><li>x</li></ul>',
        '<ul data-type="checkbox"><li>x</li></ul>',
      ],
      [
        "<ul data-type='checkbox'><li checked>x</li></ul>",
        '<ul data-type="checkbox"><li checked>x</li></ul>',
      ],
      [
        '<ul data-type="checkbox"><li checked>x</li></ul>',
        '<ul data-type="checkbox"><li checked>x</li></ul>',
      ],

      // Mentions (note: cpp reorders attrs to id, text, indicator)
      [
        "<mention text='@John Doe' indicator='@' id='1'>@John Doe</mention>",
        '<mention id="1" text="@John Doe" indicator="@">@John Doe</mention>',
      ],
      [
        '<mention text="@John Doe" indicator="@" id="1">@John Doe</mention>',
        '<mention id="1" text="@John Doe" indicator="@">@John Doe</mention>',
      ],

      // Link
      [
        '<a href="https://www.google.com">Google</a>',
        '<a href="https://www.google.com">Google</a>',
      ],
      [
        "<a href='https://www.google.com'>Google</a>",
        '<a href="https://www.google.com">Google</a>',
      ],

      // Inline
      ['<code>x</code>', '<code>x</code>'],
      ['<s>x</s>', '<s>x</s>'],
      ['<u>x</u>', '<u>x</u>'],
      ['<i>x</i>', '<i>x</i>'],
      ['<b>x</b>', '<b>x</b>'],
    ])('%s → %s', (input, expected) => {
      expect(normalizeHtml(input)).toBe(expected);
    });
  });

  describe('DivRemappings', () => {
    test.each([
      ['<div>x</div>', '<p>x</p>'],
      ['<div><p>x</p></div>', '<p>x</p>'],
      ['<div><p>x</p><p>y</p></div>', '<p>x</p><p>y</p>'],
      ['<div><span>x</span></div>', '<p>x</p>'],
      [
        '<div><div><span>x</span></div><span>y</span></div>',
        '<p>x</p><p>y</p>',
      ],

      // Without whitespace
      [
        '<span>--</span><br><div><div><span>John<span> </span></span><b>Doe</b><div><u><i>Software</i></u><span> </span>Engineer</div></div></div>',
        '<p>--</p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>',
      ],
      [
        '<div><div><span>John<span> </span></span><b>Doe</b><div><u><i>Software</i></u><span> </span>Engineer</div></div></div>',
        '<p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>',
      ],
      [
        "<span style='font-weight: 700'>--</span><br><div><div><span>John<span> </span></span><b>Doe</b><div><u><i>Software</i></u><span> </span>Engineer</div></div></div>",
        '<p><b>--</b></p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>',
      ],
      [
        "<span style='font-style: italic'>--</span><br><div><div><span>John<span> </span></span><b>Doe</b><div><u><i>Software</i></u><span> </span>Engineer</div></div></div>",
        '<p><i>--</i></p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>',
      ],
      [
        "<span style='font-style: italic; font-weight: bold'>--</span><br><div><div><span>John<span> </span></span><b>Doe</b><div><u><i>Software</i></u><span> </span>Engineer</div></div></div>",
        '<p><b><i>--</i></b></p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>',
      ],
      [
        "<span style='font-style: italic; font-weight: bold; text-decoration: underline'>--</span><br><div><div><span>John<span> </span></span><b>Doe</b><div><u><i>Software</i></u><span> </span>Engineer</div></div></div>",
        '<p><b><i><u>--</u></i></b></p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>',
      ],

      [
        '<div><br>here&#39;s more!</div><div><br></div><img src="https://example.com/image.png" alt="image.png" width="336" height="297">',
        '<br><p>here&#39;s more!</p><br><p><img src="https://example.com/image.png" alt="image.png" width="336" height="297" /></p>',
      ],
      [
        '<div>what do you think of this craziness</div><span><blockquote><div><div><ul><li><b>another one </b>hello<div><br></div><div>hi</div></li></ul></div></div></blockquote></span>',
        '<p>what do you think of this craziness</p><blockquote><p><b>another one </b>hello</p><p>hi</p></blockquote>',
      ],
    ])('%s → %s', (input, expected) => {
      expect(normalizeHtml(input)).toBe(expected);
    });
  });

  describe('ListFlattening', () => {
    test.each([
      [
        '<ul><ol><li>x</li><li>y</li></ol></ul>',
        '<ul><li>x</li><li>y</li></ul>',
      ],
      [
        '<ul><li>x</li><ol><li>y</li><li>z</li></ol></ul>',
        '<ul><li>x</li><li>y</li><li>z</li></ul>',
      ],
      [
        '<ul><ol><li>x</li><li>y</li></ol><li>z</li></ul>',
        '<ul><li>x</li><li>y</li><li>z</li></ul>',
      ],
      [
        '<ol><li>x</li><ul><li>y</li><li>z</li></ul></ol>',
        '<ol><li>x</li><li>y</li><li>z</li></ol>',
      ],
      [
        '<ol><ul><li>x</li><li>y</li></ul><li>z</li></ol>',
        '<ol><li>x</li><li>y</li><li>z</li></ol>',
      ],
      [
        "<ol><ul data-type='checkbox'><li>x</li><li>y</li></ul><li>z</li></ol>",
        '<ol><li>x</li><li>y</li><li>z</li></ol>',
      ],
      [
        "<ul data-type='checkbox'><ol><li>x</li><li>y</li></ol><li>z</li></ul>",
        '<ul data-type="checkbox"><li>x</li><li>y</li><li>z</li></ul>',
      ],
      [
        '<ul><li>x</li><ol><li>y</li><ul><li>z</li></ul></ol></ul>',
        '<ul><li>x</li><li>y</li><li>z</li></ul>',
      ],
      [
        "<ul><li>x</li><ol><li>y</li><ul data-type='checkbox'><li>z</li></ul></ol></ul>",
        '<ul><li>x</li><li>y</li><li>z</li></ul>',
      ],
      [
        "<ul data-type='checkbox'><li>x</li><ol><li>y</li><ul><li>z</li></ul></ol></ul>",
        '<ul data-type="checkbox"><li>x</li><li>y</li><li>z</li></ul>',
      ],
      [
        '<ul><li><b>another one </b>hi kacper,<div><br></div><div>hi</div></li></ul>',
        '<ul><li><b>another one </b>hi kacper,</li><li>hi</li></ul>',
      ],
    ])('%s → %s', (input, expected) => {
      expect(normalizeHtml(input)).toBe(expected);
    });
  });

  describe('BrRemappings', () => {
    test('inline collapses around <br> stay flat', () => {
      expect(
        normalizeHtml(
          "<p><b>Asdasdasd</b></p><br><br><p>Sent with<span> </span><a href='https://google.com'>Net</a></p>"
        )
      ).toBe(
        '<p><b>Asdasdasd</b></p><br><br><p>Sent with <a href="https://google.com">Net</a></p>'
      );
    });
  });

  describe('character escaping', () => {
    // Each special character in text content is re-emitted as its entity.
    test.each([
      ['<p>a & b</p>', '<p>a &amp; b</p>'],
      ['<p>a < b</p>', '<p>a &lt; b</p>'],
      ['<p>a > b</p>', '<p>a &gt; b</p>'],
      ['<p>"quoted"</p>', '<p>&quot;quoted&quot;</p>'],
      ["<p>it's</p>", '<p>it&#39;s</p>'],
      ['<p>&amp;&lt;&gt;"\'</p>', '<p>&amp;&lt;&gt;&quot;&#39;</p>'],
      ['<p>&<>"\'</p>', '<p>&amp;&lt;&gt;&quot;&#39;</p>'],
      [
        '<a href="https://example.com?a=1&b=\'2\'">x</a>',
        '<a href="https://example.com?a=1&amp;b=&#39;2&#39;">x</a>',
      ],
    ])('%s → %s', (input, expected) => {
      expect(normalizeHtml(input)).toBe(expected);
    });
  });
});
