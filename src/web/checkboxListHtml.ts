/*
 * TipTap format for checkboxes:
 *   <ul data-type="taskList">
 *     <li data-type="taskItem" data-checked="false|true"><div><p>…</p></div></li>
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
    ul.setAttribute('data-type', 'taskList');

    ul.querySelectorAll('li').forEach((li) => {
      li.setAttribute('data-type', 'taskItem');

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

export function tiptapTaskListHtmlToNative(html: string): string {
  const parser = new DOMParser();
  const doc = parser.parseFromString(html, 'text/html');

  doc.querySelectorAll('ul[data-type="taskList"]').forEach((ul) => {
    ul.setAttribute('data-type', 'checkbox');

    ul.querySelectorAll('li[data-type="taskItem"]').forEach((li) => {
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
