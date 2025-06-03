package com.swmansion.reactnativerichtexteditor.utils;

import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.text.Editable;
import android.text.Layout;
import android.text.Spannable;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.TextUtils;
import android.text.style.AlignmentSpan;
import android.text.style.BackgroundColorSpan;
import android.text.style.ForegroundColorSpan;
import android.text.style.ParagraphStyle;
import android.text.style.RelativeSizeSpan;
import android.text.style.TypefaceSpan;

import com.swmansion.reactnativerichtexteditor.spans.EditorBlockQuoteSpan;
import com.swmansion.reactnativerichtexteditor.spans.EditorBoldSpan;
import com.swmansion.reactnativerichtexteditor.spans.EditorCodeBlockSpan;
import com.swmansion.reactnativerichtexteditor.spans.EditorH1Span;
import com.swmansion.reactnativerichtexteditor.spans.EditorH2Span;
import com.swmansion.reactnativerichtexteditor.spans.EditorH3Span;
import com.swmansion.reactnativerichtexteditor.spans.EditorImageSpan;
import com.swmansion.reactnativerichtexteditor.spans.EditorInlineCodeSpan;
import com.swmansion.reactnativerichtexteditor.spans.EditorItalicSpan;
import com.swmansion.reactnativerichtexteditor.spans.EditorLinkSpan;
import com.swmansion.reactnativerichtexteditor.spans.EditorMentionSpan;
import com.swmansion.reactnativerichtexteditor.spans.EditorOrderedListSpan;
import com.swmansion.reactnativerichtexteditor.spans.EditorStrikeThroughSpan;
import com.swmansion.reactnativerichtexteditor.spans.EditorUnderlineSpan;
import com.swmansion.reactnativerichtexteditor.spans.EditorUnorderedListSpan;
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorParagraphSpan;
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorSpan;

import org.ccil.cowan.tagsoup.HTMLSchema;
import org.ccil.cowan.tagsoup.Parser;
import org.xml.sax.Attributes;
import org.xml.sax.ContentHandler;
import org.xml.sax.InputSource;
import org.xml.sax.Locator;
import org.xml.sax.SAXException;
import org.xml.sax.SAXNotRecognizedException;
import org.xml.sax.SAXNotSupportedException;
import org.xml.sax.XMLReader;

import java.io.IOException;
import java.io.StringReader;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Most of the code in this file is copied from the Android source code and adjusted to our needs.
 * For the reference see <a href="https://android.googlesource.com/platform/frameworks/base/+/refs/heads/master/core/java/android/text/Html.java">docs</a>
 */
public class EditorParser {
  /**
   * Retrieves images for HTML &lt;img&gt; tags.
   */
  public interface ImageGetter {
    /**
     * This method is called when the HTML parser encounters an
     * &lt;img&gt; tag.  The <code>source</code> argument is the
     * string from the "src" attribute; the return value should be
     * a Drawable representation of the image or <code>null</code>
     * for a generic replacement image.  Make sure you call
     * setBounds() on your Drawable if it doesn't already have
     * its bounds set.
     */
    Drawable getDrawable(String source);
  }

