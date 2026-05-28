/*
 * Custom HTML normalizer for TipTap input.
 *
 * Runs after sanitize-html and handles project-specific transforms that mirror
 * the native GumboNormalizer (cpp/parser/GumboNormalizer.c)
 */
export function customNormalizeHtml(html: string): string {
  return html;
}
