#include <gtest/gtest.h>
#include "LexborParser.hpp"

TEST(LexborParserTest, TagRemappings) {
  EXPECT_EQ(LexborParser::normalizeHtml("<strong>x</strong>"), "<b>x</b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<em>x</em>"), "<i>x</i>");
  EXPECT_EQ(LexborParser::normalizeHtml("<del>x</del>"), "<s>x</s>");
  EXPECT_EQ(LexborParser::normalizeHtml("<strike>x</strike>"), "<s>x</s>");
  EXPECT_EQ(LexborParser::normalizeHtml("<ins>x</ins>"), "<u>x</u>");
  EXPECT_EQ(LexborParser::normalizeHtml("<pre>x</pre>"), "<codeblock><p>x</p></codeblock>");
}

TEST(LexborParserTest, GoogleDocsWrapper) {
  EXPECT_EQ(LexborParser::normalizeHtml("<b id=\"docs-internal-guid-1234567890\">x</b>"), "x");
  EXPECT_EQ(LexborParser::normalizeHtml("<b id=\"docs-internal-guid-1234567890\"></b>"), "");
}

TEST(LexborParserTest, TagOmissions) {
  EXPECT_EQ(LexborParser::normalizeHtml("<meta name='author' content='John Doe'>"), "");
  EXPECT_EQ(LexborParser::normalizeHtml("<style></style>"), "");
  EXPECT_EQ(LexborParser::normalizeHtml("<script></script>"), "");
  EXPECT_EQ(LexborParser::normalizeHtml("<title></title>"), "");
  EXPECT_EQ(LexborParser::normalizeHtml("<link rel='stylesheet' href='styles.css'>"), "");
  EXPECT_EQ(LexborParser::normalizeHtml("<html></html>"), "");
  EXPECT_EQ(LexborParser::normalizeHtml("<body></body>"), "");
  EXPECT_EQ(LexborParser::normalizeHtml("<head></head>"), "");

  // Nested tags
  EXPECT_EQ(LexborParser::normalizeHtml("<html><head></head><body></body></html>"), "");
  EXPECT_EQ(LexborParser::normalizeHtml("<html><body><p>x</p></body></html>"), "<p>x</p>");
  EXPECT_EQ(LexborParser::normalizeHtml("<html><p>x</p></html>"), "<p>x</p>");
  EXPECT_EQ(LexborParser::normalizeHtml("<body><p>x</p></body>"), "<p>x</p>");
}

TEST(LexborParserTest, TableOmissions) {
  EXPECT_EQ(LexborParser::normalizeHtml("<table></table>"), "");
  EXPECT_EQ(LexborParser::normalizeHtml("<thead></thead>"), "");
  EXPECT_EQ(LexborParser::normalizeHtml("<tbody></tbody>"), "");
  EXPECT_EQ(LexborParser::normalizeHtml("<tfoot></tfoot>"), "");
  EXPECT_EQ(LexborParser::normalizeHtml("<tr></tr>"), "");
  EXPECT_EQ(LexborParser::normalizeHtml("<td></td>"), "");
  EXPECT_EQ(LexborParser::normalizeHtml("<th></th>"), "");
  EXPECT_EQ(LexborParser::normalizeHtml("<caption></caption>"), "");
  EXPECT_EQ(LexborParser::normalizeHtml("<colgroup></colgroup>"), "");
  EXPECT_EQ(LexborParser::normalizeHtml("<col></col>"), "");

  EXPECT_EQ(
    LexborParser::normalizeHtml(
        "<table style=\"width:100%\"><tr><td>Emil</td><td>Tobias</td><td>Linus</td></tr></table>"),
    "<p>Emil Tobias Linus</p>");

EXPECT_EQ(
    LexborParser::normalizeHtml(
        "<table><tr><td>Emil</td><td>Tobias</td><td>Linus</td></tr>"
        "<tr><td>16</td><td>14</td><td>10</td></tr></table>"),
    "<p>Emil Tobias Linus</p><p>16 14 10</p>");

  EXPECT_EQ(LexborParser::normalizeHtml("<table><tr><th>Person 1</th><th>Person 2</th><th>Person 3</th></tr><tr><td>Emil</td><td>Tobias</td><td>Linus</td></tr><tr><td>16</td><td>14</td><td>10</td></tr></table>"),
  "<p>Person 1 Person 2 Person 3</p><p>Emil Tobias Linus</p><p>16 14 10</p>");
}