  /**
   * Is notified when HTML tags are encountered that the parser does
   * not know how to interpret.
   */
  public interface TagHandler {
    /**
     * This method will be called whenn the HTML parser encounters
     * a tag that it does not know how to interpret.
     */
    void handleTag(boolean opening, String tag,
                   Editable output, XMLReader xmlReader);
  }
  /**
   * Option for {@link #toHtml(Spanned, int)}: Wrap consecutive lines of text delimited by '\n'
   * inside &lt;p&gt; elements. {@link EditorUnorderedListSpan}s are ignored.
   */
  public static final int TO_HTML_PARAGRAPH_LINES_CONSECUTIVE = 0x00000000;
  /**
   * Option for {@link #toHtml(Spanned, int)}: Wrap each line of text delimited by '\n' inside a
   * &lt;p&gt; or a &lt;li&gt; element. This allows {@link ParagraphStyle}s attached to be
   * encoded as CSS styles within the corresponding &lt;p&gt; or &lt;li&gt; element.
   */
  public static final int TO_HTML_PARAGRAPH_LINES_INDIVIDUAL = 0x00000001;
  /**
   * Flag indicating that texts inside &lt;p&gt; elements will be separated from other texts with
   * one newline character by default.
   */
  public static final int FROM_HTML_SEPARATOR_LINE_BREAK_PARAGRAPH = 0x00000001;
  /**
   * Flag indicating that texts inside &lt;h1&gt;~&lt;h6&gt; elements will be separated from
   * other texts with one newline character by default.
   */
  public static final int FROM_HTML_SEPARATOR_LINE_BREAK_HEADING = 0x00000002;
  /**
   * Flag indicating that texts inside &lt;li&gt; elements will be separated from other texts
   * with one newline character by default.
   */
  public static final int FROM_HTML_SEPARATOR_LINE_BREAK_LIST_ITEM = 0x00000004;
  /**
   * Flag indicating that texts inside &lt;ul&gt; elements will be separated from other texts
   * with one newline character by default.
   */
  public static final int FROM_HTML_SEPARATOR_LINE_BREAK_LIST = 0x00000008;
  /**
   * Flag indicating that texts inside &lt;div&gt; elements will be separated from other texts
   * with one newline character by default.
   */
  public static final int FROM_HTML_SEPARATOR_LINE_BREAK_DIV = 0x00000010;
  /**
   * Flag indicating that texts inside &lt;blockquote&gt; elements will be separated from other
   * texts with one newline character by default.
   */
  public static final int FROM_HTML_SEPARATOR_LINE_BREAK_BLOCKQUOTE = 0x00000020;
  /**
   * Flag indicating that CSS color values should be used instead of those defined in
   * {@link Color}.
   */
  public static final int FROM_HTML_OPTION_USE_CSS_COLORS = 0x00000100;
  /**
   * Flags for {@link #fromHtml(String, int, ImageGetter, TagHandler)}: Separate block-level
   * elements with line breaks (single newline character) in between. This inverts the
   * {@link Spanned} to HTML string conversion done with the option
   * {@link #TO_HTML_PARAGRAPH_LINES_INDIVIDUAL}.
   */
  public static final int FROM_HTML_MODE_COMPACT =
    FROM_HTML_SEPARATOR_LINE_BREAK_PARAGRAPH
      | FROM_HTML_SEPARATOR_LINE_BREAK_HEADING
      | FROM_HTML_SEPARATOR_LINE_BREAK_LIST_ITEM
      | FROM_HTML_SEPARATOR_LINE_BREAK_LIST
      | FROM_HTML_SEPARATOR_LINE_BREAK_DIV
      | FROM_HTML_SEPARATOR_LINE_BREAK_BLOCKQUOTE;
  /**
   * The bit which indicates if lines delimited by '\n' will be grouped into &lt;p&gt; elements.
   */
  private static final int TO_HTML_PARAGRAPH_FLAG = 0x00000001;
  private EditorParser() { }
  /**
   * Returns displayable styled text from the provided HTML string. Any &lt;img&gt; tags in the
   * HTML will display as a generic replacement image which your program can then go through and
   * replace with real images.
   *
   * <p>This uses TagSoup to handle real HTML, including all of the brokenness found in the wild.
   */
  public static Spanned fromHtml(String source, int flags) {
    return fromHtml(source, flags, null, null);
  }
  /**
   * Lazy initialization holder for HTML parser. This class will
   * a) be preloaded by the zygote, or b) not loaded until absolutely
   * necessary.
   */
  private static class HtmlParser {
    private static final HTMLSchema schema = new HTMLSchema();
  }
  /**
   * Returns displayable styled text from the provided HTML string. Any &lt;img&gt; tags in the
   * HTML will use the specified ImageGetter to request a representation of the image (use null
   * if you don't want this) and the specified TagHandler to handle unknown tags (specify null if
   * you don't want this).
   *
   * <p>This uses TagSoup to handle real HTML, including all of the brokenness found in the wild.
   */
  public static Spanned fromHtml(String source, int flags, ImageGetter imageGetter, TagHandler tagHandler) {
    Parser parser = new Parser();
    try {
      parser.setProperty(Parser.schemaProperty, HtmlParser.schema);
    } catch (SAXNotRecognizedException | SAXNotSupportedException e) {
      // Should not happen.
      throw new RuntimeException(e);
    }
    HtmlToSpannedConverter converter =
      new HtmlToSpannedConverter(source, imageGetter, tagHandler, parser, flags);
    return converter.convert();
  }
  /**
   * Returns an HTML representation of the provided Spanned text. A best effort is
   * made to add HTML tags corresponding to spans. Also note that HTML metacharacters
   * (such as "&lt;" and "&amp;") within the input text are escaped.
   *
   * @param text input text to convert
   * @param option one of {@link #TO_HTML_PARAGRAPH_LINES_CONSECUTIVE} or
   *     {@link #TO_HTML_PARAGRAPH_LINES_INDIVIDUAL}
   * @return string containing input converted to HTML
   */
  public static String toHtml(Spanned text, int option) {
    StringBuilder out = new StringBuilder();
    withinHtml(out, text, option);
    String outString = out.toString();
    return "<html>" + outString + "</html>";
  }
  /**
   * Returns an HTML escaped representation of the given plain text.
   */
  public static String escapeHtml(CharSequence text) {
    StringBuilder out = new StringBuilder();
    withinStyle(out, text, 0, text.length());
    return out.toString();
  }
  private static void withinHtml(StringBuilder out, Spanned text, int option) {
    if ((option & TO_HTML_PARAGRAPH_FLAG) == TO_HTML_PARAGRAPH_LINES_CONSECUTIVE) {
      encodeTextAlignmentByDiv(out, text, option);
      return;
    }
    withinDiv(out, text, 0, text.length(), option);
  }
  private static void encodeTextAlignmentByDiv(StringBuilder out, Spanned text, int option) {
    int len = text.length();
    int next;
    for (int i = 0; i < len; i = next) {
      next = text.nextSpanTransition(i, len, ParagraphStyle.class);
      ParagraphStyle[] style = text.getSpans(i, next, ParagraphStyle.class);
      String elements = " ";
      boolean needDiv = false;
      for(int j = 0; j < style.length; j++) {
        if (style[j] instanceof AlignmentSpan) {
          Layout.Alignment align =
            ((AlignmentSpan) style[j]).getAlignment();
          needDiv = true;
          if (align == Layout.Alignment.ALIGN_CENTER) {
            elements = "align=\"center\" " + elements;
          } else if (align == Layout.Alignment.ALIGN_OPPOSITE) {
            elements = "align=\"right\" " + elements;
          } else {
            elements = "align=\"left\" " + elements;
          }
        }
      }
      if (needDiv) {
        out.append("<div ").append(elements).append(">");
      }
      withinDiv(out, text, i, next, option);
      if (needDiv) {
        out.append("</div>");
      }
    }
  }
  private static void withinDiv(StringBuilder out, Spanned text, int start, int end,
                                int option) {
    int next;
    for (int i = start; i < end; i = next) {
      next = text.nextSpanTransition(i, end, EditorParagraphSpan.class);
      EditorParagraphSpan[] blocks = text.getSpans(i, next, EditorParagraphSpan.class);
      String tag = "unknown";
      if (blocks.length > 0){
        tag = blocks[0] instanceof EditorCodeBlockSpan ? "codeblock" : "blockquote";
      }

      for (EditorParagraphSpan ignored : blocks) {
        out.append("<").append(tag).append(">");
      }
      withinBlock(out, text, i, next, option);
      for (EditorParagraphSpan ignored : blocks) {
        out.append("</").append(tag).append(">\n");
      }
    }
  }
  private static String getTextStyles(Spanned text, int start, int end,
                                      boolean forceNoVerticalMargin, boolean includeTextAlign) {
    String margin = null;
    String textAlign = null;
    if (forceNoVerticalMargin) {
      margin = "margin-top:0; margin-bottom:0;";
    }
    if (includeTextAlign) {
      final AlignmentSpan[] alignmentSpans = text.getSpans(start, end, AlignmentSpan.class);
      // Only use the last AlignmentSpan with flag SPAN_PARAGRAPH
      for (int i = alignmentSpans.length - 1; i >= 0; i--) {
        AlignmentSpan s = alignmentSpans[i];
        if ((text.getSpanFlags(s) & Spanned.SPAN_PARAGRAPH) == Spanned.SPAN_PARAGRAPH) {
          final Layout.Alignment alignment = s.getAlignment();
          if (alignment == Layout.Alignment.ALIGN_NORMAL) {
            textAlign = "text-align:start;";
          } else if (alignment == Layout.Alignment.ALIGN_CENTER) {
            textAlign = "text-align:center;";
          } else if (alignment == Layout.Alignment.ALIGN_OPPOSITE) {
            textAlign = "text-align:end;";
          }
          break;
        }
      }
    }
    if (margin == null && textAlign == null) {
      return "";
    }
    final StringBuilder style = new StringBuilder(" style=\"");
    if (margin != null && textAlign != null) {
      style.append(margin).append(" ").append(textAlign);
    } else if (margin != null) {
      style.append(margin);
    } else {
      style.append(textAlign);
    }
    return style.append("\"").toString();
  }
  private static void withinBlock(StringBuilder out, Spanned text, int start, int end,
                                  int option) {
    if ((option & TO_HTML_PARAGRAPH_FLAG) == TO_HTML_PARAGRAPH_LINES_CONSECUTIVE) {
      withinBlockConsecutive(out, text, start, end);
    } else {
      withinBlockIndividual(out, text, start, end);
    }
  }
  private static void withinBlockIndividual(StringBuilder out, Spanned text, int start,
                                            int end) {
    boolean isInUlList = false;
    boolean isInOlList = false;
    int next;
    for (int i = start; i <= end; i = next) {
      next = TextUtils.indexOf(text, '\n', i, end);
      if (next < 0) {
        next = end;
      }
      if (next == i) {
        if (isInUlList) {
          // Current paragraph is no longer a list item; close the previously opened list
          isInUlList = false;
          out.append("</ul>\n");
        } else if (isInOlList) {
          // Current paragraph is no longer a list item; close the previously opened list
          isInOlList = false;
          out.append("</ol>\n");
        }
        out.append("<br>\n");
      } else {
        boolean isUlListItem = false;
        boolean isOlListItem = false;
        ParagraphStyle[] paragraphStyles = text.getSpans(i, next, ParagraphStyle.class);
        for (ParagraphStyle paragraphStyle : paragraphStyles) {
          if (paragraphStyle instanceof EditorUnorderedListSpan) {
            isUlListItem = true;
            break;
          } else if (paragraphStyle instanceof EditorOrderedListSpan) {
            isOlListItem = true;
            break;
          }
        }
        if (isUlListItem && !isInUlList) {
          // Current paragraph is the first item in a list
          isInUlList = true;
          out.append("<ul").append(">\n");
        } else if (isOlListItem && !isInOlList) {
          // Current paragraph is the first item in a list
          isInOlList = true;
          out.append("<ol").append(">\n");
        }
        if (isInUlList && !isUlListItem) {
          // Current paragraph is no longer a list item; close the previously opened list
          isInUlList = false;
          out.append("</ul>\n");
        } else if (isInOlList && !isOlListItem) {
          // Current paragraph is no longer a list item; close the previously opened list
          isInOlList = false;
          out.append("</ol>\n");
        }
        boolean isList = isUlListItem || isOlListItem;
        String tagType = isList ? "li" : "p";
        out.append("<");

        out.append(tagType);

        out.append(">");
        withinParagraph(out, text, i, next);
        out.append("</");
        out.append(tagType);
        out.append(">\n");
        if (next == end && isInUlList) {
          isInUlList = false;
          out.append("</ul>\n");
        } else if (next == end && isInOlList) {
          isInOlList = false;
          out.append("</ol>\n");
        }
      }
      next++;
    }
  }
  private static void withinBlockConsecutive(StringBuilder out, Spanned text, int start,
                                             int end) {
    out.append("<p>");
    int next;
    for (int i = start; i < end; i = next) {
      next = TextUtils.indexOf(text, '\n', i, end);
      if (next < 0) {
        next = end;
      }
      int nl = 0;
      while (next < end && text.charAt(next) == '\n') {
        nl++;
        next++;
      }
      withinParagraph(out, text, i, next - nl);
      if (nl == 1) {
        out.append("<br>\n");
      } else {
        for (int j = 2; j < nl; j++) {
          out.append("<br>");
        }
        if (next != end) {
          /* Paragraph should be closed and reopened */
          out.append("</p>\n");
          out.append("<p>");
        }
      }
    }
    out.append("</p>\n");
  }
  private static void withinParagraph(StringBuilder out, Spanned text, int start, int end) {
    int next;
    for (int i = start; i < end; i = next) {
      next = text.nextSpanTransition(i, end, EditorSpan.class);
      EditorSpan[] style = text.getSpans(i, next, EditorSpan.class);
      for (int j = 0; j < style.length; j++) {
        if (style[j] instanceof EditorBoldSpan) {
          out.append("<b>");
        }
        if (style[j] instanceof EditorItalicSpan) {
          out.append("<i>");
        }
        if (style[j] instanceof EditorUnderlineSpan) {
          out.append("<u>");
        }
        if (style[j] instanceof EditorInlineCodeSpan) {
          out.append("<code>");
        }
        if (style[j] instanceof EditorH1Span) {
          out.append("<h1>");
        }
        if (style[j] instanceof EditorH2Span) {
          out.append("<h2>");
        }
        if (style[j] instanceof EditorH3Span) {
          out.append("<h3>");
        }
        if (style[j] instanceof EditorStrikeThroughSpan) {
          out.append("<s>");
        }
        if (style[j] instanceof EditorLinkSpan) {
          out.append("<a href=\"");
          out.append(((EditorLinkSpan) style[j]).getUrl());
          out.append("\">");
        }
        if (style[j] instanceof EditorMentionSpan) {
          out.append("<mention text=\"");
          out.append(((EditorMentionSpan) style[j]).getText());
          out.append("\"");

          Map<String, String> attributes = ((EditorMentionSpan) style[j]).getAttributes();
          for (Map.Entry<String, String> entry : attributes.entrySet()) {
            out.append(" ");
            out.append(entry.getKey());
            out.append("=\"");
            out.append(entry.getValue());
            out.append("\"");
          }

          out.append(">");
        }
        if (style[j] instanceof EditorImageSpan) {
          out.append("<img src=\"");
          out.append(((EditorImageSpan) style[j]).getSource());
          out.append("\">");
          // Don't output the placeholder character underlying the image.
          i = next;
        }
      }
      withinStyle(out, text, i, next);
      for (int j = style.length - 1; j >= 0; j--) {
        if (style[j] instanceof EditorLinkSpan) {
          out.append("</a>");
        }
        if (style[j] instanceof EditorMentionSpan) {
          out.append("</mention>");
        }
        if (style[j] instanceof EditorStrikeThroughSpan) {
          out.append("</s>");
        }
        if (style[j] instanceof EditorUnderlineSpan) {
          out.append("</u>");
        }
        if (style[j] instanceof EditorInlineCodeSpan) {
          out.append("</code>");
        }
        if (style[j] instanceof EditorH1Span) {
          out.append("</h1>");
        }
        if (style[j] instanceof EditorH2Span) {
          out.append("</h2>");
        }
        if (style[j] instanceof EditorH3Span) {
          out.append("</h3>");
        }
        if (style[j] instanceof EditorBoldSpan) {
          out.append("</b>");
        }
        if (style[j] instanceof EditorItalicSpan) {
          out.append("</i>");
        }
      }
    }
  }

