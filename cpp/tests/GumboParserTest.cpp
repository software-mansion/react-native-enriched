#include <gtest/gtest.h>
#include "GumboParser.hpp"

TEST(GumboParserTest, TagRemappings) {
  EXPECT_EQ(GumboParser::normalizeHtml("<strong>x</strong>"), "<b>x</b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<em>x</em>"), "<i>x</i>");
  EXPECT_EQ(GumboParser::normalizeHtml("<del>x</del>"), "<s>x</s>");
  EXPECT_EQ(GumboParser::normalizeHtml("<strike>x</strike>"), "<s>x</s>");
  EXPECT_EQ(GumboParser::normalizeHtml("<ins>x</ins>"), "<u>x</u>");
  EXPECT_EQ(GumboParser::normalizeHtml("<pre>x</pre>"), "<codeblock><p>x</p></codeblock>");
}

TEST(GumboParserTest, GoogleDocsWrapper) {
  EXPECT_EQ(GumboParser::normalizeHtml("<b id=\"docs-internal-guid-1234567890\">x</b>"), "x");
  EXPECT_EQ(GumboParser::normalizeHtml("<b id=\"docs-internal-guid-1234567890\"></b>"), "");
}

TEST(GumboParserTest, TagOmissions) {
  EXPECT_EQ(GumboParser::normalizeHtml("<meta name='author' content='John Doe'>"), "");
  EXPECT_EQ(GumboParser::normalizeHtml("<style></style>"), "");
  EXPECT_EQ(GumboParser::normalizeHtml("<script></script>"), "");
  EXPECT_EQ(GumboParser::normalizeHtml("<title></title>"), "");
  EXPECT_EQ(GumboParser::normalizeHtml("<link rel='stylesheet' href='styles.css'>"), "");
  EXPECT_EQ(GumboParser::normalizeHtml("<html></html>"), "");
  EXPECT_EQ(GumboParser::normalizeHtml("<body></body>"), "");
  EXPECT_EQ(GumboParser::normalizeHtml("<head></head>"), "");

  // Nested tags
  EXPECT_EQ(GumboParser::normalizeHtml("<html><head></head><body></body></html>"), "");
  EXPECT_EQ(GumboParser::normalizeHtml("<html><body><p>x</p></body></html>"), "<p>x</p>");
  EXPECT_EQ(GumboParser::normalizeHtml("<html><p>x</p></html>"), "<p>x</p>");
  EXPECT_EQ(GumboParser::normalizeHtml("<body><p>x</p></body>"), "<p>x</p>");
}

TEST(GumboParserTest, TableOmissions) {
  EXPECT_EQ(GumboParser::normalizeHtml("<table></table>"), "");
  EXPECT_EQ(GumboParser::normalizeHtml("<thead></thead>"), "");
  EXPECT_EQ(GumboParser::normalizeHtml("<tbody></tbody>"), "");
  EXPECT_EQ(GumboParser::normalizeHtml("<tfoot></tfoot>"), "");
  EXPECT_EQ(GumboParser::normalizeHtml("<tr></tr>"), "");
  EXPECT_EQ(GumboParser::normalizeHtml("<td></td>"), "");
  EXPECT_EQ(GumboParser::normalizeHtml("<th></th>"), "");
  EXPECT_EQ(GumboParser::normalizeHtml("<caption></caption>"), "");
  EXPECT_EQ(GumboParser::normalizeHtml("<colgroup></colgroup>"), "");
  EXPECT_EQ(GumboParser::normalizeHtml("<col></col>"), "");

  EXPECT_EQ(
    GumboParser::normalizeHtml(
        "<table style=\"width:100%\"><tr><td>Emil</td><td>Tobias</td><td>Linus</td></tr></table>"),
    "<p>Emil Tobias Linus</p>");

EXPECT_EQ(
    GumboParser::normalizeHtml(
        "<table><tr><td>Emil</td><td>Tobias</td><td>Linus</td></tr>"
        "<tr><td>16</td><td>14</td><td>10</td></tr></table>"),
    "<p>Emil Tobias Linus</p><p>16 14 10</p>");

  EXPECT_EQ(GumboParser::normalizeHtml("<table><tr><th>Person 1</th><th>Person 2</th><th>Person 3</th></tr><tr><td>Emil</td><td>Tobias</td><td>Linus</td></tr><tr><td>16</td><td>14</td><td>10</td></tr></table>"),
  "<p>Person 1 Person 2 Person 3</p><p>Emil Tobias Linus</p><p>16 14 10</p>");
}

