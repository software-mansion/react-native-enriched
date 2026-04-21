import type { Page } from '@playwright/test';

export function toolbarButton(page: Page, id: string) {
  return page.locator(`[data-testid="toolbar-button-${id}"]`);
}