  private static void withinStyle(StringBuilder out, CharSequence text,
                                  int start, int end) {
    for (int i = start; i < end; i++) {
      char c = text.charAt(i);
      if (c == '<') {
        out.append("&lt;");
      } else if (c == '>') {
        out.append("&gt;");
      } else if (c == '&') {
        out.append("&amp;");
      } else if (c >= 0xD800 && c <= 0xDFFF) {
        if (c < 0xDC00 && i + 1 < end) {
          char d = text.charAt(i + 1);
          if (d >= 0xDC00 && d <= 0xDFFF) {
            i++;
            int codepoint = 0x010000 | (int) c - 0xD800 << 10 | (int) d - 0xDC00;
            out.append("&#").append(codepoint).append(";");
          }
        }
      } else if (c > 0x7E || c < ' ') {
        out.append("&#").append((int) c).append(";");
      } else if (c == ' ') {
        while (i + 1 < end && text.charAt(i + 1) == ' ') {
          out.append("&nbsp;");
          i++;
        }
        out.append(' ');
      } else {
        out.append(c);
      }
    }
  }
}
class HtmlToSpannedConverter implements ContentHandler {
  private static final float[] HEADING_SIZES = {
    1.5f, 1.4f, 1.3f, 1.2f, 1.1f, 1f,
  };
  private final String mSource;
  private final XMLReader mReader;
  private final SpannableStringBuilder mSpannableStringBuilder;
  private final EditorParser.ImageGetter mImageGetter;
  private final EditorParser.TagHandler mTagHandler;
  private final int mFlags;
  private static Pattern sTextAlignPattern;
  private static Pattern sForegroundColorPattern;
  private static Pattern sBackgroundColorPattern;
  private static Pattern sTextDecorationPattern;
  /**
   * Name-value mapping of HTML/CSS colors which have different values in {@link Color}.
   */
  private static final Map<String, Integer> sColorMap;

