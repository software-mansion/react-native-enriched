/**
 * lexbor_normalizer.c
 *
 * Lexbor-based HTML normalizer (C implementation).
 * This file MUST be compiled as C (not C++) because Lexbor uses C99 features
 * (compound literals, etc.) that are not valid in C++.
 *
 * Converts arbitrary external HTML into the canonical subset that our enriched
 * parser understands.
 */

#ifndef LEXBOR_STATIC
#define LEXBOR_STATIC
#endif

#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
#elif defined(__GNUC__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wall"
#pragma GCC diagnostic ignored "-Wextra"
#endif

#include "lexbor.h"

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

/** Get the lowercased tag name of an element node into buf. Returns
 *  buf on success, NULL if node is not an element or has no name. */
static const char *get_tag_name(lxb_dom_node_t *node, char *buf,
                                size_t buf_sz) {
  if (!node || node->type != LXB_DOM_NODE_TYPE_ELEMENT)
    return NULL;
  lxb_dom_element_t *el = lxb_dom_interface_element(node);
  size_t nlen;
  const lxb_char_t *nraw = lxb_dom_element_local_name(el, &nlen);
  if (!nraw || nlen == 0)
    return NULL;
  size_t n = nlen < buf_sz - 1 ? nlen : buf_sz - 1;
  for (size_t i = 0; i < n; i++)
    buf[i] = (char)tolower((unsigned char)nraw[i]);
  buf[n] = '\0';
  return buf;
}

static bool is_list_node(lxb_dom_node_t *node) {
  char buf[64];
  const char *n = get_tag_name(node, buf, sizeof(buf));
  return n && (strcmp(n, "ul") == 0 || strcmp(n, "ol") == 0);
}

static bool is_blockquote_node(lxb_dom_node_t *node) {
  char buf[64];
  const char *n = get_tag_name(node, buf, sizeof(buf));
  return n && strcmp(n, "blockquote") == 0;
}

static bool is_br_node(lxb_dom_node_t *node) {
  char buf[64];
  const char *n = get_tag_name(node, buf, sizeof(buf));
  return n && strcmp(n, "br") == 0;
}

