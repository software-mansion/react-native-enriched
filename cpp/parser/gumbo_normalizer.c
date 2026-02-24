/**
 * gumbo_normalizer.c
 *
 * Gumbo-based HTML normalizer (C implementation).
 * Converts arbitrary external HTML into the canonical subset that our enriched
 * parser understands.
 */

#define GUMBO_IMPLEMENTATION

#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
#elif defined(__GNUC__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wall"
#pragma GCC diagnostic ignored "-Wextra"
#endif

#include "gumpo-parser.h"

#ifdef __clang__
#pragma clang diagnostic pop
#elif defined(__GNUC__)
#pragma GCC diagnostic pop
#endif

#include <ctype.h>
#include <stdlib.h>
#include <string.h>

/* ------------------------------------------------------------------ */
/*  Dynamic string buffer                                              */
/* ------------------------------------------------------------------ */

typedef struct {
  char *data;
  size_t len;
  size_t cap;
} buffer_t;

static buffer_t buffer_create(size_t initial_cap) {
  buffer_t b;
  b.cap = initial_cap > 64 ? initial_cap : 64;
  b.data = (char *)malloc(b.cap);
  b.len = 0;
  if (b.data)
    b.data[0] = '\0';
  return b;
}

static void buffer_ensure(buffer_t *b, size_t extra) {
  if (b->len + extra + 1 > b->cap) {
    while (b->len + extra + 1 > b->cap)
      b->cap *= 2;
    b->data = (char *)realloc(b->data, b->cap);
  }
}

static void buffer_append(buffer_t *b, const char *s, size_t n) {
  if (!s || n == 0)
    return;
  buffer_ensure(b, n);
  memcpy(b->data + b->len, s, n);
  b->len += n;
  b->data[b->len] = '\0';
}

static void buffer_append_str(buffer_t *b, const char *s) {
  if (!s)
    return;
  buffer_append(b, s, strlen(s));
}

static void buffer_clear(buffer_t *b) {
  b->len = 0;
  b->data[0] = '\0';
}

static char *buffer_finish(buffer_t *b) { return b->data; /* caller owns */ }

/* ------------------------------------------------------------------ */
/*  Tag classification helpers                                         */
/* ------------------------------------------------------------------ */

typedef enum {
  TAG_CLASS_SKIP,         /* tag stripped, children processed    */
  TAG_CLASS_INLINE,       /* canonical inline tag                */
  TAG_CLASS_BLOCK,        /* canonical block tag                 */
  TAG_CLASS_SELF_CLOSING, /* e.g. <br>, <img>                   */
  TAG_CLASS_PASS,         /* pass-through (e.g. <html>, <body>) */
} tag_class_t;

static const char *canonical_name(const char *name) {
  if (strcmp(name, "strong") == 0)
    return "b";
  if (strcmp(name, "em") == 0)
    return "i";
  if (strcmp(name, "del") == 0 || strcmp(name, "strike") == 0)
    return "s";
  if (strcmp(name, "ins") == 0)
    return "u";
  if (strcmp(name, "pre") == 0)
    return "codeblock";
  return NULL;
}

static tag_class_t classify_tag(const char *name) {
  if (strcmp(name, "b") == 0 || strcmp(name, "i") == 0 ||
      strcmp(name, "u") == 0 || strcmp(name, "s") == 0 ||
      strcmp(name, "code") == 0 || strcmp(name, "a") == 0 ||
      strcmp(name, "strong") == 0 || strcmp(name, "em") == 0 ||
      strcmp(name, "del") == 0 || strcmp(name, "strike") == 0 ||
      strcmp(name, "ins") == 0 || strcmp(name, "mention") == 0)
    return TAG_CLASS_INLINE;

  if (strcmp(name, "p") == 0 || strcmp(name, "h1") == 0 ||
      strcmp(name, "h2") == 0 || strcmp(name, "h3") == 0 ||
      strcmp(name, "h4") == 0 || strcmp(name, "h5") == 0 ||
      strcmp(name, "h6") == 0 || strcmp(name, "ul") == 0 ||
      strcmp(name, "ol") == 0 || strcmp(name, "li") == 0 ||
      strcmp(name, "blockquote") == 0 || strcmp(name, "codeblock") == 0 ||
      strcmp(name, "pre") == 0)
    return TAG_CLASS_BLOCK;

  if (strcmp(name, "br") == 0 || strcmp(name, "img") == 0)
    return TAG_CLASS_SELF_CLOSING;

  if (strcmp(name, "html") == 0 || strcmp(name, "head") == 0 ||
      strcmp(name, "body") == 0)
    return TAG_CLASS_PASS;

  return TAG_CLASS_SKIP;
}