TEST(LexborParserTest, SpanRemappings) {
  // Bold
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"font-weight: bold;\">x</span>"), "<b>x</b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"font-weight: bold\">x</span>"), "<b>x</b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='font-weight: bold'>x</span>"), "<b>x</b>");

  // Italic
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"font-style: italic;\">x</span>"), "<i>x</i>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"font-style: italic\">x</span>"), "<i>x</i>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='font-style: italic'>x</span>"), "<i>x</i>");

  // Underline
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"text-decoration: underline;\">x</span>"), "<u>x</u>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"text-decoration: underline\">x</span>"), "<u>x</u>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='text-decoration: underline'>x</span>"), "<u>x</u>");

  // Strikethrough
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"text-decoration: line-through;\">x</span>"), "<s>x</s>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"text-decoration: line-through\">x</span>"), "<s>x</s>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='text-decoration: line-through'>x</span>"), "<s>x</s>");

  // Bold and Italic
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"font-weight: bold; font-style: italic;\">x</span>"), "<b><i>x</i></b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"font-weight: bold; font-style: italic\">x</span>"), "<b><i>x</i></b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='font-weight: bold; font-style: italic'>x</span>"), "<b><i>x</i></b>");

  // Italic and Bold
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"font-style: italic; font-weight: bold;\">x</span>"), "<b><i>x</i></b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"font-style: italic; font-weight: bold\">x</span>"), "<b><i>x</i></b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='font-style: italic; font-weight: bold'>x</span>"), "<b><i>x</i></b>");

  // Bold and Underline
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"font-weight: bold; text-decoration: underline;\">x</span>"), "<b><u>x</u></b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"font-weight: bold; text-decoration: underline\">x</span>"), "<b><u>x</u></b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='font-weight: bold; text-decoration: underline'>x</span>"), "<b><u>x</u></b>");

  // Underline and Bold
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"text-decoration: underline; font-weight: bold;\">x</span>"), "<b><u>x</u></b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"text-decoration: underline; font-weight: bold\">x</span>"), "<b><u>x</u></b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='text-decoration: underline; font-weight: bold'>x</span>"), "<b><u>x</u></b>");

  // Bold and Strikethrough
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"font-weight: bold; text-decoration: line-through;\">x</span>"), "<b><s>x</s></b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"font-weight: bold; text-decoration: line-through\">x</span>"), "<b><s>x</s></b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='font-weight: bold; text-decoration: line-through'>x</span>"), "<b><s>x</s></b>");

  // Strikethrough and Bold
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"text-decoration: line-through; font-weight: bold;\">x</span>"), "<b><s>x</s></b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"text-decoration: line-through; font-weight: bold\">x</span>"), "<b><s>x</s></b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='text-decoration: line-through; font-weight: bold'>x</span>"), "<b><s>x</s></b>");

  // Underline and Strikethrough
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"text-decoration: underline; text-decoration: line-through;\">x</span>"), "<u><s>x</s></u>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"text-decoration: underline; text-decoration: line-through\">x</span>"), "<u><s>x</s></u>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='text-decoration: underline; text-decoration: line-through'>x</span>"), "<u><s>x</s></u>");

  // Strikethrough and Underline
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"text-decoration: line-through; text-decoration: underline;\">x</span>"), "<u><s>x</s></u>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"text-decoration: line-through; text-decoration: underline\">x</span>"), "<u><s>x</s></u>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='text-decoration: line-through; text-decoration: underline'>x</span>"), "<u><s>x</s></u>");

  // Combined
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"font-weight: bold; font-style: italic; text-decoration: underline;\">x</span>"), "<b><i><u>x</u></i></b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style=\"font-weight: bold; font-style: italic; text-decoration: underline\">x</span>"), "<b><i><u>x</u></i></b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='font-weight: bold; font-style: italic; text-decoration: underline'>x</span>"), "<b><i><u>x</u></i></b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='font-weight: bold; text-decoration: underline; font-style: italic;'>x</span>"), "<b><i><u>x</u></i></b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='text-decoration: underline; font-weight: bold; font-style: italic;'>x</span>"), "<b><i><u>x</u></i></b>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='text-decoration: line-through; font-weight: bold; font-style: italic;'>x</span>"), "<b><i><s>x</s></i></b>");
}

