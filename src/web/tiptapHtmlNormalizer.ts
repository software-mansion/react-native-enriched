import sanitizeHtml from 'sanitize-html';
import {
  checkboxHtmlForTiptap,
  checkboxHtmlFromTiptap,
} from './checkboxHtmlNormalizer';
import { customNormalizeHtml } from './customHtmlNormalizer';

const SANITIZE_OPTIONS: sanitizeHtml.IOptions = {
  // TODO: tighten allowedTags/allowedAttributes/allowedStyles to match the set
  // of features our editor actually supports (mirroring GumboNormalizer's
  // classify_tag / emit_attributes logic).
};

export function prepareHtmlForTiptap(html: string): string {
  html = sanitizeHtml(html, SANITIZE_OPTIONS);
  html = customNormalizeHtml(html);
  html = checkboxHtmlForTiptap(html);
  html = html.replace(/<br\s*\/?>/gi, '<p></p>');
  return html;
}

export function normalizeHtmlFromTiptap(html: string): string {
  html = checkboxHtmlFromTiptap(html);

  // Strip <p> wrappers inside <li> elements.
  // TipTap renders <li><p>text</p></li> but native expects <li>text</li>.
  // This regex is safe because EnrichedListItem.content is 'paragraph', which
  // prevents TipTap from ever emitting nested lists
  html = html.replace(/<li([^>]*)><p>(.*?)<\/p><\/li>/gs, '<li$1>$2</li>');

  // Convert remaining empty <p></p> to <br> (outside of lists)
  html = html.replace(/<p><\/p>/g, '<br>');

  // Convert <img> tags to self-closing tags
  html = html.replace(/<img\b([^>]*)>/gi, (_, attrs: string) => {
    if (attrs.trimEnd().endsWith('/')) {
      return `<img${attrs}>`;
    }
    return `<img${attrs}/>`;
  });

  return `<html>${html}</html>`;
}
