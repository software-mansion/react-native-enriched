export function prepareHtmlForTiptap(html: string): string {
  return html.replace(/<br\s*\/?>/gi, '<p></p>');
}

export function normalizeHtmlFromTiptap(html: string): string {
  // Strip <p> wrappers inside <li> elements.
  // TipTap renders <li><p>text</p></li> but native expects <li>text</li>.
  let content = html.replace(
    /<li([^>]*)><p>(.*?)<\/p><\/li>/gs,
    '<li$1>$2</li>'
  );

  // Convert remaining empty <p></p> to <br> (outside of lists)
  content = content.replace(/<p><\/p>/g, '<br>');

  return `<html>${content}</html>`;
}
