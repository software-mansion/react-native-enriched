/*
 * TipTap format for checkboxes:
 *   <ul data-type="checkboxList">
 *     <li data-type="checkboxItem" data-checked="false|true"><div><p>…</p></div></li>
 *   </ul>
 *
 * Native format for checkboxes:
 *   <ul data-type="checkbox">
 *     <li>…</li>
 *     <li checked>…</li>
 *   </ul>
 */
export function nativeCheckboxHtmlToTiptapHtml(html: string): string {
  const parser = new DOMParser();
  const doc = parser.parseFromString(html, 'text/html');

  doc.querySelectorAll('ul[data-type="checkbox"]').forEach((ul) => {
    ul.setAttribute('data-type', 'checkboxList');

    ul.querySelectorAll('li').forEach((li) => {
      li.setAttribute('data-type', 'checkboxItem');

      if (li.hasAttribute('checked')) {
        li.setAttribute('data-checked', 'true');
        li.removeAttribute('checked');
      } else {
        li.setAttribute('data-checked', 'false');
      }

      const innerContent = li.innerHTML;
      li.innerHTML = `<p>${innerContent}</p>`;
    });
  });

  return doc.body.innerHTML;
}

export function tiptapCheckboxListHtmlToNative(html: string): string {
  const parser = new DOMParser();
  const doc = parser.parseFromString(html, 'text/html');

  doc.querySelectorAll('ul[data-type="checkboxList"]').forEach((ul) => {
    ul.setAttribute('data-type', 'checkbox');

    ul.querySelectorAll('li[data-type="checkboxItem"]').forEach((li) => {
      if (li.getAttribute('data-checked') === 'true') {
        li.setAttribute('checked', '');
      }

      li.removeAttribute('data-type');
      li.removeAttribute('data-checked');

      const pTag = li.querySelector('div > p');
      li.innerHTML = pTag ? pTag.innerHTML : '';
    });
  });

  return doc.body.innerHTML.replace(/checked=""/g, 'checked');
}