TEST(LexborParserTest, EnrichedTagRemappings) {
  // Block elements
  EXPECT_EQ(LexborParser::normalizeHtml("<codeblock>x</codeblock>"), "<codeblock><p>x</p></codeblock>");
  EXPECT_EQ(LexborParser::normalizeHtml("<codeblock><p>x</p></codeblock>"), "<codeblock><p>x</p></codeblock>");
  EXPECT_EQ(LexborParser::normalizeHtml("<blockquote>x</blockquote>"), "<blockquote><p>x</p></blockquote>");
  EXPECT_EQ(LexborParser::normalizeHtml("<blockquote><p>x</p></blockquote>"), "<blockquote><p>x</p></blockquote>");

  // Headings
  EXPECT_EQ(LexborParser::normalizeHtml("<h1>x</h1>"), "<h1>x</h1>");
  EXPECT_EQ(LexborParser::normalizeHtml("<h2>x</h2>"), "<h2>x</h2>");
  EXPECT_EQ(LexborParser::normalizeHtml("<h3>x</h3>"), "<h3>x</h3>");
  EXPECT_EQ(LexborParser::normalizeHtml("<h4>x</h4>"), "<h4>x</h4>");
  EXPECT_EQ(LexborParser::normalizeHtml("<h5>x</h5>"), "<h5>x</h5>");
  EXPECT_EQ(LexborParser::normalizeHtml("<h6>x</h6>"), "<h6>x</h6>");

  // Self-closing tags
  EXPECT_EQ(LexborParser::normalizeHtml("<br>"), "<br>");
  EXPECT_EQ(LexborParser::normalizeHtml("<img src=\"x\" width=\"100\" height=\"100\" />"), "<img src=\"x\" width=\"100\" height=\"100\" />");
  EXPECT_EQ(LexborParser::normalizeHtml("<img src='x' width='100' height='100' />"), "<img src=\"x\" width=\"100\" height=\"100\" />");

  // Lists
  EXPECT_EQ(LexborParser::normalizeHtml("<ul><li>x</li></ul>"), "<ul><li>x</li></ul>");
  EXPECT_EQ(LexborParser::normalizeHtml("<ol><li>x</li></ol>"), "<ol><li>x</li></ol>");

  // Checkbox lists
  EXPECT_EQ(LexborParser::normalizeHtml("<ul data-type='checkbox'><li>x</li></ul>"), "<ul data-type=\"checkbox\"><li>x</li></ul>");
  EXPECT_EQ(LexborParser::normalizeHtml("<ul data-type=\"checkbox\"><li>x</li></ul>"), "<ul data-type=\"checkbox\"><li>x</li></ul>");
  EXPECT_EQ(LexborParser::normalizeHtml("<ul data-type='checkbox'><li checked>x</li></ul>"), "<ul data-type=\"checkbox\"><li checked>x</li></ul>");
  EXPECT_EQ(LexborParser::normalizeHtml("<ul data-type=\"checkbox\"><li checked>x</li></ul>"), "<ul data-type=\"checkbox\"><li checked>x</li></ul>");

  // Mentions
  EXPECT_EQ(LexborParser::normalizeHtml("<mention text='@John Doe' indicator='@' id='1'>@John Doe</mention>"), "<mention id=\"1\" text=\"@John Doe\" indicator=\"@\">@John Doe</mention>");
  EXPECT_EQ(LexborParser::normalizeHtml("<mention text=\"@John Doe\" indicator=\"@\" id=\"1\">@John Doe</mention>"), "<mention id=\"1\" text=\"@John Doe\" indicator=\"@\">@John Doe</mention>");

  // Link
  EXPECT_EQ(LexborParser::normalizeHtml("<a href=\"https://www.google.com\">Google</a>"), "<a href=\"https://www.google.com\">Google</a>");
  EXPECT_EQ(LexborParser::normalizeHtml("<a href='https://www.google.com'>Google</a>"), "<a href=\"https://www.google.com\">Google</a>");

  // Inline 
  EXPECT_EQ(LexborParser::normalizeHtml("<code>x</code>"), "<code>x</code>");
  EXPECT_EQ(LexborParser::normalizeHtml("<s>x</s>"), "<s>x</s>");
  EXPECT_EQ(LexborParser::normalizeHtml("<u>x</u>"), "<u>x</u>");
  EXPECT_EQ(LexborParser::normalizeHtml("<i>x</i>"), "<i>x</i>");
  EXPECT_EQ(LexborParser::normalizeHtml("<b>x</b>"), "<b>x</b>");
}

