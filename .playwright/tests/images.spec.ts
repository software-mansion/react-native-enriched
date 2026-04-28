import { test, expect } from '@playwright/test';

import { toolbarButton } from '../helpers/toolbar';
import {
  editorLocator,
  getSerializedHtml,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

test.describe('images', () => {
  test.beforeEach(async ({ page }) => {
    await gotoVisualRegression(page);

    const routePattern = '**/pw-e2e-ok.png';
    const pngBody = Buffer.from(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      'base64'
    );
    await page.route(routePattern, async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'image/png',
        body: pngBody,
      });
    });
  });

  test('empty src shows placeholder only', async ({ page }) => {
    const snapshotName = 'images-placeholder-empty-src.png';
    await setEditorHtml(
      page,
      '<html><p>Hi <img src="" width="40" height="40" /> bye</p></html>'
    );

    await expect(page.locator('[data-eti-image-placeholder]')).toBeVisible();
    await expect(page.locator('.eti-inline-image-img')).toHaveCount(0);

    await expect(editorLocator(page)).toHaveScreenshot(snapshotName);
  });

  test('broken image URL shows placeholder after onError', async ({ page }) => {
    const routePattern = '**/pw-e2e-broken.png';
    const snapshotName = 'images-placeholder-broken-url.png';
    await page.route(routePattern, (route) => route.abort());

    await setEditorHtml(
      page,
      '<html><p><img src="/pw-e2e-broken.png" width="40" height="40" /></p></html>'
    );

    await expect(page.locator('[data-eti-image-placeholder]')).toBeVisible({
      timeout: 15_000,
    });
    await expect(page.locator('.eti-inline-image-img')).toHaveCount(0);

    await expect(editorLocator(page)).toHaveScreenshot(snapshotName);
  });

  test('real PNG shows img element', async ({ page }) => {
    const snapshotName = 'images-inline-routed-png.png';

    await setEditorHtml(
      page,
      '<html><p><img src="/pw-e2e-ok.png" width="32" height="32" /></p></html>'
    );

    await expect(page.locator('.eti-inline-image-img')).toBeVisible({
      timeout: 15_000,
    });
    await expect(page.locator('[data-eti-image-placeholder]')).toHaveCount(0);

    await expect(editorLocator(page)).toHaveScreenshot(snapshotName);
  });

  test('image attrs round-trip in serialized HTML', async ({ page }) => {
    await setEditorHtml(
      page,
      '<html><p><img src="https://example.com/pic.png" width="120" height="60" alt="x" /></p></html>'
    );

    await expect
      .poll(async () => getSerializedHtml(page))
      .toMatch(/<img[^>]*src="https:\/\/example\.com\/pic\.png"/i);
    await expect
      .poll(async () => getSerializedHtml(page))
      .toMatch(/width="120"/i);
    await expect
      .poll(async () => getSerializedHtml(page))
      .toMatch(/height="60"/i);
    await expect
      .poll(async () => getSerializedHtml(page))
      .not.toMatch(/alt="x"/i);
  });

  test.describe('visual: image with blocks and lists', () => {
    const visualBlockListCases = [
      {
        name: 'paragraph with placeholder image',
        snapshot: 'images-paragraph-placeholder.png',
        html: '<html><p>Before <img src="" width="40" height="40" /> after</p></html>',
      },
      {
        name: 'blockquote with placeholder image',
        snapshot: 'images-blockquote-placeholder.png',
        html: '<html><blockquote><p>Before <img src="" width="40" height="40" /> after</p></blockquote></html>',
      },
      {
        name: 'unordered list item with placeholder image',
        snapshot: 'images-ul-placeholder.png',
        html: '<html><ul><li><p>Item <img src="" width="40" height="40" /> end</p></li></ul></html>',
      },
      {
        name: 'ordered list item with placeholder image',
        snapshot: 'images-ol-placeholder.png',
        html: '<html><ol><li><p>Step <img src="" width="40" height="40" /> done</p></li></ol></html>',
      },
      {
        name: 'loaded image inside list (routed PNG)',
        snapshot: 'images-loaded-in-list.png',
        html: '<html><ul><li><p>See <img src="/pw-e2e-ok.png" width="28" height="28" /> tiny</p></li></ul></html>',
      },
    ] as const;

    for (const row of visualBlockListCases) {
      test(row.name, async ({ page }) => {
        await setEditorHtml(page, row.html);

        await expect(page.locator('.eti-inline-image')).toBeVisible({
          timeout: 15_000,
        });

        await expect(editorLocator(page)).toHaveScreenshot(row.snapshot);
      });
    }
  });

  test('strip marks on image: bold italic strike underline code leave img unwrapped', async ({
    page,
  }) => {
    const expectedHtml =
      '<html><p><code><b><i><u><s>Alpha </s></u></i></b></code><img width="48" height="48" src=""><code><b><i><u><s> Beta</s></u></i></b></code></p></html>';
    const toolbarOrder = [
      'bold',
      'italic',
      'strikeThrough',
      'underline',
      'inlineCode',
    ] as const;

    await setEditorHtml(
      page,
      '<html><p>Alpha <img src="" width="48" height="48" /> Beta</p></html>'
    );

    const editor = editorLocator(page);
    for (const key of toolbarOrder) {
      await editor.click();
      await editor.press('Meta+A');
      await toolbarButton(page, key).click();
    }

    await expect.poll(async () => getSerializedHtml(page)).toBe(expectedHtml);
  });
});
