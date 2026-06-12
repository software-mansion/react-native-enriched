/*
 * Custom HTML normalizer for TipTap input.
 * Mirrors the native GumboNormalizer (cpp/parser/GumboNormalizer.c)
 */

type CssStyles = {
  bold: boolean;
  italic: boolean;
  underline: boolean;
  strikethrough: boolean;
};

const INLINE_TAGS = new Set([
  'b',
  'i',
  'u',
  's',
  'code',
  'a',
  'strong',
  'em',
  'del',
  'strike',
  'ins',
  'mention',
]);

const BLOCK_TAGS = new Set([
  'p',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'ul',
  'ol',
  'li',
  'blockquote',
  'codeblock',
  'pre',
]);

const SELF_CLOSING_TAGS = new Set(['br', 'img']);

const PASS_TAGS = new Set(['html', 'head', 'body']);

const STRIPPED_TAGS = new Set(['meta', 'style', 'script', 'title', 'link']);

const TABLE_TAGS = new Set([
  'table',
  'thead',
  'tbody',
  'tfoot',
  'tr',
  'td',
  'th',
  'caption',
  'colgroup',
  'col',
]);

function canonicalName(name: string): string {
  switch (name) {
    case 'strong':
      return 'b';
    case 'em':
      return 'i';
    case 'del':
    case 'strike':
      return 's';
    case 'ins':
      return 'u';
    case 'pre':
      return 'codeblock';
    default:
      return name;
  }
}

type TagClass = 'skip' | 'inline' | 'block' | 'self-closing' | 'pass';

function classifyTag(name: string): TagClass {
  if (INLINE_TAGS.has(name)) return 'inline';
  if (BLOCK_TAGS.has(name)) return 'block';
  if (SELF_CLOSING_TAGS.has(name)) return 'self-closing';
  if (PASS_TAGS.has(name)) return 'pass';
  return 'skip';
}

function isElement(node: Node | null): node is Element {
  return !!node && node.nodeType === Node.ELEMENT_NODE;
}

function isText(node: Node | null): boolean {
  return !!node && node.nodeType === Node.TEXT_NODE;
}

function tagName(node: Node | null): string | null {
  if (!isElement(node)) return null;
  return node.tagName.toLowerCase();
}

function isListNode(node: Node | null): boolean {
  const n = tagName(node);
  return n === 'ul' || n === 'ol';
}

function isBlockquoteNode(node: Node | null): boolean {
  return tagName(node) === 'blockquote';
}

function isBrNode(node: Node | null): boolean {
  return tagName(node) === 'br';
}

function isBlockProducing(node: Node | null): boolean {
  const n = tagName(node);
  if (!n) return false;
  if (classifyTag(n) === 'block') return true;
  return n === 'div' || n === 'table' || n === 'tr';
}

function isPurelyInline(node: Element): boolean {
  for (const child of Array.from(node.childNodes)) {
    if (isBlockProducing(child)) return false;
  }
  return true;
}

function hasBlockOrBqChild(node: Element): boolean {
  for (const child of Array.from(node.childNodes)) {
    if (isBlockProducing(child) || isBlockquoteNode(child)) return true;
  }
  return false;
}

function findCssValue(style: string, prop: string): string | null {
  // Returns the value of the last declaration with this property name.
  // Mirrors GumboNormalizer's find_css_value scanning behavior.
  const re = new RegExp(
    `(?:^|;)\\s*${prop.replace(/[-/\\^$*+?.()|[\\]{}]/g, '\\$&')}\\s*:\\s*([^;]*)`,
    'gi'
  );
  let m: RegExpExecArray | null;
  let last: string | null = null;
  while ((m = re.exec(style)) !== null) {
    last = (m[1] ?? '').trim();
  }
  return last;
}

function findAllCssValues(style: string, prop: string): string[] {
  const re = new RegExp(
    `(?:^|;)\\s*${prop.replace(/[-/\\^$*+?.()|[\\]{}]/g, '\\$&')}\\s*:\\s*([^;]*)`,
    'gi'
  );
  const out: string[] = [];
  let m: RegExpExecArray | null;
  while ((m = re.exec(style)) !== null) {
    out.push((m[1] ?? '').trim());
  }
  return out;
}