TEST(LexborParserTest, DivRemappings) {
  EXPECT_EQ(LexborParser::normalizeHtml("<div>x</div>"), "<p>x</p>");
  EXPECT_EQ(LexborParser::normalizeHtml("<div><p>x</p></div>"), "<p>x</p>");
  EXPECT_EQ(LexborParser::normalizeHtml("<div><p>x</p><p>y</p></div>"), "<p>x</p><p>y</p>");
  EXPECT_EQ(LexborParser::normalizeHtml("<div><p>x</p><p>y</p></div>"), "<p>x</p><p>y</p>");
  EXPECT_EQ(LexborParser::normalizeHtml("<div><span>x</span></div>"), "<p>x</p>");
  EXPECT_EQ(LexborParser::normalizeHtml("<div><div><span>x</span></div><span>y</span></div>"), "<p>x</p><p>y</p>");

  // Without whitespace
  EXPECT_EQ(LexborParser::normalizeHtml("<span>--</span><br><div><div><span>John<span> </span></span><b>Doe</b><div><u><i>Software</i></u><span> </span>Engineer</div></div></div>"), 
  "<p>--</p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>");
  EXPECT_EQ(LexborParser::normalizeHtml("<div><div><span>John<span> </span></span><b>Doe</b><div><u><i>Software</i></u><span> </span>Engineer</div></div></div>"), 
  "<p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='font-weight: 700'>--</span><br><div><div><span>John<span> </span></span><b>Doe</b><div><u><i>Software</i></u><span> </span>Engineer</div></div></div>"), 
  "<p><b>--</b></p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='font-style: italic'>--</span><br><div><div><span>John<span> </span></span><b>Doe</b><div><u><i>Software</i></u><span> </span>Engineer</div></div></div>"), 
  "<p><i>--</i></p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='font-style: italic; font-weight: bold'>--</span><br><div><div><span>John<span> </span></span><b>Doe</b><div><u><i>Software</i></u><span> </span>Engineer</div></div></div>"), 
  "<p><b><i>--</i></b></p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>");
  EXPECT_EQ(LexborParser::normalizeHtml("<span style='font-style: italic; font-weight: bold; text-decoration: underline'>--</span><br><div><div><span>John<span> </span></span><b>Doe</b><div><u><i>Software</i></u><span> </span>Engineer</div></div></div>"), 
  "<p><b><i><u>--</u></i></b></p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>");
  

  // With whitespace
  EXPECT_EQ(LexborParser::normalizeHtml(R"(
    <span>--</span>
    <br>
    <div>
      <div>
        <span>John<span> </span></span>
        <b>Doe</b>
        <div>
          <u><i>Software</i></u>
          <span> </span>Engineer
        </div>
      </div>
    </div>
  )"), "<p>--</p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>");

  EXPECT_EQ(LexborParser::normalizeHtml(R"(
    <div>
      <div>
        <span>John<span> </span></span>
        <b>Doe</b>
        <div>
          <u><i>Software</i></u>
          <span> </span>Engineer
        </div>
      </div>
    </div>
  )"), "<p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>");

  EXPECT_EQ(LexborParser::normalizeHtml(R"(
    <span style='font-weight: 700'>--</span>
    <br>
    <div>
      <div>
        <span>John<span> </span></span>
        <b>Doe</b>
        <div>
          <u><i>Software</i></u>
          <span> </span>Engineer
        </div>
      </div>
    </div>
  )"), "<p><b>--</b></p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>");

  EXPECT_EQ(LexborParser::normalizeHtml(R"(
    <span style='font-style: italic'>--</span>
    <br>
    <div>
      <div>
        <span>John<span> </span></span>
        <b>Doe</b>
        <div>
          <u><i>Software</i></u>
          <span> </span>Engineer
        </div>
      </div>
    </div>
  )"), "<p><i>--</i></p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>");

  EXPECT_EQ(LexborParser::normalizeHtml(R"(
    <span style='font-style: italic; font-weight: bold'>--</span>
    <br>
    <div>
      <div>
        <span>John<span> </span></span>
        <b>Doe</b>
        <div>
          <u><i>Software</i></u>
          <span> </span>Engineer
        </div>
      </div>
    </div>
  )"), "<p><b><i>--</i></b></p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>");

  EXPECT_EQ(LexborParser::normalizeHtml(R"(
    <span font-style='italic' font-weight='bold' text-decoration='underline'>--</span>
    <br>
    <div>
      <div>
        <span>John<span> </span></span>
        <b>Doe</b>
        <div>
          <u><i>Software</i></u>
          <span> </span>Engineer
        </div>
      </div>
    </div>
  )"), "<p><b><i><u>--</u></i></b></p><p>John <b>Doe</b></p><p><u><i>Software</i></u> Engineer</p>");
}

TEST(LexborParserTest, ListFlattening) {
  EXPECT_EQ(LexborParser::normalizeHtml(R"(
    <ul>
      <ol>
        <li>x</li>
        <li>y</li>
      </ol>
    </ul>
  )"), "<ul><li>x</li><li>y</li></ul>");


  EXPECT_EQ(LexborParser::normalizeHtml(R"(
    <ul>
      <li>x</li>
      <ol>
        <li>y</li>
        <li>z</li>
      </ol>
    </ul>
  )"), "<ul><li>x</li><li>y</li><li>z</li></ul>");


  EXPECT_EQ(LexborParser::normalizeHtml(R"(
    <ul>
      <ol>
        <li>x</li>
        <li>y</li>
      </ol>
      <li>z</li>
    </ul>
  )"), "<ul><li>x</li><li>y</li><li>z</li></ul>");

  EXPECT_EQ(LexborParser::normalizeHtml(R"(
    <ol>
      <li>x</li>
      <ul>
        <li>y</li>
        <li>z</li>
      </ul>
    </ol>
  )"), "<ol><li>x</li><li>y</li><li>z</li></ol>");

  EXPECT_EQ(LexborParser::normalizeHtml(R"(
    <ol>
      <ul>
        <li>x</li>
        <li>y</li>
      </ul>
      <li>z</li>
    </ol>
  )"), "<ol><li>x</li><li>y</li><li>z</li></ol>");

  EXPECT_EQ(LexborParser::normalizeHtml(R"(
    <ol>
      <ul data-type='checkbox'>
        <li>x</li>
        <li>y</li>
      </ul>
      <li>z</li>
    </ol>
  )"), "<ol><li>x</li><li>y</li><li>z</li></ol>");

  EXPECT_EQ(LexborParser::normalizeHtml(R"(
    <ul data-type='checkbox'>
      <ol>
        <li>x</li>
        <li>y</li>
      </ol>
      <li>z</li>
    </ul>
  )"), "<ul data-type=\"checkbox\"><li>x</li><li>y</li><li>z</li></ul>");

  EXPECT_EQ(LexborParser::normalizeHtml(R"(
    <ul>
      <li>x</li>
      <ol>
        <li>y</li>
        <ul>
          <li>z</li>
        </ul>
      </ol>
    </ul>
  )"), "<ul><li>x</li><li>y</li><li>z</li></ul>");

  EXPECT_EQ(LexborParser::normalizeHtml(R"(
    <ul>
      <li>x</li>
      <ol>
        <li>y</li>
        <ul data-type='checkbox'>
          <li>z</li>
        </ul>
      </ol>
    </ul>
  )"), "<ul><li>x</li><li>y</li><li>z</li></ul>");

  EXPECT_EQ(LexborParser::normalizeHtml(R"(
    <ul data-type='checkbox'>
      <li>x</li>
      <ol>
        <li>y</li>
        <ul>
          <li>z</li>
        </ul>
      </ol>
    </ul>
  )"), "<ul data-type=\"checkbox\"><li>x</li><li>y</li><li>z</li></ul>");
}