TEST(GumboParserTest, SpanRemappings) {
  // Bold
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"font-weight: bold;\">x</span>"), "<b>x</b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"font-weight: bold\">x</span>"), "<b>x</b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='font-weight: bold'>x</span>"), "<b>x</b>");

  // Italic
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"font-style: italic;\">x</span>"), "<i>x</i>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"font-style: italic\">x</span>"), "<i>x</i>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='font-style: italic'>x</span>"), "<i>x</i>");

  // Underline
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"text-decoration: underline;\">x</span>"), "<u>x</u>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"text-decoration: underline\">x</span>"), "<u>x</u>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='text-decoration: underline'>x</span>"), "<u>x</u>");

  // Strikethrough
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"text-decoration: line-through;\">x</span>"), "<s>x</s>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"text-decoration: line-through\">x</span>"), "<s>x</s>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='text-decoration: line-through'>x</span>"), "<s>x</s>");

  // Bold and Italic
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"font-weight: bold; font-style: italic;\">x</span>"), "<b><i>x</i></b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"font-weight: bold; font-style: italic\">x</span>"), "<b><i>x</i></b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='font-weight: bold; font-style: italic'>x</span>"), "<b><i>x</i></b>");

  // Italic and Bold
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"font-style: italic; font-weight: bold;\">x</span>"), "<b><i>x</i></b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"font-style: italic; font-weight: bold\">x</span>"), "<b><i>x</i></b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='font-style: italic; font-weight: bold'>x</span>"), "<b><i>x</i></b>");

  // Bold and Underline
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"font-weight: bold; text-decoration: underline;\">x</span>"), "<b><u>x</u></b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"font-weight: bold; text-decoration: underline\">x</span>"), "<b><u>x</u></b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='font-weight: bold; text-decoration: underline'>x</span>"), "<b><u>x</u></b>");

  // Underline and Bold
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"text-decoration: underline; font-weight: bold;\">x</span>"), "<b><u>x</u></b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"text-decoration: underline; font-weight: bold\">x</span>"), "<b><u>x</u></b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='text-decoration: underline; font-weight: bold'>x</span>"), "<b><u>x</u></b>");

  // Bold and Strikethrough
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"font-weight: bold; text-decoration: line-through;\">x</span>"), "<b><s>x</s></b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"font-weight: bold; text-decoration: line-through\">x</span>"), "<b><s>x</s></b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='font-weight: bold; text-decoration: line-through'>x</span>"), "<b><s>x</s></b>");

  // Strikethrough and Bold
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"text-decoration: line-through; font-weight: bold;\">x</span>"), "<b><s>x</s></b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"text-decoration: line-through; font-weight: bold\">x</span>"), "<b><s>x</s></b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='text-decoration: line-through; font-weight: bold'>x</span>"), "<b><s>x</s></b>");

  // Underline and Strikethrough
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"text-decoration: underline; text-decoration: line-through;\">x</span>"), "<u><s>x</s></u>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"text-decoration: underline; text-decoration: line-through\">x</span>"), "<u><s>x</s></u>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='text-decoration: underline; text-decoration: line-through'>x</span>"), "<u><s>x</s></u>");

  // Strikethrough and Underline
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"text-decoration: line-through; text-decoration: underline;\">x</span>"), "<u><s>x</s></u>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"text-decoration: line-through; text-decoration: underline\">x</span>"), "<u><s>x</s></u>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='text-decoration: line-through; text-decoration: underline'>x</span>"), "<u><s>x</s></u>");

  // Combined
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"font-weight: bold; font-style: italic; text-decoration: underline;\">x</span>"), "<b><i><u>x</u></i></b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style=\"font-weight: bold; font-style: italic; text-decoration: underline\">x</span>"), "<b><i><u>x</u></i></b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='font-weight: bold; font-style: italic; text-decoration: underline'>x</span>"), "<b><i><u>x</u></i></b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='font-weight: bold; text-decoration: underline; font-style: italic;'>x</span>"), "<b><i><u>x</u></i></b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='text-decoration: underline; font-weight: bold; font-style: italic;'>x</span>"), "<b><i><u>x</u></i></b>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='text-decoration: line-through; font-weight: bold; font-style: italic;'>x</span>"), "<b><i><s>x</s></i></b>");
}