static bool is_block_producing(lxb_dom_node_t *node) {
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
static bool is_purely_inline(lxb_dom_node_t *node) {
  lxb_dom_node_t *c = lxb_dom_node_first_child(node);
  while (c) {
    if (is_block_producing(c))
      return false;
    c = lxb_dom_node_next(c);
  }
  return true;
}

/** True if any direct child is block-producing or a blockquote. */
static bool has_block_or_bq_child(lxb_dom_node_t *node) {
  lxb_dom_node_t *c = lxb_dom_node_first_child(node);
  while (c) {
    if (is_block_producing(c) || is_blockquote_node(c))
      return true;
    c = lxb_dom_node_next(c);
  }
  return false;
}

/* ------------------------------------------------------------------ */
/*  CSS style → canonical tag mapping  (uses Lexbor CSS parser)        */
/* ------------------------------------------------------------------ */

typedef struct {
  bool bold;
  bool italic;
  bool underline;
  bool strikethrough;
} css_styles_t;

static css_styles_t parse_css_style(const char *style_value, size_t style_len) {
  css_styles_t result = {false, false, false, false};
  if (!style_value || style_len == 0)
    return result;

  lxb_css_parser_t *parser = lxb_css_parser_create();
  lxb_status_t status = lxb_css_parser_init(parser, NULL);
  if (status != LXB_STATUS_OK) {
    lxb_css_parser_destroy(parser, true);
    return result;
  }

  lxb_css_memory_t *memory = lxb_css_memory_create();
  status = lxb_css_memory_init(memory, 128);
  if (status != LXB_STATUS_OK) {
    lxb_css_memory_destroy(memory, true);
    lxb_css_parser_destroy(parser, true);
    return result;
  }
  lxb_css_parser_memory_set(parser, memory);

  lxb_css_rule_declaration_list_t *list = lxb_css_declaration_list_parse(
      parser, (const lxb_char_t *)style_value, style_len);
  if (!list) {
    lxb_css_memory_destroy(memory, true);
    lxb_css_parser_destroy(parser, true);
    return result;
  }

  lxb_css_rule_t *rule = list->first;
  while (rule) {
    if (rule->type == LXB_CSS_RULE_DECLARATION) {
      lxb_css_rule_declaration_t *decl = (lxb_css_rule_declaration_t *)rule;
      switch ((unsigned)decl->type) {
      case LXB_CSS_PROPERTY_FONT_WEIGHT: {
        lxb_css_property_font_weight_t *fw = decl->u.font_weight;
        if (fw) {
          if (fw->type == LXB_CSS_FONT_WEIGHT_BOLD ||
              fw->type == LXB_CSS_FONT_WEIGHT_BOLDER)
            result.bold = true;
          else if (fw->type == LXB_CSS_FONT_WEIGHT__NUMBER &&
                   fw->number.num >= 700.0)
            result.bold = true;
        }
        break;
      }
      case LXB_CSS_PROPERTY_FONT_STYLE: {
        lxb_css_property_font_style_t *fs = decl->u.font_style;
        if (fs && (fs->type == LXB_CSS_FONT_STYLE_ITALIC ||
                   fs->type == LXB_CSS_FONT_STYLE_OBLIQUE))
          result.italic = true;
        break;
      }
      case LXB_CSS_PROPERTY_TEXT_DECORATION:
      case LXB_CSS_PROPERTY_TEXT_DECORATION_LINE: {
        lxb_css_property_text_decoration_line_t *tdl = NULL;
        if ((unsigned)decl->type == LXB_CSS_PROPERTY_TEXT_DECORATION) {
          lxb_css_property_text_decoration_t *td = decl->u.text_decoration;
          if (td)
            tdl = &td->line;
        } else {
          tdl = decl->u.text_decoration_line;
        }
        if (tdl) {
          if (tdl->underline == LXB_CSS_TEXT_DECORATION_LINE_UNDERLINE)
            result.underline = true;
          if (tdl->line_through == LXB_CSS_TEXT_DECORATION_LINE_LINE_THROUGH)
            result.strikethrough = true;
        }
        break;
      }
      default:
        break;
      }
    }
    rule = rule->next;
  }

  lxb_css_rule_declaration_list_destroy(list, true);
  lxb_css_memory_destroy(memory, true);
  lxb_css_parser_destroy(parser, true);
  return result;
}

/** Compute extra styles that the tag doesn't already convey. */
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

/* Emit opening / closing style wrapper tags. */
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

static const char *get_attr(lxb_dom_element_t *el, const char *name,
                            size_t *out_len) {
  const lxb_char_t *val = lxb_dom_element_get_attribute(
      el, (const lxb_char_t *)name, strlen(name), out_len);
  return (const char *)val;
}

static void emit_one_attr(buffer_t *out, lxb_dom_element_t *el,
                          const char *attr_name) {
  size_t len;
  const char *val = get_attr(el, attr_name, &len);
  if (val && len > 0) {
    buffer_append_str(out, " ");
    buffer_append_str(out, attr_name);
    buffer_append_str(out, "=\"");
    buffer_append(out, val, len);
    buffer_append_str(out, "\"");
  }
}

static void emit_attributes(lxb_dom_element_t *el, const char *tag_name,
                            buffer_t *out) {
  if (strcmp(tag_name, "a") == 0) {
    emit_one_attr(out, el, "href");
  } else if (strcmp(tag_name, "img") == 0) {
    emit_one_attr(out, el, "src");
    emit_one_attr(out, el, "alt");
    emit_one_attr(out, el, "width");
    emit_one_attr(out, el, "height");
  } else if (strcmp(tag_name, "ul") == 0) {
    size_t len;
    const char *val = get_attr(el, "data-type", &len);
    if (val && len > 0 && strncmp(val, "checkbox", len) == 0)
      buffer_append_str(out, " data-type=\"checkbox\"");
  } else if (strcmp(tag_name, "li") == 0) {
    if (lxb_dom_element_has_attribute(el, (const lxb_char_t *)"checked", 7))
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

static bool is_google_docs_wrapper(lxb_dom_element_t *el,
                                   const char *tag_name) {
  if (strcmp(tag_name, "b") != 0)
    return false;
  size_t id_len;
  const char *id_val = get_attr(el, "id", &id_len);
  if (!id_val)
    return false;
  return (id_len > 20 && strncmp(id_val, "docs-internal-guid-", 19) == 0);
}

/* ------------------------------------------------------------------ */
/*  Recursive DOM tree walker                                          */
/* ------------------------------------------------------------------ */

static void walk_node(lxb_dom_node_t *node, buffer_t *out);

/* ------------------------------------------------------------------ */
/*  Blockquote content flattening                                      */
/* ------------------------------------------------------------------ */

static void flatten_bq_node(lxb_dom_node_t *node, buffer_t *ib, buffer_t *out);

/** Flush the inline buffer into a <p> element (if non-empty). */
static void flush_inline_p(buffer_t *ib, buffer_t *out) {
  if (ib->len > 0) {
    buffer_append_str(out, "<p>");
    buffer_append(out, ib->data, ib->len);
    buffer_append_str(out, "</p>");
    buffer_clear(ib);
  }
}

static void flatten_bq_children(lxb_dom_node_t *node, buffer_t *ib,
                                buffer_t *out) {
  lxb_dom_node_t *child = lxb_dom_node_first_child(node);
  while (child) {
    flatten_bq_node(child, ib, out);
    child = lxb_dom_node_next(child);
  }
}

static void flatten_bq_node(lxb_dom_node_t *node, buffer_t *ib, buffer_t *out) {
  if (!node)
    return;
  if (node->type == LXB_DOM_NODE_TYPE_TEXT) {
    walk_node(node, ib);
    return;
  }
  if (node->type != LXB_DOM_NODE_TYPE_ELEMENT) {
    flatten_bq_children(node, ib, out);
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
  lxb_dom_element_t *el;
  css_styles_t styles;
  lxb_dom_node_t **nested_lists;
  int *nested_count;
  int max_nested;
} li_ctx_t;

static void flatten_li_node(lxb_dom_node_t *node, buffer_t *ib, buffer_t *out,
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

static void flatten_li_children(lxb_dom_node_t *node, buffer_t *ib,
                                buffer_t *out, li_ctx_t *ctx) {
  lxb_dom_node_t *child = lxb_dom_node_first_child(node);
  while (child) {
    flatten_li_node(child, ib, out, ctx);
    child = lxb_dom_node_next(child);
  }
}

static void flatten_li_node(lxb_dom_node_t *node, buffer_t *ib, buffer_t *out,
                            li_ctx_t *ctx) {
  if (!node)
    return;
  if (node->type == LXB_DOM_NODE_TYPE_TEXT) {
    walk_node(node, ib);
    return;
  }
  if (node->type != LXB_DOM_NODE_TYPE_ELEMENT) {
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

static void walk_children(lxb_dom_node_t *node, buffer_t *out) {
  bool parent_is_list = is_list_node(node);

  /* Detect mixed content: does the parent have any block-producing child? */
  bool has_block = false;
  {
    lxb_dom_node_t *c = lxb_dom_node_first_child(node);
    while (c) {
      if (is_block_producing(c)) {
        has_block = true;
        break;
      }
      c = lxb_dom_node_next(c);
    }
  }

  lxb_dom_node_t *child = lxb_dom_node_first_child(node);
  while (child) {
    /* Flatten list-inside-list */
    if (parent_is_list && is_list_node(child)) {
      walk_children(child, out);
      child = lxb_dom_node_next(child);
      continue;
    }

    /* Merge consecutive blockquotes, flattening content into <p>s */
    if (is_blockquote_node(child)) {
      buffer_append_str(out, "<blockquote>");
      buffer_t bq_ib = buffer_create(64);
      while (child && is_blockquote_node(child)) {
        flatten_bq_children(child, &bq_ib, out);
        child = lxb_dom_node_next(child);
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
      while (child && !is_block_producing(child) &&
             !is_blockquote_node(child)) {
        if (is_br_node(child)) {
          if (ib.len > 0)
            flush_inline_p(&ib, out);
          else
            buffer_append_str(out, "<br>");
          child = lxb_dom_node_next(child);
          continue;
        }
        /* Transparent inline wrapper for block/bq children
         * (e.g. <span><blockquote>…</blockquote></span>) */
        if (child->type == LXB_DOM_NODE_TYPE_ELEMENT &&
            has_block_or_bq_child(child)) {
          flush_inline_p(&ib, out);
          walk_children(child, out);
          child = lxb_dom_node_next(child);
          continue;
        }
        walk_node(child, &ib);
        child = lxb_dom_node_next(child);
      }
      flush_inline_p(&ib, out);
      free(ib.data);
      continue;
    }

    walk_node(child, out);
    child = lxb_dom_node_next(child);
  }
}

/* ------------------------------------------------------------------ */
/*  walk_node — process a single DOM node                              */
/* ------------------------------------------------------------------ */

static void walk_node(lxb_dom_node_t *node, buffer_t *out) {
  if (!node)
    return;

  /* Text node */
  if (node->type == LXB_DOM_NODE_TYPE_TEXT) {
    size_t text_len;
    const lxb_char_t *text_raw = lxb_dom_node_text_content(node, &text_len);
    if (text_raw && text_len > 0) {
      for (size_t i = 0; i < text_len; i++) {
        char c = (char)text_raw[i];
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

  if (node->type != LXB_DOM_NODE_TYPE_ELEMENT) {
    walk_children(node, out);
    return;
  }

  lxb_dom_element_t *el = lxb_dom_interface_element(node);
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
    size_t slen;
    const char *sval = get_attr(el, "style", &slen);
    css_styles_t s = parse_css_style(sval, slen);
    emit_styles_open(out, s);
    walk_children(node, out);
    emit_styles_close(out, s);
    return;
  }

  /* --- <div>: becomes <p> or passes through --- */
  if (strcmp(name_buf, "div") == 0) {
    size_t slen;
    const char *sval = get_attr(el, "style", &slen);
    css_styles_t s = parse_css_style(sval, slen);

    if (is_purely_inline(node)) {
      /* Split on <br> into separate <p>s */
      buffer_t pb = buffer_create(64);
      lxb_dom_node_t *dc = lxb_dom_node_first_child(node);
      while (dc) {
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
          dc = lxb_dom_node_next(dc);
          continue;
        }
        walk_node(dc, &pb);
        dc = lxb_dom_node_next(dc);
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
      lxb_dom_node_t *sib = lxb_dom_node_next(node);
      while (sib && sib->type != LXB_DOM_NODE_TYPE_ELEMENT)
        sib = lxb_dom_node_next(sib);
      if (sib)
        buffer_append_str(out, " ");
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
    size_t slen;
    const char *sval = get_attr(el, "style", &slen);
    css_styles_t es = extra_styles(parse_css_style(sval, slen), out_name);

    /* <li>: always flatten (handles block children + nested lists) */
    if (strcmp(out_name, "li") == 0) {
      lxb_dom_node_t *nested_lists[16];
      int nested_count = 0;
      buffer_t li_ib = buffer_create(64);
      li_ctx_t ctx = {el, es, nested_lists, &nested_count, 16};
      flatten_li_children(node, &li_ib, out, &ctx);
      flush_li_buffer(&li_ib, out, &ctx);
      free(li_ib.data);
      for (int i = 0; i < nested_count; i++)
        walk_children(nested_lists[i], out);
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
/*  Public API                                                         */
/* ------------------------------------------------------------------ */

char *normalize_html(const char *html, size_t len) {
  if (!html || len == 0)
    return NULL;

  lxb_html_document_t *doc = lxb_html_document_create();
  if (!doc)
    return NULL;

  lxb_status_t status =
      lxb_html_document_parse(doc, (const lxb_char_t *)html, len);
  if (status != LXB_STATUS_OK) {
    lxb_html_document_destroy(doc);
    return NULL;
  }

  lxb_html_body_element_t *body = lxb_html_document_body_element(doc);
  lxb_dom_node_t *root =
      body ? lxb_dom_interface_node(body)
           : lxb_dom_interface_node(lxb_dom_interface_node(doc));

  buffer_t output = buffer_create(len * 2);
  walk_children(root, &output);

  lxb_html_document_destroy(doc);
  return buffer_finish(&output);
}

void free_normalized_html(char *result) { free(result); }