  private static Integer currentOrderedListItemIndex = 0;
  private static Boolean isInOrderedList = false;

  static {
    sColorMap = new HashMap<>();
    sColorMap.put("darkgray", 0xFFA9A9A9);
    sColorMap.put("gray", 0xFF808080);
    sColorMap.put("lightgray", 0xFFD3D3D3);
    sColorMap.put("darkgrey", 0xFFA9A9A9);
    sColorMap.put("grey", 0xFF808080);
    sColorMap.put("lightgrey", 0xFFD3D3D3);
    sColorMap.put("green", 0xFF008000);
  }

  private static Pattern getTextAlignPattern() {
    if (sTextAlignPattern == null) {
      sTextAlignPattern = Pattern.compile("(?:\\s+|\\A)text-align\\s*:\\s*(\\S*)\\b");
    }
    return sTextAlignPattern;
  }

  private static Pattern getForegroundColorPattern() {
    if (sForegroundColorPattern == null) {
      sForegroundColorPattern = Pattern.compile(
        "(?:\\s+|\\A)color\\s*:\\s*(\\S*)\\b");
    }
    return sForegroundColorPattern;
  }

  private static Pattern getBackgroundColorPattern() {
    if (sBackgroundColorPattern == null) {
      sBackgroundColorPattern = Pattern.compile(
        "(?:\\s+|\\A)background(?:-color)?\\s*:\\s*(\\S*)\\b");
    }
    return sBackgroundColorPattern;
  }