/* ------------------------------------------------------------------ */
/*  DOM helpers — get tag name, node type checks                       */
/* ------------------------------------------------------------------ */

static bool is_element(GumboNode *node) {
  return node && (node->type == GUMBO_NODE_ELEMENT ||
                  node->type == GUMBO_NODE_TEMPLATE);
}

static bool is_text(GumboNode *node) {
  return node &&
         (node->type == GUMBO_NODE_TEXT || node->type == GUMBO_NODE_WHITESPACE);
}

/** Get the lowercased tag name of an element node into buf. */
static const char *get_tag_name(GumboNode *node, char *buf, size_t buf_sz) {
  if (!is_element(node))
    return NULL;
  GumboElement *el = &node->v.element;

  if (el->tag != GUMBO_TAG_UNKNOWN) {
    const char *name = gumbo_normalized_tagname(el->tag);
    if (name && name[0]) {
      size_t n = strlen(name);
      if (n >= buf_sz)
        n = buf_sz - 1;
      memcpy(buf, name, n);
      buf[n] = '\0';
      return buf;
    }
  }

  /* Unknown tag — extract from original_tag */
  GumboStringPiece piece = el->original_tag;
  gumbo_tag_from_original_text(&piece);
  if (piece.data && piece.length > 0) {
    size_t n = piece.length < buf_sz - 1 ? piece.length : buf_sz - 1;
    for (size_t i = 0; i < n; i++)
      buf[i] = (char)tolower((unsigned char)piece.data[i]);
    buf[n] = '\0';
    return buf;
  }
  return NULL;
}

static bool is_list_node(GumboNode *node) {
  char buf[64];
  const char *n = get_tag_name(node, buf, sizeof(buf));
  return n && (strcmp(n, "ul") == 0 || strcmp(n, "ol") == 0);
}

static bool is_blockquote_node(GumboNode *node) {
  char buf[64];
  const char *n = get_tag_name(node, buf, sizeof(buf));
  return n && strcmp(n, "blockquote") == 0;
}

static bool is_br_node(GumboNode *node) {
  char buf[64];
  const char *n = get_tag_name(node, buf, sizeof(buf));
  return n && strcmp(n, "br") == 0;
}

static bool is_block_producing(GumboNode *node) {
  char buf[64];
  const char *n = get_tag_name(node, buf, sizeof(buf));
  if (!n)
    return false;
  if (classify_tag(n) == TAG_CLASS_BLOCK)
    return true;
  return strcmp(n, "div") == 0 || strcmp(n, "table") == 0 ||
         strcmp(n, "tr") == 0;
}

/** True if all children are inline/text (no block-producing elements). */
static bool is_purely_inline(GumboNode *node) {
  if (!is_element(node))
    return true;
  GumboVector *children = &node->v.element.children;
  for (unsigned int i = 0; i < children->length; i++) {
    if (is_block_producing(children->data[i]))
      return false;
  }
  return true;
}

/** True if any direct child is block-producing or a blockquote. */
static bool has_block_or_bq_child(GumboNode *node) {
  if (!is_element(node))
    return false;
  GumboVector *children = &node->v.element.children;
  for (unsigned int i = 0; i < children->length; i++) {
    GumboNode *c = children->data[i];
    if (is_block_producing(c) || is_blockquote_node(c))
      return true;
  }
  return false;
}

/* ------------------------------------------------------------------ */
/*  CSS style → canonical tag mapping  (simple string matching)        */
/* ------------------------------------------------------------------ */

typedef struct {
  bool bold;
  bool italic;
  bool underline;
  bool strikethrough;
} css_styles_t;

