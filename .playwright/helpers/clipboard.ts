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