TEST(GumboParserTest, EnrichedTagRemappings) {
  // Block elements
  EXPECT_EQ(GumboParser::normalizeHtml("<codeblock>x</codeblock>"), "<codeblock><p>x</p></codeblock>");
  EXPECT_EQ(GumboParser::normalizeHtml("<codeblock><p>x</p></codeblock>"), "<codeblock><p>x</p></codeblock>");
  EXPECT_EQ(GumboParser::normalizeHtml("<blockquote>x</blockquote>"), "<blockquote><p>x</p></blockquote>");
  EXPECT_EQ(GumboParser::normalizeHtml("<blockquote><p>x</p></blockquote>"), "<blockquote><p>x</p></blockquote>");

  // Headings
  EXPECT_EQ(GumboParser::normalizeHtml("<h1>x</h1>"), "<h1>x</h1>");
  EXPECT_EQ(GumboParser::normalizeHtml("<h2>x</h2>"), "<h2>x</h2>");
  EXPECT_EQ(GumboParser::normalizeHtml("<h3>x</h3>"), "<h3>x</h3>");
  EXPECT_EQ(GumboParser::normalizeHtml("<h4>x</h4>"), "<h4>x</h4>");
  EXPECT_EQ(GumboParser::normalizeHtml("<h5>x</h5>"), "<h5>x</h5>");
  EXPECT_EQ(GumboParser::normalizeHtml("<h6>x</h6>"), "<h6>x</h6>");

  // Self-closing tags
  EXPECT_EQ(GumboParser::normalizeHtml("<br>"), "<br>");
  EXPECT_EQ(GumboParser::normalizeHtml("<img src=\"x\" width=\"100\" height=\"100\" />"), "<img src=\"x\" width=\"100\" height=\"100\" />");
  EXPECT_EQ(GumboParser::normalizeHtml("<img src='x' width='100' height='100' />"), "<img src=\"x\" width=\"100\" height=\"100\" />");

  // Lists
  EXPECT_EQ(GumboParser::normalizeHtml("<ul><li>x</li></ul>"), "<ul><li>x</li></ul>");
  EXPECT_EQ(GumboParser::normalizeHtml("<ol><li>x</li></ol>"), "<ol><li>x</li></ol>");

  // Checkbox lists
  EXPECT_EQ(GumboParser::normalizeHtml("<ul data-type='checkbox'><li>x</li></ul>"), "<ul data-type=\"checkbox\"><li>x</li></ul>");
  EXPECT_EQ(GumboParser::normalizeHtml("<ul data-type=\"checkbox\"><li>x</li></ul>"), "<ul data-type=\"checkbox\"><li>x</li></ul>");
  EXPECT_EQ(GumboParser::normalizeHtml("<ul data-type='checkbox'><li checked>x</li></ul>"), "<ul data-type=\"checkbox\"><li checked>x</li></ul>");
  EXPECT_EQ(GumboParser::normalizeHtml("<ul data-type=\"checkbox\"><li checked>x</li></ul>"), "<ul data-type=\"checkbox\"><li checked>x</li></ul>");

  // Mentions
  EXPECT_EQ(GumboParser::normalizeHtml("<mention text='@John Doe' indicator='@' id='1'>@John Doe</mention>"), "<mention id=\"1\" text=\"@John Doe\" indicator=\"@\">@John Doe</mention>");
  EXPECT_EQ(GumboParser::normalizeHtml("<mention text=\"@John Doe\" indicator=\"@\" id=\"1\">@John Doe</mention>"), "<mention id=\"1\" text=\"@John Doe\" indicator=\"@\">@John Doe</mention>");

  // Link
  EXPECT_EQ(GumboParser::normalizeHtml("<a href=\"https://www.google.com\">Google</a>"), "<a href=\"https://www.google.com\">Google</a>");
  EXPECT_EQ(GumboParser::normalizeHtml("<a href='https://www.google.com'>Google</a>"), "<a href=\"https://www.google.com\">Google</a>");

  // Inline 
  EXPECT_EQ(GumboParser::normalizeHtml("<code>x</code>"), "<code>x</code>");
  EXPECT_EQ(GumboParser::normalizeHtml("<s>x</s>"), "<s>x</s>");
  EXPECT_EQ(GumboParser::normalizeHtml("<u>x</u>"), "<u>x</u>");
  EXPECT_EQ(GumboParser::normalizeHtml("<i>x</i>"), "<i>x</i>");
  EXPECT_EQ(GumboParser::normalizeHtml("<b>x</b>"), "<b>x</b>");
}

