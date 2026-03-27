export function prepareHtmlForTiptap(html: string): string {
  return html.replace(/<br\s*\/?>/gi, '<p></p>');
}

export function normalizeHtmlFromTiptap(html: string): string {
  const content = html.replace(/<p><\/p>/g, '<br>');
  return `<html>${content}</html>`;
}
