import type { Locator } from '@playwright/test';

export async function copySelectionFrom(locator: Locator): Promise<void> {
  await locator.click();
  await locator.click({ clickCount: 3 });
  await locator.page().keyboard.press('ControlOrMeta+C');
}

export async function pasteInto(locator: Locator): Promise<void> {
  await locator.click();
  await locator.click({ clickCount: 3 });
  await locator.page().keyboard.press('ControlOrMeta+V');
}

export async function copyAndPasteBetween(
  source: Locator,
  dest: Locator
): Promise<void> {
  await copySelectionFrom(source);
  await pasteInto(dest);
}

export async function pastePlainTextIntoEditor(
  editorInnerLocator: Locator,
  text: string
): Promise<void> {
  const pm = editorInnerLocator.locator('.ProseMirror');
  await pm.click();
  await pm.evaluate((el, t) => {
    const dt = new DataTransfer();
    dt.setData('text/plain', t);
    el.dispatchEvent(
      new ClipboardEvent('paste', {
        clipboardData: dt,
        bubbles: true,
        cancelable: true,
      })
    );
  }, text);
}