TEST(GumboParserTest, DivRemappings) {
  EXPECT_EQ(GumboParser::normalizeHtml("<div>x</div>"), "<p>x</p>");
  EXPECT_EQ(GumboParser::normalizeHtml("<div><p>x</p></div>"), "<p>x</p>");
  EXPECT_EQ(GumboParser::normalizeHtml("<div><p>x</p><p>y</p></div>"), "<p>x</p><p>y</p>");
  EXPECT_EQ(GumboParser::normalizeHtml("<div><p>x</p><p>y</p></div>"), "<p>x</p><p>y</p>");
  EXPECT_EQ(GumboParser::normalizeHtml("<div><span>x</span></div>"), "<p>x</p>");
  EXPECT_EQ(GumboParser::normalizeHtml("<div><div><span>x</span></div><span>y</span></div>"), "<p>x</p><p>y</p>");

  // Without whitespace
  EXPECT_EQ(GumboParser::normalizeHtml("<span>--</span><br><div><div><span>John<span> </span></span><b>Doe</b><div><u><i>Software</i></u><span> </span>Engineer</div></div></div>"), 
  "<p>--</p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>");
  EXPECT_EQ(GumboParser::normalizeHtml("<div><div><span>John<span> </span></span><b>Doe</b><div><u><i>Software</i></u><span> </span>Engineer</div></div></div>"), 
  "<p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='font-weight: 700'>--</span><br><div><div><span>John<span> </span></span><b>Doe</b><div><u><i>Software</i></u><span> </span>Engineer</div></div></div>"), 
  "<p><b>--</b></p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='font-style: italic'>--</span><br><div><div><span>John<span> </span></span><b>Doe</b><div><u><i>Software</i></u><span> </span>Engineer</div></div></div>"), 
  "<p><i>--</i></p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='font-style: italic; font-weight: bold'>--</span><br><div><div><span>John<span> </span></span><b>Doe</b><div><u><i>Software</i></u><span> </span>Engineer</div></div></div>"), 
  "<p><b><i>--</i></b></p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>");
  EXPECT_EQ(GumboParser::normalizeHtml("<span style='font-style: italic; font-weight: bold; text-decoration: underline'>--</span><br><div><div><span>John<span> </span></span><b>Doe</b><div><u><i>Software</i></u><span> </span>Engineer</div></div></div>"), 
  "<p><b><i><u>--</u></i></b></p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>");

  EXPECT_EQ(GumboParser::normalizeHtml("<div><br>here's more!</div><div><br></div><img src=\"https://example.com/image.png\" alt=\"image.png\" width=\"336\" height=\"297\">"),
  "<br><p>here's more!</p><br><p><img src=\"https://example.com/image.png\" alt=\"image.png\" width=\"336\" height=\"297\" /></p>");

  EXPECT_EQ(GumboParser::normalizeHtml("<div>what do you think of this craziness</div><span><blockquote><div><div><ul><li><b>another one </b>hello<div><br></div><div>hi</div></li></ul></div></div></blockquote></span>"),
  "<p>what do you think of this craziness</p><blockquote><p><b>another one </b>hello</p><p>hi</p></blockquote>");
}

