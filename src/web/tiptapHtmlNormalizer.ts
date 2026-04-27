import {
  nativeCheckboxHtmlToTiptapHtml,
  tiptapTaskListHtmlToNative,
} from './checkboxListHtml';

export function prepareHtmlForTiptap(html: string): string {
  const withBrAsP = html.replace(/<br\s*\/?>/gi, '<p></p>');
  return nativeCheckboxHtmlToTiptapHtml(withBrAsP);
}

export function normalizeHtmlFromTiptap(html: string): string {
  const nativeTaskHtml = tiptapTaskListHtmlToNative(html);

  // Strip <p> wrappers inside <li> elements.
  // TipTap renders <li><p>text</p></li> but native expects <li>text</li>.
  // This regex is safe because EnrichedListItem.content is 'paragraph', which
  // prevents TipTap from ever emitting nested lists
  let content = nativeTaskHtml.replace(
    /<li([^>]*)><p>(.*?)<\/p><\/li>/gs,
    '<li$1>$2</li>'
  );

  // Convert remaining empty <p></p> to <br> (outside of lists)
  content = content.replace(/<p><\/p>/g, '<br>');

  return `<html>${content}</html>`;
}