  private static Pattern getTextDecorationPattern() {
    if (sTextDecorationPattern == null) {
      sTextDecorationPattern = Pattern.compile(
        "(?:\\s+|\\A)text-decoration\\s*:\\s*(\\S*)\\b");
    }
    return sTextDecorationPattern;
  }

  public HtmlToSpannedConverter(String source, EditorParser.ImageGetter imageGetter, EditorParser.TagHandler tagHandler, Parser parser, int flags) {
    mSource = source;
    mSpannableStringBuilder = new SpannableStringBuilder();
    mImageGetter = imageGetter;
    mTagHandler = tagHandler;
    mReader = parser;
    mFlags = flags;
  }

  public Spanned convert() {
    mReader.setContentHandler(this);
    try {
      mReader.parse(new InputSource(new StringReader(mSource)));
    } catch (IOException e) {
      // We are reading from a string. There should not be IO problems.
      throw new RuntimeException(e);
    } catch (SAXException e) {
      // TagSoup doesn't throw parse exceptions.
      throw new RuntimeException(e);
    }
    // Fix flags and range for paragraph-type markup.
    Object[] obj = mSpannableStringBuilder.getSpans(0, mSpannableStringBuilder.length(), ParagraphStyle.class);
    for (int i = 0; i < obj.length; i++) {
      int start = mSpannableStringBuilder.getSpanStart(obj[i]);
      int end = mSpannableStringBuilder.getSpanEnd(obj[i]);
      // If the last line of the range is blank, back off by one.
      if (end - 2 >= 0) {
        if (mSpannableStringBuilder.charAt(end - 1) == '\n' &&
          mSpannableStringBuilder.charAt(end - 2) == '\n') {
          end--;
        }
      }
      if (end == start) {
        mSpannableStringBuilder.removeSpan(obj[i]);
      } else {
        // TODO: verify if Spannable.SPAN_EXCLUSIVE_EXCLUSIVE does not break anything.
        // Previously it was SPAN_PARAGRAPH. I've changed that in order to fix ranges for list items.
        mSpannableStringBuilder.setSpan(obj[i], start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
      }
    }
    return mSpannableStringBuilder;
  }

  private void handleStartTag(String tag, Attributes attributes) {
    if (tag.equalsIgnoreCase("br")) {
      // We don't need to handle this. TagSoup will ensure that there's a </br> for each <br>
      // so we can safely emit the linebreaks when we handle the close tag.
    } else if (tag.equalsIgnoreCase("p")) {
      startBlockElement(mSpannableStringBuilder, attributes, getMarginParagraph());
      startCssStyle(mSpannableStringBuilder, attributes);
    } else if (tag.equalsIgnoreCase("ul")) {
      isInOrderedList = false;
      startBlockElement(mSpannableStringBuilder, attributes, getMarginList());
    } else if (tag.equalsIgnoreCase("ol")) {
      isInOrderedList = true;
      currentOrderedListItemIndex = 0;
      startBlockElement(mSpannableStringBuilder, attributes, getMarginList());
    } else if (tag.equalsIgnoreCase("li")) {
      startLi(mSpannableStringBuilder, attributes);
    } else if (tag.equalsIgnoreCase("div")) {
      startBlockElement(mSpannableStringBuilder, attributes, getMarginDiv());
    } else if (tag.equalsIgnoreCase("span")) {
      startCssStyle(mSpannableStringBuilder, attributes);
    } else if (tag.equalsIgnoreCase("b")) {
      start(mSpannableStringBuilder, new Bold());
    } else if (tag.equalsIgnoreCase("i")) {
      start(mSpannableStringBuilder, new Italic());
    } else if (tag.equalsIgnoreCase("font")) {
      startFont(mSpannableStringBuilder, attributes);
    } else if (tag.equalsIgnoreCase("blockquote")) {
      startBlockquote(mSpannableStringBuilder, attributes);
    } else if (tag.equalsIgnoreCase("codeblock")) {
      startCodeBlock(mSpannableStringBuilder, attributes);
    } else if (tag.equalsIgnoreCase("a")) {
      startA(mSpannableStringBuilder, attributes);
    } else if (tag.equalsIgnoreCase("u")) {
      start(mSpannableStringBuilder, new Underline());
    } else if (tag.equalsIgnoreCase("s")) {
      start(mSpannableStringBuilder, new Strikethrough());
    } else if (tag.equalsIgnoreCase("strike")) {
      start(mSpannableStringBuilder, new Strikethrough());
    } else if (tag.equalsIgnoreCase("h1")) {
      start(mSpannableStringBuilder, new H1());
    } else if (tag.equalsIgnoreCase("h2")) {
      start(mSpannableStringBuilder, new H2());
    } else if (tag.equalsIgnoreCase("h3")) {
      start(mSpannableStringBuilder, new H3());
    } else if (tag.equalsIgnoreCase("img")) {
      startImg(mSpannableStringBuilder, attributes, mImageGetter);
    } else if (tag.equalsIgnoreCase("code")) {
      start(mSpannableStringBuilder, new Code());
    } else if (tag.equalsIgnoreCase("mention")) {
      startMention(mSpannableStringBuilder, attributes);
    } else if (mTagHandler != null) {
      mTagHandler.handleTag(true, tag, mSpannableStringBuilder, mReader);
    }
  }

  private void handleEndTag(String tag) {
    if (tag.equalsIgnoreCase("br")) {
      handleBr(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("p")) {
      endCssStyle(mSpannableStringBuilder);
      endBlockElement(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("ul")) {
      endBlockElement(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("li")) {
      endLi(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("div")) {
      endBlockElement(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("span")) {
      endCssStyle(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("b")) {
      end(mSpannableStringBuilder, Bold.class, new EditorBoldSpan());
    } else if (tag.equalsIgnoreCase("i")) {
      end(mSpannableStringBuilder, Italic.class, new EditorItalicSpan());
    } else if (tag.equalsIgnoreCase("font")) {
      endFont(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("blockquote")) {
      endBlockquote(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("codeblock")) {
      endCodeBlock(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("a")) {
      endA(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("u")) {
      end(mSpannableStringBuilder, Underline.class, new EditorUnderlineSpan());
    } else if (tag.equalsIgnoreCase("s")) {
      end(mSpannableStringBuilder, Strikethrough.class, new EditorStrikeThroughSpan());
    } else if (tag.equalsIgnoreCase("h1")) {
      end(mSpannableStringBuilder, H1.class, new EditorH1Span());
    } else if (tag.equalsIgnoreCase("h2")) {
      end(mSpannableStringBuilder, H2.class, new EditorH2Span());
    } else if (tag.equalsIgnoreCase("h3")) {
      end(mSpannableStringBuilder, H3.class, new EditorH3Span());
    } else if (tag.equalsIgnoreCase("code")) {
      end(mSpannableStringBuilder, Code.class, new EditorInlineCodeSpan());
    } else if (tag.equalsIgnoreCase("mention")) {
      endMention(mSpannableStringBuilder);
    } else if (mTagHandler != null) {
      mTagHandler.handleTag(false, tag, mSpannableStringBuilder, mReader);
    }
  }

  private int getMarginParagraph() {
    return getMargin(EditorParser.FROM_HTML_SEPARATOR_LINE_BREAK_PARAGRAPH);
  }

  private int getMarginHeading() {
    return getMargin(EditorParser.FROM_HTML_SEPARATOR_LINE_BREAK_HEADING);
  }

  private int getMarginListItem() {
    return getMargin(EditorParser.FROM_HTML_SEPARATOR_LINE_BREAK_LIST_ITEM);
  }

  private int getMarginList() {
    return getMargin(EditorParser.FROM_HTML_SEPARATOR_LINE_BREAK_LIST);
  }

  private int getMarginDiv() {
    return getMargin(EditorParser.FROM_HTML_SEPARATOR_LINE_BREAK_DIV);
  }

  private int getMarginBlockquote() {
    return getMargin(EditorParser.FROM_HTML_SEPARATOR_LINE_BREAK_BLOCKQUOTE);
  }

  /**
   * Returns the minimum number of newline characters needed before and after a given block-level
   * element.
   *
   * @param flag the corresponding option flag defined in {@link EditorParser} of a block-level element
   */
  private int getMargin(int flag) {
    if ((flag & mFlags) != 0) {
      return 1;
    }
    return 2;
  }

  private static void appendNewlines(Editable text, int minNewline) {
    final int len = text.length();
    if (len == 0) {
      return;
    }
    int existingNewlines = 0;
    for (int i = len - 1; i >= 0 && text.charAt(i) == '\n'; i--) {
      existingNewlines++;
    }
    for (int j = existingNewlines; j < minNewline; j++) {
      text.append("\n");
    }
  }

  private static void startBlockElement(Editable text, Attributes attributes, int margin) {
    if (margin > 0) {
      appendNewlines(text, margin);
      start(text, new Newline(margin));
    }
    String style = attributes.getValue("", "style");
    if (style != null) {
      Matcher m = getTextAlignPattern().matcher(style);
      if (m.find()) {
        String alignment = m.group(1);
        if (alignment.equalsIgnoreCase("start")) {
          start(text, new Alignment(Layout.Alignment.ALIGN_NORMAL));
        } else if (alignment.equalsIgnoreCase("center")) {
          start(text, new Alignment(Layout.Alignment.ALIGN_CENTER));
        } else if (alignment.equalsIgnoreCase("end")) {
          start(text, new Alignment(Layout.Alignment.ALIGN_OPPOSITE));
        }
      }
    }
  }

  private static void endBlockElement(Editable text) {
    Newline n = getLast(text, Newline.class);
    if (n != null) {
      appendNewlines(text, n.mNumNewlines);
      text.removeSpan(n);
    }
    Alignment a = getLast(text, Alignment.class);
    if (a != null) {
      setSpanFromMark(text, a, new AlignmentSpan.Standard(a.mAlignment));
    }
  }

  private static void handleBr(Editable text) {
    text.append('\n');
  }

  private void startLi(Editable text, Attributes attributes) {
    startBlockElement(text, attributes, getMarginListItem());

    if (isInOrderedList) {
      currentOrderedListItemIndex++;
      start(text, new List("ol", currentOrderedListItemIndex));
    } else {
      start(text, new List("ul", 0));
    }

    startCssStyle(text, attributes);
  }

  private static void endLi(Editable text) {
    endCssStyle(text);
    endBlockElement(text);

    List l = getLast(text, List.class);
    if (l != null) {
      if (l.mType.equals("ol")) {
        setListSpanFromMark(text, l, new EditorOrderedListSpan(l.mIndex));
      } else {
        setListSpanFromMark(text, l, new EditorUnorderedListSpan());
      }
    }

    endBlockElement(text);
  }

  private void startBlockquote(Editable text, Attributes attributes) {
    startBlockElement(text, attributes, getMarginBlockquote());
    start(text, new Blockquote());
  }

  private static void endBlockquote(Editable text) {
    endBlockElement(text);
    end(text, Blockquote.class, new EditorBlockQuoteSpan());
  }

  private void startCodeBlock(Editable text, Attributes attributes) {
    startBlockElement(text, attributes, getMarginBlockquote());
    start(text, new CodeBlock());
    ;
  }

  private static void endCodeBlock(Editable text) {
    endBlockElement(text);
    end(text, CodeBlock.class, new EditorCodeBlockSpan());
  }

  private void startHeading(Editable text, Attributes attributes, int level) {
    startBlockElement(text, attributes, getMarginHeading());
    start(text, new Heading(level));
  }

  private static void endHeading(Editable text) {
    // RelativeSizeSpan and StyleSpan are CharacterStyles
    // Their ranges should not include the newlines at the end
    Heading h = getLast(text, Heading.class);
    if (h != null) {
      setSpanFromMark(text, h, new RelativeSizeSpan(HEADING_SIZES[h.mLevel]),
        new EditorBoldSpan());
    }
    endBlockElement(text);
  }

  private static <T> T getLast(Spanned text, Class<T> kind) {
    /*
     * This knows that the last returned object from getSpans()
     * will be the most recently added.
     */
    T[] objs = text.getSpans(0, text.length(), kind);
    if (objs.length == 0) {
      return null;
    } else {
      return objs[objs.length - 1];
    }
  }

  private static void setSpanFromMark(Spannable text, Object mark, Object... spans) {
    int where = text.getSpanStart(mark);
    text.removeSpan(mark);
    int len = text.length();
    if (where != len) {
      for (Object span : spans) {
        text.setSpan(span, where, len, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
      }
    }
  }

  private static void setListSpanFromMark(Spannable text, Object mark, Object... spans) {
    int where = text.getSpanStart(mark);
    text.removeSpan(mark);
    int len = text.length();

    // Adjust the end position to exclude the newline character, if present
    if (len > 0 && text.charAt(len - 1) == '\n') {
      len--;
    }

    if (where != len) {
      for (Object span : spans) {
        text.setSpan(span, where, len, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
      }
    }
  }

  private static void start(Editable text, Object mark) {
    int len = text.length();
    text.setSpan(mark, len, len, Spannable.SPAN_INCLUSIVE_EXCLUSIVE);
  }

  private static void end(Editable text, Class kind, Object repl) {
    Object obj = getLast(text, kind);
    if (obj != null) {
      setSpanFromMark(text, obj, repl);
    }
  }

  private void startCssStyle(Editable text, Attributes attributes) {
    String style = attributes.getValue("", "style");
    if (style != null) {
      Matcher m = getForegroundColorPattern().matcher(style);
      if (m.find()) {
        int c = getHtmlColor(m.group(1));
        if (c != -1) {
          start(text, new Foreground(c | 0xFF000000));
        }
      }
      m = getBackgroundColorPattern().matcher(style);
      if (m.find()) {
        int c = getHtmlColor(m.group(1));
        if (c != -1) {
          start(text, new Background(c | 0xFF000000));
        }
      }
      m = getTextDecorationPattern().matcher(style);
      if (m.find()) {
        String textDecoration = m.group(1);
        if (textDecoration.equalsIgnoreCase("line-through")) {
          start(text, new EditorStrikeThroughSpan());
        }
      }
    }
  }

  private static void endCssStyle(Editable text) {
    Strikethrough s = getLast(text, Strikethrough.class);
    if (s != null) {
      setSpanFromMark(text, s, new EditorStrikeThroughSpan());
    }
    Background b = getLast(text, Background.class);
    if (b != null) {
      setSpanFromMark(text, b, new BackgroundColorSpan(b.mBackgroundColor));
    }
    Foreground f = getLast(text, Foreground.class);
    if (f != null) {
      setSpanFromMark(text, f, new ForegroundColorSpan(f.mForegroundColor));
    }
  }

  private static void startImg(Editable text, Attributes attributes, EditorParser.ImageGetter img) {
    String src = attributes.getValue("", "src");
    Drawable d = null;
    if (img != null) {
      d = img.getDrawable(src);
    }

    if (d == null) {
      return;
    }

    int len = text.length();
    text.append("￼");
    text.setSpan(new EditorImageSpan(d, src), len, text.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
  }

  private void startFont(Editable text, Attributes attributes) {
    String color = attributes.getValue("", "color");
    String face = attributes.getValue("", "face");
    if (!TextUtils.isEmpty(color)) {
      int c = getHtmlColor(color);
      if (c != -1) {
        start(text, new Foreground(c | 0xFF000000));
      }
    }
    if (!TextUtils.isEmpty(face)) {
      start(text, new Font(face));
    }
  }

  private static void endFont(Editable text) {
    Font font = getLast(text, Font.class);
    if (font != null) {
      setSpanFromMark(text, font, new TypefaceSpan(font.mFace));
    }
    Foreground foreground = getLast(text, Foreground.class);
    if (foreground != null) {
      setSpanFromMark(text, foreground,
        new ForegroundColorSpan(foreground.mForegroundColor));
    }
  }

  private static void startA(Editable text, Attributes attributes) {
    String href = attributes.getValue("", "href");
    start(text, new Href(href));
  }

  private void endA(Editable text) {
    Href h = getLast(text, Href.class);
    if (h != null) {
      if (h.mHref != null) {
        setSpanFromMark(text, h, new EditorLinkSpan(h.mHref));
      }
    }
  }

  private static void startMention(Editable mention, Attributes attributes) {
    String text = attributes.getValue("", "text");

    Map<String, String> attributesMap = new HashMap<>();
    for (int i = 0; i < attributes.getLength(); i++) {
      if (!"text".equals(attributes.getLocalName(i))) {
        attributesMap.put(attributes.getLocalName(i), attributes.getValue(i));
      }
    }

    start(mention, new Mention(text, attributesMap));
  }

  private void endMention(Editable text) {
    Mention m = getLast(text, Mention.class);

    if (m == null) return;
    if (m.mText == null) return;

    setSpanFromMark(text, m, new EditorMentionSpan(m.mText, m.mAttributes));
  }

  private int getHtmlColor(String color) {
    if ((mFlags & EditorParser.FROM_HTML_OPTION_USE_CSS_COLORS)
      == EditorParser.FROM_HTML_OPTION_USE_CSS_COLORS) {
      Integer i = sColorMap.get(color.toLowerCase(Locale.US));
      if (i != null) {
        return i;
      }
    }
    try {
      return Color.parseColor(color);
    } catch (IllegalArgumentException e) {
      return -1;
    }
  }

  public void setDocumentLocator(Locator locator) {
  }

  public void startDocument() {
  }

  public void endDocument() {
  }

  public void startPrefixMapping(String prefix, String uri) {
  }

  public void endPrefixMapping(String prefix) {
  }

  public void startElement(String uri, String localName, String qName, Attributes attributes) {
    handleStartTag(localName, attributes);
  }

  public void endElement(String uri, String localName, String qName) {
    handleEndTag(localName);
  }

  public void characters(char[] ch, int start, int length) {
    StringBuilder sb = new StringBuilder();
    /*
     * Ignore whitespace that immediately follows other whitespace;
     * newlines count as spaces.
     */
    for (int i = 0; i < length; i++) {
      char c = ch[i + start];
      if (c == ' ' || c == '\n') {
        char pred;
        int len = sb.length();
        if (len == 0) {
          len = mSpannableStringBuilder.length();
          if (len == 0) {
            pred = '\n';
          } else {
            pred = mSpannableStringBuilder.charAt(len - 1);
          }
        } else {
          pred = sb.charAt(len - 1);
        }
        if (pred != ' ' && pred != '\n') {
          sb.append(' ');
        }
      } else {
        sb.append(c);
      }
    }
    mSpannableStringBuilder.append(sb);
  }

  public void ignorableWhitespace(char[] ch, int start, int length) {
  }

  public void processingInstruction(String target, String data) {
  }

  public void skippedEntity(String name) {
  }

  private static class H1 {
  }

  private static class H2 {
  }

  private static class H3 {
  }

  private static class Bold {
  }

  private static class Italic {
  }

  private static class Underline {
  }

  private static class Code {
  }

  private static class CodeBlock {
  }

  private static class Strikethrough {
  }

  private static class Blockquote {
  }

  private static class List {
    public int mIndex;
    public String mType;

    public List(String type, int index) {
      mType = type;
      mIndex = index;
    }
  }

  private static class Mention {
    public Map<String, String> mAttributes;
    public String mText;

    public Mention(String text, Map<String, String> attributes) {
      mAttributes = attributes;
      mText = text;
    }
  }

  private static class Font {
    public String mFace;

    public Font(String face) {
      mFace = face;
    }
  }

  private static class Href {
    public String mHref;

    public Href(String href) {
      mHref = href;
    }
  }

  private static class Foreground {
    private final int mForegroundColor;

    public Foreground(int foregroundColor) {
      mForegroundColor = foregroundColor;
    }
  }

  private static class Background {
    private final int mBackgroundColor;

    public Background(int backgroundColor) {
      mBackgroundColor = backgroundColor;
    }
  }

  private static class Heading {
    private final int mLevel;

    public Heading(int level) {
      mLevel = level;
    }
  }

  private static class Newline {
    private final int mNumNewlines;

    public Newline(int numNewlines) {
      mNumNewlines = numNewlines;
    }
  }

  private static class Alignment {
    private final Layout.Alignment mAlignment;

    public Alignment(Layout.Alignment alignment) {
      mAlignment = alignment;
    }
  }
}