TEST(GumboParserTest, ListFlattening) {
  EXPECT_EQ(GumboParser::normalizeHtml("<ul><ol><li>x</li><li>y</li></ol></ul>"), "<ul><li>x</li><li>y</li></ul>");
  EXPECT_EQ(GumboParser::normalizeHtml("<ul><li>x</li><ol><li>y</li><li>z</li></ol></ul>"), "<ul><li>x</li><li>y</li><li>z</li></ul>");
  EXPECT_EQ(GumboParser::normalizeHtml("<ul><ol><li>x</li><li>y</li></ol><li>z</li></ul>"), "<ul><li>x</li><li>y</li><li>z</li></ul>");
  EXPECT_EQ(GumboParser::normalizeHtml("<ol><li>x</li><ul><li>y</li><li>z</li></ul></ol>"), "<ol><li>x</li><li>y</li><li>z</li></ol>");
  EXPECT_EQ(GumboParser::normalizeHtml("<ol><ul><li>x</li><li>y</li></ul><li>z</li></ol>"), "<ol><li>x</li><li>y</li><li>z</li></ol>");
  EXPECT_EQ(GumboParser::normalizeHtml("<ol><ul data-type='checkbox'><li>x</li><li>y</li></ul><li>z</li></ol>"), "<ol><li>x</li><li>y</li><li>z</li></ol>");
  EXPECT_EQ(GumboParser::normalizeHtml("<ul data-type='checkbox'><ol><li>x</li><li>y</li></ol><li>z</li></ul>"), "<ul data-type=\"checkbox\"><li>x</li><li>y</li><li>z</li></ul>");
  EXPECT_EQ(GumboParser::normalizeHtml("<ul><li>x</li><ol><li>y</li><ul><li>z</li></ul></ol></ul>"), "<ul><li>x</li><li>y</li><li>z</li></ul>");
  EXPECT_EQ(GumboParser::normalizeHtml("<ul><li>x</li><ol><li>y</li><ul data-type='checkbox'><li>z</li></ul></ol></ul>"), "<ul><li>x</li><li>y</li><li>z</li></ul>");
  EXPECT_EQ(GumboParser::normalizeHtml("<ul data-type='checkbox'><li>x</li><ol><li>y</li><ul><li>z</li></ul></ol></ul>"), "<ul data-type=\"checkbox\"><li>x</li><li>y</li><li>z</li></ul>");
  EXPECT_EQ(GumboParser::normalizeHtml("<ul><li><b>another one </b>hi kacper,<div><br></div><div>hi</div></li></ul>"), "<ul><li><b>another one </b>hi kacper,</li><li>hi</li></ul>");
}

TEST(GumboParserTest, BrRemappings) {
  EXPECT_EQ(GumboParser::normalizeHtml("<p><b>Asdasdasd</b></p><br><br><p>Sent with<span> </span><a href='https://google.com'>Net</a></p>"), "<p><b>Asdasdasd</b></p><br><br><p>Sent with <a href=\"https://google.com\">Net</a></p>");
}