static const char *find_css_value(const char *style, size_t style_len,
                                  const char *prop_name, size_t *val_len) {
  size_t plen = strlen(prop_name);
  const char *end = style + style_len;
  const char *p = style;
  while (p < end) {
    while (p < end &&
           (*p == ' ' || *p == '\t' || *p == ';' || *p == '\n' || *p == '\r'))
      p++;
    if (p >= end)
      break;
    if ((size_t)(end - p) > plen && strncmp(p, prop_name, plen) == 0) {
      const char *after = p + plen;
      while (after < end && (*after == ' ' || *after == '\t'))
        after++;
      if (after < end && *after == ':') {
        after++;
        while (after < end && (*after == ' ' || *after == '\t'))
          after++;
        const char *val_start = after;
        while (after < end && *after != ';')
          after++;
        const char *val_end = after;
        while (val_end > val_start &&
               (*(val_end - 1) == ' ' || *(val_end - 1) == '\t'))
          val_end--;
        *val_len = (size_t)(val_end - val_start);
        return val_start;
      }
    }
    while (p < end && *p != ';')
      p++;
    if (p < end)
      p++;
  }
  return NULL;
}

static bool css_val_contains(const char *val, size_t val_len,
                             const char *needle) {
  size_t nlen = strlen(needle);
  if (nlen > val_len)
    return false;
  for (size_t i = 0; i <= val_len - nlen; i++) {
    bool match = true;
    for (size_t j = 0; j < nlen; j++) {
      if (tolower((unsigned char)val[i + j]) !=
          tolower((unsigned char)needle[j])) {
        match = false;
        break;
      }
    }
    if (match)
      return true;
  }
  return false;
}

static css_styles_t parse_css_style(const char *style_value, size_t style_len) {
  css_styles_t result = {false, false, false, false};
  if (!style_value || style_len == 0)
    return result;

  size_t vlen;
  const char *val;

  val = find_css_value(style_value, style_len, "font-weight", &vlen);
  if (val) {
    if (css_val_contains(val, vlen, "bold") ||
        css_val_contains(val, vlen, "bolder")) {
      result.bold = true;
    } else {
      int num = atoi(val);
      if (num >= 700)
        result.bold = true;
    }
  }

  val = find_css_value(style_value, style_len, "font-style", &vlen);
  if (val) {
    if (css_val_contains(val, vlen, "italic") ||
        css_val_contains(val, vlen, "oblique"))
      result.italic = true;
  }

  {
    const char *search_start = style_value;
    size_t search_remaining = style_len;
    while (search_remaining > 0) {
      val = find_css_value(search_start, search_remaining,
                           "text-decoration-line", &vlen);
      if (!val)
        val = find_css_value(search_start, search_remaining, "text-decoration",
                             &vlen);
      if (!val)
        break;
      if (css_val_contains(val, vlen, "underline"))
        result.underline = true;
      if (css_val_contains(val, vlen, "line-through"))
        result.strikethrough = true;
      size_t consumed = (size_t)(val + vlen - search_start);
      if (consumed >= search_remaining)
        break;
      search_start = val + vlen;
      search_remaining = style_len - (size_t)(search_start - style_value);
    }
  }

  return result;
}

static css_styles_t extra_styles(css_styles_t s, const char *tag) {
  if (strcmp(tag, "b") == 0)
    s.bold = false;
  if (strcmp(tag, "i") == 0)
    s.italic = false;
  if (strcmp(tag, "u") == 0)
    s.underline = false;
  if (strcmp(tag, "s") == 0)
    s.strikethrough = false;
  return s;
}

static void emit_styles_open(buffer_t *out, css_styles_t s) {
  if (s.bold)
    buffer_append_str(out, "<b>");
  if (s.italic)
    buffer_append_str(out, "<i>");
  if (s.underline)
    buffer_append_str(out, "<u>");
  if (s.strikethrough)
    buffer_append_str(out, "<s>");
}

static void emit_styles_close(buffer_t *out, css_styles_t s) {
  if (s.strikethrough)
    buffer_append_str(out, "</s>");
  if (s.underline)
    buffer_append_str(out, "</u>");
  if (s.italic)
    buffer_append_str(out, "</i>");
  if (s.bold)
    buffer_append_str(out, "</b>");
}

/* ------------------------------------------------------------------ */
/*  Attribute emission helpers                                         */
/* ------------------------------------------------------------------ */

