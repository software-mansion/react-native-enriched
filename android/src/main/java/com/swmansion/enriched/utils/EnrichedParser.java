package com.swmansion.enriched.utils;

import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.text.Editable;
import android.text.Layout;
import android.text.Spannable;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.TextUtils;
import android.text.style.AlignmentSpan;
import android.text.style.ParagraphStyle;
import android.util.Log;

import com.swmansion.enriched.spans.EnrichedBlockQuoteSpan;
import com.swmansion.enriched.spans.EnrichedBoldSpan;
import com.swmansion.enriched.spans.EnrichedCodeBlockSpan;
import com.swmansion.enriched.spans.EnrichedH1Span;
import com.swmansion.enriched.spans.EnrichedH2Span;
import com.swmansion.enriched.spans.EnrichedH3Span;
import com.swmansion.enriched.spans.EnrichedH4Span;
import com.swmansion.enriched.spans.EnrichedH5Span;
import com.swmansion.enriched.spans.EnrichedH6Span;
import com.swmansion.enriched.spans.EnrichedImageSpan;
import com.swmansion.enriched.spans.EnrichedInlineCodeSpan;
import com.swmansion.enriched.spans.EnrichedItalicSpan;
import com.swmansion.enriched.spans.EnrichedLinkSpan;
import com.swmansion.enriched.spans.EnrichedMentionSpan;
import com.swmansion.enriched.spans.EnrichedOrderedListSpan;
import com.swmansion.enriched.spans.EnrichedStrikeThroughSpan;
import com.swmansion.enriched.spans.EnrichedUnderlineSpan;
import com.swmansion.enriched.spans.EnrichedUnorderedListSpan;
import com.swmansion.enriched.spans.interfaces.EnrichedBlockSpan;
import com.swmansion.enriched.spans.interfaces.EnrichedParagraphSpan;
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan;
import com.swmansion.enriched.spans.interfaces.EnrichedZeroWidthSpaceSpan;
import com.swmansion.enriched.styles.HtmlStyle;

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
import java.util.Map;

/**
 * Most of the code in this file is copied from the Android source code and adjusted to our needs.
 * For the reference see <a href="https://android.googlesource.com/platform/frameworks/base/+/refs/heads/master/core/java/android/text/Html.java">docs</a>
 */
public class EnrichedParser {
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