function parseCssStyle(style: string | null): CssStyles {
  const result: CssStyles = {
    bold: false,
    italic: false,
    underline: false,
    strikethrough: false,
  };
  if (!style) return result;

  const fw = findCssValue(style, 'font-weight');
  if (fw) {
    const lower = fw.toLowerCase();
    if (lower.includes('bold') || lower.includes('bolder')) {
      result.bold = true;
    } else {
      const num = parseInt(fw, 10);
      if (!Number.isNaN(num) && num >= 700) result.bold = true;
    }
  }

  const fs = findCssValue(style, 'font-style');
  if (fs) {
    const lower = fs.toLowerCase();
    if (lower.includes('italic') || lower.includes('oblique'))
      result.italic = true;
  }

  // text-decoration / text-decoration-line: scan ALL declarations
  const decorations = [
    ...findAllCssValues(style, 'text-decoration-line'),
    ...findAllCssValues(style, 'text-decoration'),
  ];
  for (const v of decorations) {
    const lower = v.toLowerCase();
    if (lower.includes('underline')) result.underline = true;
    if (lower.includes('line-through')) result.strikethrough = true;
  }

  return result;
}

function extraStyles(s: CssStyles, tag: string): CssStyles {
  return {
    bold: s.bold && tag !== 'b',
    italic: s.italic && tag !== 'i',
    underline: s.underline && tag !== 'u',
    strikethrough: s.strikethrough && tag !== 's',
  };
}

function emitStylesOpen(s: CssStyles): string {
  let out = '';
  if (s.bold) out += '<b>';
  if (s.italic) out += '<i>';
  if (s.underline) out += '<u>';
  if (s.strikethrough) out += '<s>';
  return out;
}

function emitStylesClose(s: CssStyles): string {
  let out = '';
  if (s.strikethrough) out += '</s>';
  if (s.underline) out += '</u>';
  if (s.italic) out += '</i>';
  if (s.bold) out += '</b>';
  return out;
}

function emitOneAttr(el: Element, attr: string): string {
  const val = el.getAttribute(attr);
  if (val == null || val === '') return '';
  return ` ${attr}="${val}"`;
}

function emitAttributes(el: Element, name: string): string {
  switch (name) {
    case 'a':
      return emitOneAttr(el, 'href');
    case 'img':
      return (
        emitOneAttr(el, 'src') +
        emitOneAttr(el, 'alt') +
        emitOneAttr(el, 'width') +
        emitOneAttr(el, 'height')
      );
    case 'ul': {
      const val = el.getAttribute('data-type');
      return val === 'checkbox' ? ' data-type="checkbox"' : '';
    }
    case 'li':
      return el.hasAttribute('checked') ? ' checked' : '';
    case 'mention':
      return (
        emitOneAttr(el, 'id') +
        emitOneAttr(el, 'text') +
        emitOneAttr(el, 'indicator')
      );
    default:
      return '';
  }
}

function isGoogleDocsWrapper(el: Element, tag: string): boolean {
  if (tag !== 'b') return false;
  const id = el.getAttribute('id');
  return !!id && id.startsWith('docs-internal-guid-') && id.length > 20;
}