static const char *get_attr(GumboElement *el, const char *name) {
  GumboAttribute *attr = gumbo_get_attribute(&el->attributes, name);
  if (attr)
    return attr->value;
  return NULL;
}

static void emit_one_attr(buffer_t *out, GumboElement *el,
                          const char *attr_name) {
  const char *val = get_attr(el, attr_name);
  if (val && val[0]) {
    buffer_append_str(out, " ");
    buffer_append_str(out, attr_name);
    buffer_append_str(out, "=\"");
    buffer_append_str(out, val);
    buffer_append_str(out, "\"");
  }
}

static void emit_attributes(GumboElement *el, const char *tag_name,
                            buffer_t *out) {
  if (strcmp(tag_name, "a") == 0) {
    emit_one_attr(out, el, "href");
  } else if (strcmp(tag_name, "img") == 0) {
    emit_one_attr(out, el, "src");
    emit_one_attr(out, el, "alt");
    emit_one_attr(out, el, "width");
    emit_one_attr(out, el, "height");
  } else if (strcmp(tag_name, "ul") == 0) {
    const char *val = get_attr(el, "data-type");
    if (val && strcmp(val, "checkbox") == 0)
      buffer_append_str(out, " data-type=\"checkbox\"");
  } else if (strcmp(tag_name, "li") == 0) {
    if (gumbo_get_attribute(&el->attributes, "checked") != NULL)
      buffer_append_str(out, " checked");
  } else if (strcmp(tag_name, "mention") == 0) {
    emit_one_attr(out, el, "id");
    emit_one_attr(out, el, "text");
    emit_one_attr(out, el, "indicator");
  }
}

/* ------------------------------------------------------------------ */
/*  Google Docs specific handling                                       */
/* ------------------------------------------------------------------ */

static bool is_google_docs_wrapper(GumboElement *el, const char *tag_name) {
  if (strcmp(tag_name, "b") != 0)
    return false;
  const char *id_val = get_attr(el, "id");
  if (!id_val)
    return false;
  size_t id_len = strlen(id_val);
  return (id_len > 20 && strncmp(id_val, "docs-internal-guid-", 19) == 0);
}

/* ------------------------------------------------------------------ */
/*  Recursive DOM tree walker                                          */
/* ------------------------------------------------------------------ */

static void walk_node(GumboNode *node, buffer_t *out);

/* ------------------------------------------------------------------ */
/*  Blockquote content flattening                                      */
/* ------------------------------------------------------------------ */

static void flatten_bq_node(GumboNode *node, buffer_t *ib, buffer_t *out);

static void flush_inline_p(buffer_t *ib, buffer_t *out) {
  if (ib->len > 0) {
    buffer_append_str(out, "<p>");
    buffer_append(out, ib->data, ib->len);
    buffer_append_str(out, "</p>");
    buffer_clear(ib);
  }
}

static void flatten_bq_children(GumboNode *node, buffer_t *ib, buffer_t *out) {
  if (!is_element(node))
    return;
  GumboVector *children = &node->v.element.children;
  for (unsigned int i = 0; i < children->length; i++) {
    flatten_bq_node(children->data[i], ib, out);
  }
}

static void flatten_bq_node(GumboNode *node, buffer_t *ib, buffer_t *out) {
  if (!node)
    return;
  if (is_text(node)) {
    walk_node(node, ib);
    return;
  }
  if (!is_element(node)) {
    return;
  }
  if (is_br_node(node)) {
    flush_inline_p(ib, out);
    return;
  }
  if (is_block_producing(node) || is_blockquote_node(node)) {
    flush_inline_p(ib, out);
    flatten_bq_children(node, ib, out);
    flush_inline_p(ib, out);
    return;
  }
  walk_node(node, ib);
}

/* ------------------------------------------------------------------ */
/*  List item content flattening                                       */
/* ------------------------------------------------------------------ */

typedef struct {
  GumboElement *el;
  css_styles_t styles;
  GumboNode **nested_lists;
  int *nested_count;
  int max_nested;
} li_ctx_t;

static void flatten_li_node(GumboNode *node, buffer_t *ib, buffer_t *out,
                            li_ctx_t *ctx);

