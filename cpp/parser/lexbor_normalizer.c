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

/* Returns the canonical tag name if we want to remap, or NULL to keep as-is. */
static const char *canonical_name(const char *name) {
  if (strcmp(name, "strong") == 0)
    return "b";
  if (strcmp(name, "em") == 0)
    return "i";
  if (strcmp(name, "del") == 0)
    return "s";
  if (strcmp(name, "strike") == 0)
    return "s";
  if (strcmp(name, "ins") == 0)
    return "u";
  if (strcmp(name, "pre") == 0)
    return "codeblock";
  return NULL;
}

static tag_class_t classify_tag(const char *name) {
  /* Inline canonical tags */
  if (strcmp(name, "b") == 0 || strcmp(name, "i") == 0 ||
      strcmp(name, "u") == 0 || strcmp(name, "s") == 0 ||
      strcmp(name, "code") == 0 || strcmp(name, "a") == 0 ||
      strcmp(name, "strong") == 0 || strcmp(name, "em") == 0 ||
      strcmp(name, "del") == 0 || strcmp(name, "strike") == 0 ||
      strcmp(name, "ins") == 0 || strcmp(name, "mention") == 0)
    return TAG_CLASS_INLINE;

  /* Block canonical tags */
  if (strcmp(name, "p") == 0 || strcmp(name, "h1") == 0 ||
      strcmp(name, "h2") == 0 || strcmp(name, "h3") == 0 ||
      strcmp(name, "h4") == 0 || strcmp(name, "h5") == 0 ||
      strcmp(name, "h6") == 0 || strcmp(name, "ul") == 0 ||
      strcmp(name, "ol") == 0 || strcmp(name, "li") == 0 ||
      strcmp(name, "blockquote") == 0 || strcmp(name, "codeblock") == 0 ||
      strcmp(name, "pre") == 0)
    return TAG_CLASS_BLOCK;

  /* Self-closing */
  if (strcmp(name, "br") == 0 || strcmp(name, "img") == 0)
    return TAG_CLASS_SELF_CLOSING;

  /* Pass-through (just emit children) */
  if (strcmp(name, "html") == 0 || strcmp(name, "head") == 0 ||
      strcmp(name, "body") == 0)
    return TAG_CLASS_PASS;

  /* Everything else: strip tag, keep children text */
  return TAG_CLASS_SKIP;
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

/**
 * Parse the value of a `style` attribute and extract relevant styles.
 * Uses Lexbor's CSS declaration list parser.
 */
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

  /* The CSS parser needs a memory object to allocate rule nodes. */
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

  /* Walk each declaration in the list */
  lxb_css_rule_t *rule = list->first;
  while (rule) {
    if (rule->type == LXB_CSS_RULE_DECLARATION) {
      lxb_css_rule_declaration_t *decl = (lxb_css_rule_declaration_t *)rule;

      switch ((unsigned)decl->type) {
      case LXB_CSS_PROPERTY_FONT_WEIGHT: {
        lxb_css_property_font_weight_t *fw = decl->u.font_weight;
        if (fw) {
          if (fw->type == LXB_CSS_FONT_WEIGHT_BOLD ||
              fw->type == LXB_CSS_FONT_WEIGHT_BOLDER) {
            result.bold = true;
          } else if (fw->type == LXB_CSS_FONT_WEIGHT__NUMBER) {
            /* Numeric weight >= 700 is bold */
            if (fw->number.num >= 700.0) {
              result.bold = true;
            }
          }
        }
        break;
      }

      case LXB_CSS_PROPERTY_FONT_STYLE: {
        lxb_css_property_font_style_t *fs = decl->u.font_style;
        if (fs) {
          if (fs->type == LXB_CSS_FONT_STYLE_ITALIC ||
              fs->type == LXB_CSS_FONT_STYLE_OBLIQUE) {
            result.italic = true;
          }
        }
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

/* ------------------------------------------------------------------ */
/*  Attribute emission helpers                                         */
/* ------------------------------------------------------------------ */

/**
 * Get an attribute value from an element.
 * Returns NULL if the attribute doesn't exist.
 */
static const char *get_attr(lxb_dom_element_t *el, const char *name,
                            size_t *out_len) {
  const lxb_char_t *val = lxb_dom_element_get_attribute(
      el, (const lxb_char_t *)name, strlen(name), out_len);
  return (const char *)val;
}

/**
 * Emit whitelisted attributes for a given canonical tag into the buffer.
 * Only emits: href, src, width, height, data-type, data-id, data-label, checked
 */
static void emit_attributes(lxb_dom_element_t *el, const char *tag_name,
                            buffer_t *out) {
  size_t len;
  const char *val;

  /* <a href="…"> */
  if (strcmp(tag_name, "a") == 0) {
    val = get_attr(el, "href", &len);
    if (val && len > 0) {
      buffer_append_str(out, " href=\"");
      buffer_append(out, val, len);
      buffer_append_str(out, "\"");
    }
    return;
  }

  /* <img src="…" alt="…" width="…" height="…"> */
  if (strcmp(tag_name, "img") == 0) {
    val = get_attr(el, "src", &len);
    if (val && len > 0) {
      buffer_append_str(out, " src=\"");
      buffer_append(out, val, len);
      buffer_append_str(out, "\"");
    }
    val = get_attr(el, "alt", &len);
    if (val && len > 0) {
      buffer_append_str(out, " alt=\"");
      buffer_append(out, val, len);
      buffer_append_str(out, "\"");
    }
    val = get_attr(el, "width", &len);
    if (val && len > 0) {
      buffer_append_str(out, " width=\"");
      buffer_append(out, val, len);
      buffer_append_str(out, "\"");
    }
    val = get_attr(el, "height", &len);
    if (val && len > 0) {
      buffer_append_str(out, " height=\"");
      buffer_append(out, val, len);
      buffer_append_str(out, "\"");
    }
    return;
  }

  /* <ul data-type="checkbox"> */
  if (strcmp(tag_name, "ul") == 0) {
    val = get_attr(el, "data-type", &len);
    if (val && len > 0 && strncmp(val, "checkbox", len) == 0) {
      buffer_append_str(out, " data-type=\"checkbox\"");
    }
    return;
  }

  /* <li checked> (boolean attribute – value may be NULL) */
  if (strcmp(tag_name, "li") == 0) {
    if (lxb_dom_element_has_attribute(el, (const lxb_char_t *)"checked", 7)) {
      buffer_append_str(out, " checked");
    }
    return;
  }

  /* <mention id="…" text="…" indicator="…"> */
  if (strcmp(tag_name, "mention") == 0) {
    val = get_attr(el, "id", &len);
    if (val && len > 0) {
      buffer_append_str(out, " id=\"");
      buffer_append(out, val, len);
      buffer_append_str(out, "\"");
    }
    val = get_attr(el, "text", &len);
    if (val && len > 0) {
      buffer_append_str(out, " text=\"");
      buffer_append(out, val, len);
      buffer_append_str(out, "\"");
    }
    val = get_attr(el, "indicator", &len);
    if (val && len > 0) {
      buffer_append_str(out, " indicator=\"");
      buffer_append(out, val, len);
      buffer_append_str(out, "\"");
    }
    return;
  }
}

/* ------------------------------------------------------------------ */
/*  Google Docs specific handling                                       */
/* ------------------------------------------------------------------ */

/**
 * Detect and skip the Google Docs wrapper: <b id="docs-internal-guid-…">
 * Returns true if this element is a Google Docs wrapper that should be
 * treated as pass-through (skip the <b> tag itself, keep children).
 */
static bool is_google_docs_wrapper(lxb_dom_element_t *el,
                                   const char *tag_name) {
  if (strcmp(tag_name, "b") != 0)
    return false;
  size_t id_len;
  const char *id_val = get_attr(el, "id", &id_len);
  if (!id_val)
    return false;
  /* Google Docs uses: id="docs-internal-guid-…" */
  return (id_len > 20 && strncmp(id_val, "docs-internal-guid-", 19) == 0);
}

/* ------------------------------------------------------------------ */
/*  Recursive DOM tree walker                                          */
/* ------------------------------------------------------------------ */

static void walk_node(lxb_dom_node_t *node, buffer_t *out);

/**
 * Check if a DOM node is a <ul> or <ol> list element.
 */
static bool is_list_node(lxb_dom_node_t *node) {
  if (!node || node->type != LXB_DOM_NODE_TYPE_ELEMENT)
    return false;
  lxb_dom_element_t *el = lxb_dom_interface_element(node);
  size_t name_len;
  const lxb_char_t *name_raw = lxb_dom_element_local_name(el, &name_len);
  if (!name_raw || name_len != 2)
    return false;
  char a = (char)tolower((unsigned char)name_raw[0]);
  char b = (char)tolower((unsigned char)name_raw[1]);
  return (a == 'u' && b == 'l') || (a == 'o' && b == 'l');
}

/**
 * Check if a DOM node is a <blockquote> element.
 */
static bool is_blockquote_node(lxb_dom_node_t *node) {
  if (!node || node->type != LXB_DOM_NODE_TYPE_ELEMENT)
    return false;
  lxb_dom_element_t *el = lxb_dom_interface_element(node);
  size_t name_len;
  const lxb_char_t *name_raw = lxb_dom_element_local_name(el, &name_len);
  if (!name_raw || name_len != 10)
    return false;
  /* Case-insensitive compare against "blockquote" */
  const char *bq = "blockquote";
  for (size_t i = 0; i < 10; i++) {
    if (tolower((unsigned char)name_raw[i]) != bq[i])
      return false;
  }
  return true;
}

/**
 * Check if a DOM node produces block-level output.
 */
static bool is_block_producing_element(lxb_dom_node_t *node) {
  if (!node || node->type != LXB_DOM_NODE_TYPE_ELEMENT)
    return false;
  lxb_dom_element_t *el = lxb_dom_interface_element(node);
  size_t nlen;
  const lxb_char_t *nraw = lxb_dom_element_local_name(el, &nlen);
  if (!nraw || nlen == 0)
    return false;
  char buf[64];
  size_t n = nlen < 63 ? nlen : 63;
  for (size_t i = 0; i < n; i++)
    buf[i] = (char)tolower((unsigned char)nraw[i]);
  buf[n] = '\0';
  if (classify_tag(buf) == TAG_CLASS_BLOCK)
    return true;
  if (strcmp(buf, "div") == 0)
    return true;
  if (strcmp(buf, "table") == 0 || strcmp(buf, "tr") == 0)
    return true;
  return false;
}

/**
 * Check if a text node's parent has any block-level element children.
 */
static bool parent_has_block_children(lxb_dom_node_t *node) {
  lxb_dom_node_t *parent = node->parent;
  if (!parent)
    return false;
  lxb_dom_node_t *child = lxb_dom_node_first_child(parent);
  while (child) {
    if (is_block_producing_element(child))
      return true;
    child = lxb_dom_node_next(child);
  }
  return false;
}

/**
 * Check if a node's children are all inline/text (no block-level elements).
 * If so, the content should be wrapped in <p> when placed inside a blockquote.
 */
static bool needs_p_wrap(lxb_dom_node_t *node) {
  lxb_dom_node_t *child = lxb_dom_node_first_child(node);
  while (child) {
    if (child->type == LXB_DOM_NODE_TYPE_ELEMENT) {
      lxb_dom_element_t *el = lxb_dom_interface_element(child);
      size_t nlen;
      const lxb_char_t *nraw = lxb_dom_element_local_name(el, &nlen);
      if (nraw && nlen > 0) {
        char buf[64];
        size_t n = nlen < 63 ? nlen : 63;
        for (size_t i = 0; i < n; i++)
          buf[i] = (char)tolower((unsigned char)nraw[i]);
        buf[n] = '\0';
        if (classify_tag(buf) == TAG_CLASS_BLOCK)
          return false;
      }
    }
    child = lxb_dom_node_next(child);
  }
  return true;
}

/**
 * Check if a node has any <div> children.
 * Since <div> becomes <p> in the output, it counts as block-level content
 * even though classify_tag("div") returns TAG_CLASS_SKIP.
 */
static bool has_div_child(lxb_dom_node_t *node) {
  lxb_dom_node_t *child = lxb_dom_node_first_child(node);
  while (child) {
    if (child->type == LXB_DOM_NODE_TYPE_ELEMENT) {
      lxb_dom_element_t *el = lxb_dom_interface_element(child);
      size_t nlen;
      const lxb_char_t *nraw = lxb_dom_element_local_name(el, &nlen);
      if (nraw && nlen == 3) {
        if (tolower((unsigned char)nraw[0]) == 'd' &&
            tolower((unsigned char)nraw[1]) == 'i' &&
            tolower((unsigned char)nraw[2]) == 'v')
          return true;
      }
    }
    child = lxb_dom_node_next(child);
  }
  return false;
}

/**
 * Walk children of a <li> node, but skip nested <ul>/<ol> elements.
 * Nested lists are collected in the provided array for later flattening.
 * Returns the number of nested lists found.
 */
static int walk_li_children_collecting(lxb_dom_node_t *node, buffer_t *out,
                                       lxb_dom_node_t **nested, int max_n) {
  int count = 0;
  lxb_dom_node_t *child = lxb_dom_node_first_child(node);
  while (child) {
    if (is_list_node(child)) {
      if (count < max_n) {
        nested[count++] = child;
      }
    } else {
      walk_node(child, out);
    }
    child = lxb_dom_node_next(child);
  }
  return count;
}

/**
 * Walk all children of a node.
 * Merges consecutive <blockquote> siblings into a single <blockquote>,
 * wrapping each original blockquote's content in <p> tags.
 */
static void walk_children(lxb_dom_node_t *node, buffer_t *out) {
  bool parent_is_list = is_list_node(node);
  lxb_dom_node_t *child = lxb_dom_node_first_child(node);
  while (child) {
    /* Flatten list-inside-list: when a <ul>/<ol> is a direct child of
     * another <ul>/<ol>, strip the inner list container and emit its
     * children (the <li> items) directly as siblings in the parent list. */
    if (parent_is_list && is_list_node(child)) {
      walk_children(child, out);
      child = lxb_dom_node_next(child);
      continue;
    }
    if (is_blockquote_node(child)) {
      /* Merge consecutive <blockquote> siblings into one */
      buffer_append_str(out, "<blockquote>");
      while (child && is_blockquote_node(child)) {
        bool wrap = needs_p_wrap(child);
        if (wrap)
          buffer_append_str(out, "<p>");
        walk_children(child, out);
        if (wrap)
          buffer_append_str(out, "</p>");
        child = lxb_dom_node_next(child);
      }
      buffer_append_str(out, "</blockquote>");
      continue; /* child already advanced past the run */
    }
    walk_node(child, out);
    child = lxb_dom_node_next(child);
  }
}

/**
 * Process a single DOM node.
 */
static void walk_node(lxb_dom_node_t *node, buffer_t *out) {
  if (!node)
    return;

  /* --- Text node: emit verbatim (HTML-encoded by Lexbor) --- */
  if (node->type == LXB_DOM_NODE_TYPE_TEXT) {
    size_t text_len;
    const lxb_char_t *text_raw = lxb_dom_node_text_content(node, &text_len);
    if (text_raw && text_len > 0) {
      /* Skip whitespace-only text nodes between block elements */
      bool all_ws = true;
      for (size_t i = 0; i < text_len; i++) {
        if (!isspace((unsigned char)text_raw[i])) {
          all_ws = false;
          break;
        }
      }
      if (all_ws && parent_has_block_children(node))
        return;

      /* Emit text, escaping < > & for safety */
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

  /* --- Only process element nodes --- */
  if (node->type != LXB_DOM_NODE_TYPE_ELEMENT) {
    walk_children(node, out);
    return;
  }

  lxb_dom_element_t *el = lxb_dom_interface_element(node);
  size_t name_len;
  const lxb_char_t *name_raw = lxb_dom_element_local_name(el, &name_len);
  if (!name_raw || name_len == 0) {
    walk_children(node, out);
    return;
  }

  /* Convert tag name to lowercase C string */
  char name_buf[64];
  size_t copy_len = name_len < 63 ? name_len : 63;
  for (size_t i = 0; i < copy_len; i++)
    name_buf[i] = (char)tolower((unsigned char)name_raw[i]);
  name_buf[copy_len] = '\0';

  /* --- Strip <meta>, <style>, <script>, <title>, <link> --- */
  if (strcmp(name_buf, "meta") == 0 || strcmp(name_buf, "style") == 0 ||
      strcmp(name_buf, "script") == 0 || strcmp(name_buf, "title") == 0 ||
      strcmp(name_buf, "link") == 0) {
    return; /* skip entirely including children */
  }

  /* --- Google Docs wrapper detection --- */
  if (is_google_docs_wrapper(el, name_buf)) {
    walk_children(node, out);
    return;
  }

  /* Determine canonical output name */
  const char *out_name = canonical_name(name_buf);
  if (!out_name)
    out_name = name_buf; /* keep original */

  tag_class_t cls = classify_tag(name_buf);

  /* --- Handle <span> with style-based inline formatting --- */
  if (strcmp(name_buf, "span") == 0) {
    size_t style_len;
    const char *style_val = get_attr(el, "style", &style_len);
    css_styles_t styles = parse_css_style(style_val, style_len);

    /* Emit opening tags for detected styles */
    if (styles.bold)
      buffer_append_str(out, "<b>");
    if (styles.italic)
      buffer_append_str(out, "<i>");
    if (styles.underline)
      buffer_append_str(out, "<u>");
    if (styles.strikethrough)
      buffer_append_str(out, "<s>");

    walk_children(node, out);

    /* Emit closing tags in reverse */
    if (styles.strikethrough)
      buffer_append_str(out, "</s>");
    if (styles.underline)
      buffer_append_str(out, "</u>");
    if (styles.italic)
      buffer_append_str(out, "</i>");
    if (styles.bold)
      buffer_append_str(out, "</b>");
    return;
  }

  /* --- Handle <div> as a block element with style support --- */
  if (strcmp(name_buf, "div") == 0) {
    size_t style_len;
    const char *style_val = get_attr(el, "style", &style_len);
    css_styles_t styles = parse_css_style(style_val, style_len);

    /* Only wrap in <p> if the div has purely inline/text content.
     * If it contains block-level children (ul, ol, p, div, etc.),
     * just pass through to avoid invalid <p><ul>…</ul></p>. */
    bool wrap = needs_p_wrap(node) && !has_div_child(node);

    if (wrap)
      buffer_append_str(out, "<p>");

    if (styles.bold)
      buffer_append_str(out, "<b>");
    if (styles.italic)
      buffer_append_str(out, "<i>");
    if (styles.underline)
      buffer_append_str(out, "<u>");
    if (styles.strikethrough)
      buffer_append_str(out, "<s>");

    walk_children(node, out);

    if (styles.strikethrough)
      buffer_append_str(out, "</s>");
    if (styles.underline)
      buffer_append_str(out, "</u>");
    if (styles.italic)
      buffer_append_str(out, "</i>");
    if (styles.bold)
      buffer_append_str(out, "</b>");

    if (wrap)
      buffer_append_str(out, "</p>");
    return;
  }

  /* --- Handle table elements: extract text, separate cells --- */
  if (strcmp(name_buf, "table") == 0 || strcmp(name_buf, "thead") == 0 ||
      strcmp(name_buf, "tbody") == 0 || strcmp(name_buf, "tfoot") == 0 ||
      strcmp(name_buf, "tr") == 0 || strcmp(name_buf, "td") == 0 ||
      strcmp(name_buf, "th") == 0 || strcmp(name_buf, "caption") == 0 ||
      strcmp(name_buf, "colgroup") == 0 || strcmp(name_buf, "col") == 0) {
    /* For td/th: emit children then a space separator */
    if (strcmp(name_buf, "td") == 0 || strcmp(name_buf, "th") == 0) {
      walk_children(node, out);
      /* Only add space separator if there's a next cell sibling */
      lxb_dom_node_t *sib = lxb_dom_node_next(node);
      while (sib && sib->type != LXB_DOM_NODE_TYPE_ELEMENT)
        sib = lxb_dom_node_next(sib);
      if (sib)
        buffer_append_str(out, " ");
    } else if (strcmp(name_buf, "tr") == 0) {
      /* Each row becomes a paragraph (if non-empty) */
      buffer_t row_buf = buffer_create(64);
      walk_children(node, &row_buf);
      if (row_buf.len > 0) {
        buffer_append_str(out, "<p>");
        buffer_append(out, row_buf.data, row_buf.len);
        buffer_append_str(out, "</p>");
      }
      free(row_buf.data);
    } else {
      /* table, thead, tbody, etc.: just pass through children */
      walk_children(node, out);
    }
    return;
  }

  switch (cls) {
  case TAG_CLASS_PASS:
    /* html/body/head: just emit children */
    walk_children(node, out);
    break;

  case TAG_CLASS_SKIP:
    /* Unknown tags: strip tag, keep text content */
    walk_children(node, out);
    break;

  case TAG_CLASS_SELF_CLOSING:
    buffer_append_str(out, "<");
    buffer_append_str(out, out_name);
    emit_attributes(el, out_name, out);
    if (strcmp(out_name, "img") == 0)
      buffer_append_str(out, " />");
    else
      buffer_append_str(out, ">");
    break;

  case TAG_CLASS_INLINE:
  case TAG_CLASS_BLOCK: {
    /* Check for inline styles on block/inline elements too */
    size_t style_len;
    const char *style_val = get_attr(el, "style", &style_len);
    css_styles_t styles = parse_css_style(style_val, style_len);

    /* For semantic tags that already convey a style, don't double-emit.
     * E.g. <b style="font-weight:bold"> should not emit <b><b>. */
    bool is_already_bold = (strcmp(out_name, "b") == 0);
    bool is_already_italic = (strcmp(out_name, "i") == 0);
    bool is_already_underline = (strcmp(out_name, "u") == 0);
    bool is_already_strikethrough = (strcmp(out_name, "s") == 0);

    /* --- Special handling for <li>: flatten nested lists --- */
    if (strcmp(out_name, "li") == 0) {
      buffer_append_str(out, "<li");
      emit_attributes(el, "li", out);
      buffer_append_str(out, ">");

      if (styles.bold && !is_already_bold)
        buffer_append_str(out, "<b>");
      if (styles.italic && !is_already_italic)
        buffer_append_str(out, "<i>");
      if (styles.underline && !is_already_underline)
        buffer_append_str(out, "<u>");
      if (styles.strikethrough && !is_already_strikethrough)
        buffer_append_str(out, "<s>");

      /* Walk children but collect nested <ul>/<ol> for flattening */
      lxb_dom_node_t *nested_lists[16];
      int nested_count =
          walk_li_children_collecting(node, out, nested_lists, 16);

      if (styles.strikethrough && !is_already_strikethrough)
        buffer_append_str(out, "</s>");
      if (styles.underline && !is_already_underline)
        buffer_append_str(out, "</u>");
      if (styles.italic && !is_already_italic)
        buffer_append_str(out, "</i>");
      if (styles.bold && !is_already_bold)
        buffer_append_str(out, "</b>");

      buffer_append_str(out, "</li>");

      /* Flatten nested list items as siblings in the parent list */
      for (int i = 0; i < nested_count; i++) {
        walk_children(nested_lists[i], out);
      }
      break;
    }

    /* --- Special handling for <codeblock>: wrap inline content in <p> --- */
    if (strcmp(out_name, "codeblock") == 0) {
      buffer_append_str(out, "<codeblock>");
      if (needs_p_wrap(node))
        buffer_append_str(out, "<p>");
      walk_children(node, out);
      if (needs_p_wrap(node))
        buffer_append_str(out, "</p>");
      buffer_append_str(out, "</codeblock>");
      break;
    }

    /* Emit the tag itself */
    buffer_append_str(out, "<");
    buffer_append_str(out, out_name);
    emit_attributes(el, out_name, out);
    buffer_append_str(out, ">");

    /* Wrap children with extra style tags if CSS adds styles
     * that the tag doesn't already convey. */
    if (styles.bold && !is_already_bold)
      buffer_append_str(out, "<b>");
    if (styles.italic && !is_already_italic)
      buffer_append_str(out, "<i>");
    if (styles.underline && !is_already_underline)
      buffer_append_str(out, "<u>");
    if (styles.strikethrough && !is_already_strikethrough)
      buffer_append_str(out, "<s>");

    walk_children(node, out);

    if (styles.strikethrough && !is_already_strikethrough)
      buffer_append_str(out, "</s>");
    if (styles.underline && !is_already_underline)
      buffer_append_str(out, "</u>");
    if (styles.italic && !is_already_italic)
      buffer_append_str(out, "</i>");
    if (styles.bold && !is_already_bold)
      buffer_append_str(out, "</b>");

    /* Closing tag */
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

  /* Start from <body> if present, else from document element */
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