  private EnrichedParser() { }
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
  public static Spanned fromHtml(String source, HtmlStyle style, ImageGetter imageGetter) {
    Parser parser = new Parser();
    try {
      parser.setProperty(Parser.schemaProperty, HtmlParser.schema);
    } catch (SAXNotRecognizedException | SAXNotSupportedException e) {
      // Should not happen.
      throw new RuntimeException(e);
    }
    HtmlToSpannedConverter converter = new HtmlToSpannedConverter(source, style, imageGetter, parser);
    return converter.convert();
  }
  public static String toHtml(Spanned text) {
    StringBuilder out = new StringBuilder();
    withinHtml(out, text);
    String outString = out.toString();
    // Codeblocks and blockquotes appends a newline character by default, so we have to remove it
    String normalizedCodeBlock = outString.replaceAll("</codeblock>\\n<br>", "</codeblock>");
    String normalizedBlockQuote = normalizedCodeBlock.replaceAll("</blockquote>\\n<br>", "</blockquote>");
    return "<html>\n" + normalizedBlockQuote + "</html>";
  }
  /**
   * Returns an HTML escaped representation of the given plain text.
   */
  public static String escapeHtml(CharSequence text) {
    StringBuilder out = new StringBuilder();
    withinStyle(out, text, 0, text.length());
    return out.toString();
  }
  private static void withinHtml(StringBuilder out, Spanned text) {
    withinDiv(out, text, 0, text.length());
  }
  private static void withinDiv(StringBuilder out, Spanned text, int start, int end) {
    int next;
    for (int i = start; i < end; i = next) {
      next = text.nextSpanTransition(i, end, EnrichedBlockSpan.class);
      EnrichedBlockSpan[] blocks = text.getSpans(i, next, EnrichedBlockSpan.class);
      String tag = "unknown";
      if (blocks.length > 0){
        tag = blocks[0] instanceof EnrichedCodeBlockSpan ? "codeblock" : "blockquote";
      }

      // Each block appends a newline by default.
      // If we set up a new block, we have to remove the last  character.
      if (out.length() >= 5 && out.substring(out.length() - 5).equals("<br>\n")) {
        out.replace(out.length() - 5, out.length(), "");
      }

      for (EnrichedBlockSpan ignored : blocks) {
        out.append("<").append(tag).append(">\n");
      }
      withinBlock(out, text, i, next);
      for (EnrichedBlockSpan ignored : blocks) {
        out.append("</").append(tag).append(">\n");
      }
    }
  }
  private static String getBlockTag(EnrichedParagraphSpan[] spans) {
    for (EnrichedParagraphSpan span : spans) {
      if (span instanceof EnrichedUnorderedListSpan) {
        return "ul";
      } else if (span instanceof EnrichedOrderedListSpan) {
        return "ol";
      } else if (span instanceof EnrichedH1Span) {
        return "h1";
      } else if (span instanceof EnrichedH2Span) {
        return "h2";
      } else if (span instanceof EnrichedH3Span) {
        return "h3";
      } else if (span instanceof EnrichedH4Span) {
        return "h4";
      } else if (span instanceof EnrichedH5Span) {
        return "h5";
      } else if (span instanceof EnrichedH6Span) {
        return "h6";
      }
    }

    return "p";
  }
  private static void withinBlock(StringBuilder out, Spanned text, int start, int end) {
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
        EnrichedParagraphSpan[] paragraphStyles = text.getSpans(i, next, EnrichedParagraphSpan.class);
        String tag = getBlockTag(paragraphStyles);
        boolean isUlListItem = tag.equals("ul");
        boolean isOlListItem = tag.equals("ol");

        if (isInUlList && !isUlListItem) {
          // Current paragraph is no longer a list item; close the previously opened list
          isInUlList = false;
          out.append("</ul>\n");
        } else if (isInOlList && !isOlListItem) {
          // Current paragraph is no longer a list item; close the previously opened list
          isInOlList = false;
          out.append("</ol>\n");
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

        boolean isList = isUlListItem || isOlListItem;
        String tagType = isList ? "li" : tag;
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
  private static void withinParagraph(StringBuilder out, Spanned text, int start, int end) {
    int next;
    for (int i = start; i < end; i = next) {
      next = text.nextSpanTransition(i, end, EnrichedInlineSpan.class);
      EnrichedInlineSpan[] style = text.getSpans(i, next, EnrichedInlineSpan.class);
      for (int j = 0; j < style.length; j++) {
        if (style[j] instanceof EnrichedBoldSpan) {
          out.append("<b>");
        }
        if (style[j] instanceof EnrichedItalicSpan) {
          out.append("<i>");
        }
        if (style[j] instanceof EnrichedUnderlineSpan) {
          out.append("<u>");
        }
        if (style[j] instanceof EnrichedInlineCodeSpan) {
          out.append("<code>");
        }
        if (style[j] instanceof EnrichedStrikeThroughSpan) {
          out.append("<s>");
        }
        if (style[j] instanceof EnrichedLinkSpan) {
          out.append("<a href=\"");
          out.append(((EnrichedLinkSpan) style[j]).getUrl());
          out.append("\">");
        }
        if (style[j] instanceof EnrichedMentionSpan) {
          out.append("<mention text=\"");
          out.append(((EnrichedMentionSpan) style[j]).getText());
          out.append("\"");

          out.append(" indicator=\"");
          out.append(((EnrichedMentionSpan) style[j]).getIndicator());
          out.append("\"");

          Map<String, String> attributes = ((EnrichedMentionSpan) style[j]).getAttributes();
          for (Map.Entry<String, String> entry : attributes.entrySet()) {
            out.append(" ");
            out.append(entry.getKey());
            out.append("=\"");
            out.append(entry.getValue());
            out.append("\"");
          }

          out.append(">");
        }
        if (style[j] instanceof EnrichedImageSpan) {
          out.append("<img src=\"");
          out.append(((EnrichedImageSpan) style[j]).getSource());
          out.append("\"");

          out.append(" width=\"");
          out.append(((EnrichedImageSpan) style[j]).getWidth());
          out.append("\"");

          out.append(" height=\"");
          out.append(((EnrichedImageSpan) style[j]).getHeight());

          out.append("\"/>");
          // Don't output the placeholder character underlying the image.
          i = next;
        }
      }
      withinStyle(out, text, i, next);
      for (int j = style.length - 1; j >= 0; j--) {
        if (style[j] instanceof EnrichedLinkSpan) {
          out.append("</a>");
        }
        if (style[j] instanceof EnrichedMentionSpan) {
          out.append("</mention>");
        }
        if (style[j] instanceof EnrichedStrikeThroughSpan) {
          out.append("</s>");
        }
        if (style[j] instanceof EnrichedUnderlineSpan) {
          out.append("</u>");
        }
        if (style[j] instanceof EnrichedInlineCodeSpan) {
          out.append("</code>");
        }
        if (style[j] instanceof EnrichedBoldSpan) {
          out.append("</b>");
        }
        if (style[j] instanceof EnrichedItalicSpan) {
          out.append("</i>");
        }
      }
    }
  }
  private static void withinStyle(StringBuilder out, CharSequence text,
                                  int start, int end) {
    for (int i = start; i < end; i++) {
      char c = text.charAt(i);
      if (c == '\u200B') {
        // Do not output zero-width space characters.
        continue;
      } else if (c == '<') {
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
  private final HtmlStyle mStyle;
  private final String mSource;
  private final XMLReader mReader;
  private final SpannableStringBuilder mSpannableStringBuilder;
  private final EnrichedParser.ImageGetter mImageGetter;
  private static Integer currentOrderedListItemIndex = 0;
  private static Boolean isInOrderedList = false;
  private static Boolean isEmptyTag = false;

  public HtmlToSpannedConverter(String source, HtmlStyle style, EnrichedParser.ImageGetter imageGetter, Parser parser) {
    mStyle = style;
    mSource = source;
    mSpannableStringBuilder = new SpannableStringBuilder();
    mImageGetter = imageGetter;
    mReader = parser;
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

    // Assign zero-width space character to the proper spans.
    EnrichedZeroWidthSpaceSpan[] zeroWidthSpaceSpans = mSpannableStringBuilder.getSpans(0, mSpannableStringBuilder.length(), EnrichedZeroWidthSpaceSpan.class);
    for (EnrichedZeroWidthSpaceSpan zeroWidthSpaceSpan : zeroWidthSpaceSpans) {
      int start = mSpannableStringBuilder.getSpanStart(zeroWidthSpaceSpan);
      int end = mSpannableStringBuilder.getSpanEnd(zeroWidthSpaceSpan);

      if (mSpannableStringBuilder.charAt(start) != '\u200B') {
        // Insert zero-width space character at the start if it's not already present.
        mSpannableStringBuilder.insert(start, "\u200B");
        end++; // Adjust end position due to insertion.
      }

      mSpannableStringBuilder.removeSpan(zeroWidthSpaceSpan);
      mSpannableStringBuilder.setSpan(zeroWidthSpaceSpan, start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
    }

    return mSpannableStringBuilder;
  }

  private void handleStartTag(String tag, Attributes attributes) {
    if (tag.equalsIgnoreCase("br")) {
      // We don't need to handle this. TagSoup will ensure that there's a </br> for each <br>
      // so we can safely emit the linebreaks when we handle the close tag.
    } else if (tag.equalsIgnoreCase("p")) {
      isEmptyTag = true;
      startBlockElement(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("ul")) {
      isInOrderedList = false;
      startBlockElement(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("ol")) {
      isInOrderedList = true;
      currentOrderedListItemIndex = 0;
      startBlockElement(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("li")) {
      isEmptyTag = true;
      startLi(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("b")) {
      start(mSpannableStringBuilder, new Bold());
    } else if (tag.equalsIgnoreCase("i")) {
      start(mSpannableStringBuilder, new Italic());
    } else if (tag.equalsIgnoreCase("blockquote")) {
      isEmptyTag = true;
      startBlockquote(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("codeblock")) {
      isEmptyTag = true;
      startCodeBlock(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("a")) {
      startA(mSpannableStringBuilder, attributes);
    } else if (tag.equalsIgnoreCase("u")) {
      start(mSpannableStringBuilder, new Underline());
    } else if (tag.equalsIgnoreCase("s")) {
      start(mSpannableStringBuilder, new Strikethrough());
    } else if (tag.equalsIgnoreCase("strike")) {
      start(mSpannableStringBuilder, new Strikethrough());
    } else if (tag.equalsIgnoreCase("h1")) {
      startHeading(mSpannableStringBuilder, 1);
    } else if (tag.equalsIgnoreCase("h2")) {
      startHeading(mSpannableStringBuilder, 2);
    } else if (tag.equalsIgnoreCase("h3")) {
      startHeading(mSpannableStringBuilder, 3);
    } else if (tag.equalsIgnoreCase("h4")) {
      startHeading(mSpannableStringBuilder, 4);
    } else if (tag.equalsIgnoreCase("h5")) {
      startHeading(mSpannableStringBuilder, 5);
    } else if (tag.equalsIgnoreCase("h6")) {
      startHeading(mSpannableStringBuilder, 6);
    } else if (tag.equalsIgnoreCase("img")) {
      startImg(mSpannableStringBuilder, attributes, mImageGetter);
    } else if (tag.equalsIgnoreCase("code")) {
      start(mSpannableStringBuilder, new Code());
    } else if (tag.equalsIgnoreCase("mention")) {
      startMention(mSpannableStringBuilder, attributes);
    }
  }

  private void handleEndTag(String tag) {
    if (tag.equalsIgnoreCase("br")) {
      handleBr(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("p")) {
      endBlockElement(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("ul")) {
      endBlockElement(mSpannableStringBuilder);
    } else if (tag.equalsIgnoreCase("li")) {
      endLi(mSpannableStringBuilder, mStyle);
    } else if (tag.equalsIgnoreCase("b")) {
      end(mSpannableStringBuilder, Bold.class, new EnrichedBoldSpan(mStyle));
    } else if (tag.equalsIgnoreCase("i")) {
      end(mSpannableStringBuilder, Italic.class, new EnrichedItalicSpan(mStyle));
    } else if (tag.equalsIgnoreCase("blockquote")) {
      endBlockquote(mSpannableStringBuilder, mStyle);
    } else if (tag.equalsIgnoreCase("codeblock")) {
      endCodeBlock(mSpannableStringBuilder, mStyle);
    } else if (tag.equalsIgnoreCase("a")) {
      endA(mSpannableStringBuilder, mStyle);
    } else if (tag.equalsIgnoreCase("u")) {
      end(mSpannableStringBuilder, Underline.class, new EnrichedUnderlineSpan(mStyle));
    } else if (tag.equalsIgnoreCase("s")) {
      end(mSpannableStringBuilder, Strikethrough.class, new EnrichedStrikeThroughSpan(mStyle));
    } else if (tag.equalsIgnoreCase("h1")) {
      endHeading(mSpannableStringBuilder, mStyle, 1);
    } else if (tag.equalsIgnoreCase("h2")) {
      endHeading(mSpannableStringBuilder, mStyle, 2);
    } else if (tag.equalsIgnoreCase("h3")) {
      endHeading(mSpannableStringBuilder, mStyle, 3);
    } else if (tag.equalsIgnoreCase("h4")) {
      endHeading(mSpannableStringBuilder, mStyle, 4);
    } else if (tag.equalsIgnoreCase("h5")) {
      endHeading(mSpannableStringBuilder, mStyle, 5);
    } else if (tag.equalsIgnoreCase("h6")) {
      endHeading(mSpannableStringBuilder, mStyle, 6);
    } else if (tag.equalsIgnoreCase("code")) {
      end(mSpannableStringBuilder, Code.class, new EnrichedInlineCodeSpan(mStyle));
    } else if (tag.equalsIgnoreCase("mention")) {
      endMention(mSpannableStringBuilder, mStyle);
    }
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

  private static void startBlockElement(Editable text) {
      appendNewlines(text, 1);
      start(text, new Newline(1));
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

  private void startLi(Editable text) {
    startBlockElement(text);

    if (isInOrderedList) {
      currentOrderedListItemIndex++;
      start(text, new List("ol", currentOrderedListItemIndex));
    } else {
      start(text, new List("ul", 0));
    }
  }

  private static void endLi(Editable text, HtmlStyle style) {
    endBlockElement(text);

    List l = getLast(text, List.class);
    if (l != null) {
      if (l.mType.equals("ol")) {
        setParagraphSpanFromMark(text, l, new EnrichedOrderedListSpan(l.mIndex, style));
      } else {
        setParagraphSpanFromMark(text, l, new EnrichedUnorderedListSpan(style));
      }
    }

    endBlockElement(text);
  }

  private void startBlockquote(Editable text) {
    startBlockElement(text);
    start(text, new Blockquote());
  }

  private static void endBlockquote(Editable text, HtmlStyle style) {
    endBlockElement(text);
    Blockquote last = getLast(text, Blockquote.class);
    setParagraphSpanFromMark(text, last, new EnrichedBlockQuoteSpan(style));
  }

  private void startCodeBlock(Editable text) {
    startBlockElement(text);
    start(text, new CodeBlock());
  }

  private static void endCodeBlock(Editable text, HtmlStyle style) {
    endBlockElement(text);
    CodeBlock last = getLast(text, CodeBlock.class);
    setParagraphSpanFromMark(text, last, new EnrichedCodeBlockSpan(style));
  }

  private void startHeading(Editable text, int level) {
    startBlockElement(text);

    switch (level) {
      case 1:
        start(text, new H1());
        break;
      case 2:
        start(text, new H2());
        break;
      case 3:
        start(text, new H3());
        break;
      case 4:
        start(text, new H4());
        break;
      case 5:
        start(text, new H5());
        break;
      case 6:
        start(text, new H6());
        break;
      default:
        throw new IllegalArgumentException("Unsupported heading level: " + level);
    }
  }

  private static void endHeading(Editable text, HtmlStyle style, int level) {
    endBlockElement(text);

    switch (level) {
      case 1:
        H1 lastH1 = getLast(text, H1.class);
        setParagraphSpanFromMark(text, lastH1, new EnrichedH1Span(style));
        break;
      case 2:
        H2 lastH2 = getLast(text, H2.class);
        setParagraphSpanFromMark(text, lastH2, new EnrichedH2Span(style));
        break;
      case 3:
        H3 lastH3 = getLast(text, H3.class);
        setParagraphSpanFromMark(text, lastH3, new EnrichedH3Span(style));
        break;
      case 4:
        H4 lastH4 = getLast(text, H4.class);
        setParagraphSpanFromMark(text, lastH4, new EnrichedH4Span(style));
        break;
      case 5:
        H5 lastH5 = getLast(text, H5.class);
        setParagraphSpanFromMark(text, lastH5, new EnrichedH5Span(style));
        break;
      case 6:
        H6 lastH6 = getLast(text, H6.class);
        setParagraphSpanFromMark(text, lastH6, new EnrichedH6Span(style));
        break;
      default:
        throw new IllegalArgumentException("Unsupported heading level: " + level);
    }
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

  private static void setParagraphSpanFromMark(Editable text, Object mark, Object... spans) {
    int where = text.getSpanStart(mark);
    text.removeSpan(mark);
    int len = text.length();

    // Block spans require at least one character to be applied.
    if (isEmptyTag) {
      text.append("\u200B");
      len++;
    }

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

  private static void startImg(Editable text, Attributes attributes, EnrichedParser.ImageGetter img) {
    String src = attributes.getValue("", "src");
    String width = attributes.getValue("", "width");
    String height = attributes.getValue("", "height");

    Drawable d = null;
    if (img != null) {
      d = img.getDrawable(src);
    }

    if (d == null) {
      d = HtmlToSpannedConverter.prepareDrawableForImage(src);
    }

    if (d == null) {
      return;
    }

    int len = text.length();
    text.append("￼");
    text.setSpan(new EnrichedImageSpan(d, src, Integer.parseInt(width), Integer.parseInt(height)), len, text.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
  }

  private static BitmapDrawable prepareDrawableForImage(String src) {
    String cleanPath = src;
    if (cleanPath.startsWith("file://")) {
      cleanPath = cleanPath.substring(7);
    }

    BitmapDrawable drawable = null;

    try {
      Bitmap bitmap = BitmapFactory.decodeFile(cleanPath);
      if (bitmap != null) {
        drawable = new BitmapDrawable(Resources.getSystem(), bitmap);
        // set bounds so it knows how big it is naturally,
        // though EnrichedImageSpan will override this with the HTML width/height later.
        drawable.setBounds(0, 0, bitmap.getWidth(), bitmap.getHeight());
      }
    } catch (Exception e) {
      // Failed to load file
      Log.e("EnrichedParser", "Failed to load image from path: " + cleanPath, e);
    }

    return drawable;
  }

  private static void startA(Editable text, Attributes attributes) {
    String href = attributes.getValue("", "href");
    start(text, new Href(href));
  }

  private void endA(Editable text, HtmlStyle style) {
    Href h = getLast(text, Href.class);
    if (h != null) {
      if (h.mHref != null) {
        setSpanFromMark(text, h, new EnrichedLinkSpan(h.mHref, style));
      }
    }
  }

  private static void startMention(Editable mention, Attributes attributes) {
    String text = attributes.getValue("", "text");
    String indicator = attributes.getValue("", "indicator");

    Map<String, String> attributesMap = new HashMap<>();
    for (int i = 0; i < attributes.getLength(); i++) {
      String localName = attributes.getLocalName(i);

      if (!"text".equals(localName) && !"indicator".equals(localName)) {
        attributesMap.put(localName, attributes.getValue(i));
      }
    }

    start(mention, new Mention(indicator, text, attributesMap));
  }

  private void endMention(Editable text, HtmlStyle style) {
    Mention m = getLast(text, Mention.class);

    if (m == null) return;
    if (m.mText == null) return;

    setSpanFromMark(text, m, new EnrichedMentionSpan(m.mText, m.mIndicator, m.mAttributes, style));
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
    if (length > 0) isEmptyTag = false;

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

  private static class H4 {
  }

  private static class H5 {
  }

  private static class H6 {
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
    public String mIndicator;
    public String mText;

    public Mention(String indicator, String text, Map<String, String> attributes) {
      mIndicator = indicator;
      mAttributes = attributes;
      mText = text;
    }
  }

  private static class Href {
    public String mHref;

    public Href(String href) {
      mHref = href;
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