static void flush_li_buffer(buffer_t *ib, buffer_t *out, li_ctx_t *ctx) {
  if (ib->len == 0)
    return;
  buffer_append_str(out, "<li");
  emit_attributes(ctx->el, "li", out);
  buffer_append_str(out, ">");
  emit_styles_open(out, ctx->styles);
  buffer_append(out, ib->data, ib->len);
  emit_styles_close(out, ctx->styles);
  buffer_append_str(out, "</li>");
  buffer_clear(ib);
}

static void flatten_li_children(GumboNode *node, buffer_t *ib, buffer_t *out,
                                li_ctx_t *ctx) {
  if (!is_element(node))
    return;
  GumboVector *children = &node->v.element.children;
  for (unsigned int i = 0; i < children->length; i++) {
    flatten_li_node(children->data[i], ib, out, ctx);
  }
}

static void flatten_li_node(GumboNode *node, buffer_t *ib, buffer_t *out,
                            li_ctx_t *ctx) {
  if (!node)
    return;
  if (is_text(node)) {
    walk_node(node, ib);
    return;
  }
  if (!is_element(node)) {
    flatten_li_children(node, ib, out, ctx);
    return;
  }
  if (is_list_node(node)) {
    if (*ctx->nested_count < ctx->max_nested) {
      ctx->nested_lists[*ctx->nested_count] = node;
      (*ctx->nested_count)++;
    }
    return;
  }
  if (is_br_node(node)) {
    flush_li_buffer(ib, out, ctx);
    return;
  }
  if (is_block_producing(node) || is_blockquote_node(node)) {
    flush_li_buffer(ib, out, ctx);
    flatten_li_children(node, ib, out, ctx);
    flush_li_buffer(ib, out, ctx);
    return;
  }
  walk_node(node, ib);
}

/* ------------------------------------------------------------------ */
/*  walk_children — the main child-iteration driver                    */
/* ------------------------------------------------------------------ */

static void walk_children(GumboNode *node, buffer_t *out) {
  if (!is_element(node))
    return;

  GumboVector *children = &node->v.element.children;
  bool parent_is_list = is_list_node(node);

  /* Detect mixed content: does the parent have any block-producing child? */
  bool has_block = false;
  for (unsigned int j = 0; j < children->length; j++) {
    if (is_block_producing(children->data[j])) {
      has_block = true;
      break;
    }
  }

  unsigned int i = 0;
  while (i < children->length) {
    GumboNode *child = children->data[i];

    /* Flatten list-inside-list */
    if (parent_is_list && is_list_node(child)) {
      walk_children(child, out);
      i++;
      continue;
    }

    /* Merge consecutive blockquotes, flattening content into <p>s */
    if (is_blockquote_node(child)) {
      buffer_append_str(out, "<blockquote>");
      buffer_t bq_ib = buffer_create(64);
      while (i < children->length && is_blockquote_node(children->data[i])) {
        flatten_bq_children(children->data[i], &bq_ib, out);
        i++;
      }
      flush_inline_p(&bq_ib, out);
      free(bq_ib.data);
      buffer_append_str(out, "</blockquote>");
      continue;
    }

    /* Auto-paragraph: group inline runs into <p> when mixed with blocks */
    if (has_block && !parent_is_list && !is_block_producing(child) &&
        !is_blockquote_node(child)) {
      buffer_t ib = buffer_create(64);
      while (i < children->length && !is_block_producing(children->data[i]) &&
             !is_blockquote_node(children->data[i])) {
        child = children->data[i];
        if (is_br_node(child)) {
          if (ib.len > 0)
            flush_inline_p(&ib, out);
          else
            buffer_append_str(out, "<br>");
          i++;
          continue;
        }
        /* Transparent inline wrapper for block/bq children */
        if (is_element(child) && has_block_or_bq_child(child)) {
          flush_inline_p(&ib, out);
          walk_children(child, out);
          i++;
          continue;
        }
        walk_node(child, &ib);
        i++;
      }
      flush_inline_p(&ib, out);
      free(ib.data);
      continue;
    }

    walk_node(child, out);
    i++;
  }
}

/* ------------------------------------------------------------------ */
/*  walk_node — process a single DOM node                              */
/* ------------------------------------------------------------------ */