function escapeText(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

// --- Blockquote content flattening ---

function flushInlineP(ib: { buf: string }, out: { buf: string }): void {
  if (ib.buf.length > 0) {
    out.buf += `<p>${ib.buf}</p>`;
    ib.buf = '';
  }
}

function flattenBqChildren(
  node: Element,
  ib: { buf: string },
  out: { buf: string }
): void {
  for (const child of Array.from(node.childNodes)) {
    flattenBqNode(child, ib, out);
  }
}

function flattenBqNode(
  node: Node,
  ib: { buf: string },
  out: { buf: string }
): void {
  if (isText(node)) {
    const t = node.textContent ?? '';
    ib.buf += escapeText(t);
    return;
  }
  if (!isElement(node)) return;
  if (isBrNode(node)) {
    flushInlineP(ib, out);
    return;
  }
  if (isBlockProducing(node) || isBlockquoteNode(node)) {
    flushInlineP(ib, out);
    flattenBqChildren(node, ib, out);
    flushInlineP(ib, out);
    return;
  }
  walkNode(node, ib);
}

// --- List item content flattening ---

type LiCtx = {
  el: Element;
  styles: CssStyles;
  nestedLists: Element[];
};

function flushLiBuffer(
  ib: { buf: string },
  out: { buf: string },
  ctx: LiCtx
): void {
  if (ib.buf.length === 0) return;
  out.buf += `<li${emitAttributes(ctx.el, 'li')}>`;
  out.buf += emitStylesOpen(ctx.styles);
  out.buf += ib.buf;
  out.buf += emitStylesClose(ctx.styles);
  out.buf += '</li>';
  ib.buf = '';
}

function flattenLiChildren(
  node: Element,
  ib: { buf: string },
  out: { buf: string },
  ctx: LiCtx
): void {
  for (const child of Array.from(node.childNodes)) {
    flattenLiNode(child, ib, out, ctx);
  }
}

function flattenLiNode(
  node: Node,
  ib: { buf: string },
  out: { buf: string },
  ctx: LiCtx
): void {
  if (isText(node)) {
    ib.buf += escapeText(node.textContent ?? '');
    return;
  }
  if (!isElement(node)) return;
  if (isListNode(node)) {
    ctx.nestedLists.push(node);
    return;
  }
  if (isBrNode(node)) {
    flushLiBuffer(ib, out, ctx);
    return;
  }
  if (isBlockProducing(node) || isBlockquoteNode(node)) {
    flushLiBuffer(ib, out, ctx);
    flattenLiChildren(node, ib, out, ctx);
    flushLiBuffer(ib, out, ctx);
    return;
  }
  walkNode(node, ib);
}

// --- Main walker ---

function walkChildren(node: Element, out: { buf: string }): void {
  const children = Array.from(node.childNodes);
  const parentIsList = isListNode(node);

  let hasBlock = false;
  for (const c of children) {
    if (isBlockProducing(c)) {
      hasBlock = true;
      break;
    }
  }

  let i = 0;
  while (i < children.length) {
    const child = children[i]!;

    // Flatten list-inside-list
    if (parentIsList && isElement(child) && isListNode(child)) {
      walkChildren(child, out);
      i++;
      continue;
    }

    // Merge consecutive blockquotes
    if (isElement(child) && isBlockquoteNode(child)) {
      out.buf += '<blockquote>';
      const bqIb = { buf: '' };
      while (i < children.length) {
        const cur = children[i];
        if (!cur || !isElement(cur) || !isBlockquoteNode(cur)) break;
        flattenBqChildren(cur, bqIb, out);
        i++;
      }
      flushInlineP(bqIb, out);
      out.buf += '</blockquote>';
      continue;
    }

    // Auto-paragraph: group inline runs into <p> when mixed with blocks
    if (
      hasBlock &&
      !parentIsList &&
      !isBlockProducing(child) &&
      !(isElement(child) && isBlockquoteNode(child))
    ) {
      const ib = { buf: '' };
      while (i < children.length) {
        const cur = children[i]!;
        if (
          isBlockProducing(cur) ||
          (isElement(cur) && isBlockquoteNode(cur))
        ) {
          break;
        }
        if (isElement(cur) && isBrNode(cur)) {
          if (ib.buf.length > 0) {
            flushInlineP(ib, out);
          } else {
            out.buf += '<br>';
          }
          i++;
          continue;
        }
        // Transparent inline wrapper for block/bq children
        if (isElement(cur) && hasBlockOrBqChild(cur)) {
          flushInlineP(ib, out);
          walkChildren(cur, out);
          i++;
          continue;
        }
        walkNode(cur, ib);
        i++;
      }
      flushInlineP(ib, out);
      continue;
    }

    walkNode(child, out);
    i++;
  }
}

function walkNode(node: Node, out: { buf: string }): void {
  if (isText(node)) {
    out.buf += escapeText(node.textContent ?? '');
    return;
  }
  if (!isElement(node)) return;

  const name = node.tagName.toLowerCase();

  if (STRIPPED_TAGS.has(name)) return;

  if (isGoogleDocsWrapper(node, name)) {
    walkChildren(node, out);
    return;
  }

  const outName = canonicalName(name);
  const cls = classifyTag(name);

  // <span>: CSS style → inline tags
  if (name === 'span') {
    const s = parseCssStyle(node.getAttribute('style'));
    out.buf += emitStylesOpen(s);
    walkChildren(node, out);
    out.buf += emitStylesClose(s);
    return;
  }

  // <div>: becomes <p> or passes through
  if (name === 'div') {
    const s = parseCssStyle(node.getAttribute('style'));
    if (isPurelyInline(node)) {
      const pb = { buf: '' };
      for (const dc of Array.from(node.childNodes)) {
        if (isElement(dc) && isBrNode(dc)) {
          if (pb.buf.length > 0) {
            out.buf += `<p>${emitStylesOpen(s)}${pb.buf}${emitStylesClose(s)}</p>`;
          } else {
            out.buf += '<br>';
          }
          pb.buf = '';
          continue;
        }
        walkNode(dc, pb);
      }
      if (pb.buf.length > 0) {
        out.buf += `<p>${emitStylesOpen(s)}${pb.buf}${emitStylesClose(s)}</p>`;
      }
    } else {
      out.buf += emitStylesOpen(s);
      walkChildren(node, out);
      out.buf += emitStylesClose(s);
    }
    return;
  }

  // Table elements
  if (TABLE_TAGS.has(name)) {
    if (name === 'td' || name === 'th') {
      walkChildren(node, out);
      // Append space if there is a next element sibling
      let sib: Node | null = node.nextSibling;
      while (sib && !isElement(sib)) sib = sib.nextSibling;
      if (sib) out.buf += ' ';
    } else if (name === 'tr') {
      const row = { buf: '' };
      walkChildren(node, row);
      if (row.buf.length > 0) {
        out.buf += `<p>${row.buf}</p>`;
      }
    } else {
      walkChildren(node, out);
    }
    return;
  }

  if (cls === 'pass' || cls === 'skip') {
    walkChildren(node, out);
    return;
  }

  if (cls === 'self-closing') {
    out.buf += `<${outName}${emitAttributes(node, outName)}`;
    out.buf += outName === 'img' ? ' />' : '>';
    return;
  }

  // inline or block
  const es = extraStyles(parseCssStyle(node.getAttribute('style')), outName);

  // <li>: flatten
  if (outName === 'li') {
    const nestedLists: Element[] = [];
    const liIb = { buf: '' };
    const ctx: LiCtx = { el: node, styles: es, nestedLists };
    flattenLiChildren(node, liIb, out, ctx);
    flushLiBuffer(liIb, out, ctx);
    for (const nl of nestedLists) walkChildren(nl, out);
    return;
  }

  // <codeblock>: wrap inline content in <p>
  if (outName === 'codeblock') {
    const wrap = isPurelyInline(node);
    out.buf += '<codeblock>';
    if (wrap) out.buf += '<p>';
    walkChildren(node, out);
    if (wrap) out.buf += '</p>';
    out.buf += '</codeblock>';
    return;
  }

  // Generic block/inline
  out.buf += `<${outName}${emitAttributes(node, outName)}>`;
  out.buf += emitStylesOpen(es);
  walkChildren(node, out);
  out.buf += emitStylesClose(es);
  out.buf += `</${outName}>`;
}

export function normalizeHtml(html: string): string {
  const parser = new DOMParser();
  const doc = parser.parseFromString(`<body>${html}</body>`, 'text/html');
  const body = doc.body;
  const out = { buf: '' };
  walkChildren(body, out);
  return out.buf;
}