static void walk_node(GumboNode *node, buffer_t *out) {
  if (!node)
    return;

  /* Text node */
  if (is_text(node)) {
    const char *text_raw = node->v.text.text;
    if (text_raw) {
      size_t text_len = strlen(text_raw);
      for (size_t i = 0; i < text_len; i++) {
        char c = text_raw[i];
        switch (c) {
        case '<':
          buffer_append_str(out, "&lt;");
          break;
        case '>':
          buffer_append_str(out, "&gt;");
          break;
        case '&':
          buffer_append_str(out, "&amp;");
          break;
        default:
          buffer_append(out, &c, 1);
          break;
        }
      }
    }
    return;
  }

  if (!is_element(node)) {
    walk_children(node, out);
    return;
  }

  GumboElement *el = &node->v.element;
  char name_buf[64];
  if (!get_tag_name(node, name_buf, sizeof(name_buf))) {
    walk_children(node, out);
    return;
  }

  /* Strip <meta>, <style>, <script>, <title>, <link> */
  if (strcmp(name_buf, "meta") == 0 || strcmp(name_buf, "style") == 0 ||
      strcmp(name_buf, "script") == 0 || strcmp(name_buf, "title") == 0 ||
      strcmp(name_buf, "link") == 0)
    return;

  /* Google Docs wrapper */
  if (is_google_docs_wrapper(el, name_buf)) {
    walk_children(node, out);
    return;
  }

  const char *out_name = canonical_name(name_buf);
  if (!out_name)
    out_name = name_buf;

  tag_class_t cls = classify_tag(name_buf);

  /* --- <span>: CSS style → inline tags --- */
  if (strcmp(name_buf, "span") == 0) {
    const char *sval = get_attr(el, "style");
    size_t slen = sval ? strlen(sval) : 0;
    css_styles_t s = parse_css_style(sval, slen);
    emit_styles_open(out, s);
    walk_children(node, out);
    emit_styles_close(out, s);
    return;
  }

  /* --- <div>: becomes <p> or passes through --- */
  if (strcmp(name_buf, "div") == 0) {
    const char *sval = get_attr(el, "style");
    size_t slen = sval ? strlen(sval) : 0;
    css_styles_t s = parse_css_style(sval, slen);

    if (is_purely_inline(node)) {
      /* Split on <br> into separate <p>s */
      buffer_t pb = buffer_create(64);
      GumboVector *div_children = &el->children;
      for (unsigned int di = 0; di < div_children->length; di++) {
        GumboNode *dc = div_children->data[di];
        if (is_br_node(dc)) {
          if (pb.len > 0) {
            buffer_append_str(out, "<p>");
            emit_styles_open(out, s);
            buffer_append(out, pb.data, pb.len);
            emit_styles_close(out, s);
            buffer_append_str(out, "</p>");
          } else {
            buffer_append_str(out, "<br>");
          }
          buffer_clear(&pb);
          continue;
        }
        walk_node(dc, &pb);
      }
      if (pb.len > 0) {
        buffer_append_str(out, "<p>");
        emit_styles_open(out, s);
        buffer_append(out, pb.data, pb.len);
        emit_styles_close(out, s);
        buffer_append_str(out, "</p>");
      }
      free(pb.data);
    } else {
      emit_styles_open(out, s);
      walk_children(node, out);
      emit_styles_close(out, s);
    }
    return;
  }

  /* --- Table elements --- */
  if (strcmp(name_buf, "table") == 0 || strcmp(name_buf, "thead") == 0 ||
      strcmp(name_buf, "tbody") == 0 || strcmp(name_buf, "tfoot") == 0 ||
      strcmp(name_buf, "tr") == 0 || strcmp(name_buf, "td") == 0 ||
      strcmp(name_buf, "th") == 0 || strcmp(name_buf, "caption") == 0 ||
      strcmp(name_buf, "colgroup") == 0 || strcmp(name_buf, "col") == 0) {
    if (strcmp(name_buf, "td") == 0 || strcmp(name_buf, "th") == 0) {
      walk_children(node, out);
      /* Check if there's a next sibling element */
      GumboNode *parent = node->parent;
      if (parent && is_element(parent)) {
        GumboVector *siblings = &parent->v.element.children;
        unsigned int my_idx = node->index_within_parent;
        /* Find next element sibling */
        bool has_next_el = false;
        for (unsigned int si = my_idx + 1; si < siblings->length; si++) {
          GumboNode *sib = siblings->data[si];
          if (is_element(sib)) {
            has_next_el = true;
            break;
          }
        }
        if (has_next_el)
          buffer_append_str(out, " ");
      }
    } else if (strcmp(name_buf, "tr") == 0) {
      buffer_t row = buffer_create(64);
      walk_children(node, &row);
      if (row.len > 0) {
        buffer_append_str(out, "<p>");
        buffer_append(out, row.data, row.len);
        buffer_append_str(out, "</p>");
      }
      free(row.data);
    } else {
      walk_children(node, out);
    }
    return;
  }

  /* --- Remaining tags handled by class --- */
  switch (cls) {
  case TAG_CLASS_PASS:
  case TAG_CLASS_SKIP:
    walk_children(node, out);
    break;

  case TAG_CLASS_SELF_CLOSING:
    buffer_append_str(out, "<");
    buffer_append_str(out, out_name);
    emit_attributes(el, out_name, out);
    buffer_append_str(out, strcmp(out_name, "img") == 0 ? " />" : ">");
    break;

  case TAG_CLASS_INLINE:
  case TAG_CLASS_BLOCK: {
    const char *sval = get_attr(el, "style");
    size_t slen = sval ? strlen(sval) : 0;
    css_styles_t es = extra_styles(parse_css_style(sval, slen), out_name);

    /* <li>: always flatten */
    if (strcmp(out_name, "li") == 0) {
      GumboNode *nested_lists[16];
      int nested_count = 0;
      buffer_t li_ib = buffer_create(64);
      li_ctx_t ctx = {el, es, nested_lists, &nested_count, 16};
      flatten_li_children(node, &li_ib, out, &ctx);
      flush_li_buffer(&li_ib, out, &ctx);
      free(li_ib.data);
      for (int k = 0; k < nested_count; k++)
        walk_children(nested_lists[k], out);
      break;
    }

    /* <codeblock>: wrap inline content in <p> */
    if (strcmp(out_name, "codeblock") == 0) {
      bool wrap = is_purely_inline(node);
      buffer_append_str(out, "<codeblock>");
      if (wrap)
        buffer_append_str(out, "<p>");
      walk_children(node, out);
      if (wrap)
        buffer_append_str(out, "</p>");
      buffer_append_str(out, "</codeblock>");
      break;
    }

    /* Generic block/inline tag */
    buffer_append_str(out, "<");
    buffer_append_str(out, out_name);
    emit_attributes(el, out_name, out);
    buffer_append_str(out, ">");
    emit_styles_open(out, es);
    walk_children(node, out);
    emit_styles_close(out, es);
    buffer_append_str(out, "</");
    buffer_append_str(out, out_name);
    buffer_append_str(out, ">");
    break;
  }
  }
}

/* ------------------------------------------------------------------ */
/*  Find <body> element from parse output                              */
/* ------------------------------------------------------------------ */

static GumboNode *find_body(GumboNode *root) {
  if (!root || !is_element(root))
    return root;
  GumboVector *children = &root->v.element.children;
  for (unsigned int i = 0; i < children->length; i++) {
    GumboNode *child = children->data[i];
    if (is_element(child) && child->v.element.tag == GUMBO_TAG_BODY)
      return child;
  }
  return root;
}

/* ------------------------------------------------------------------ */
/*  Public API                                                         */
/* ------------------------------------------------------------------ */

char *normalize_html(const char *html, size_t len) {
  if (!html || len == 0)
    return NULL;

  GumboOutput *output =
      gumbo_parse_with_options(&kGumboDefaultOptions, html, len);
  if (!output)
    return NULL;

  GumboNode *body = find_body(output->root);
  if (!body)
    body = output->root;

  buffer_t buf = buffer_create(len * 2);
  walk_children(body, &buf);

  gumbo_destroy_output(&kGumboDefaultOptions, output);
  return buffer_finish(&buf);
}

void free_normalized_html(char *result) { free(result); }
