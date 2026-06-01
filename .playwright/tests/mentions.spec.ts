import { test, expect, type Page } from '@playwright/test';
import {
  editorLocator,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

test.setTimeout(90_000);

const sel = {
  editorContent: '[data-testid="mention-test-editor"] .eti-editor',
  eventType: '[data-testid="mention-event-type"]',
  eventIndicator: '[data-testid="mention-event-indicator"]',
  eventText: '[data-testid="mention-event-text"]',
  htmlOutput: '[data-testid="mention-html-output"]',
  detectedCount: '[data-testid="mention-detected-count"]',
  detectedText: '[data-testid="mention-detected-text"]',
  detectedIndicator: '[data-testid="mention-detected-indicator"]',
  blurTarget: '[data-testid="mention-blur-target"]',
  setUserButton: '[data-testid="mention-set-user-button"]',
  setChannelButton: '[data-testid="mention-set-channel-button"]',
  startUserButton: '[data-testid="mention-start-user-button"]',
  startChannelButton: '[data-testid="mention-start-channel-button"]',
} as const;

async function gotoMentionTest(page: Page): Promise<void> {
  await page.goto('/test-mentions');
  await page.waitForSelector(sel.editorContent);
}

function mentionEditor(page: Page) {
  return page.locator(sel.editorContent);
}

function eventType(page: Page) {
  return page.locator(sel.eventType);
}
function eventIndicator(page: Page) {
  return page.locator(sel.eventIndicator);
}
function eventText(page: Page) {
  return page.locator(sel.eventText);
}
function htmlOutput(page: Page) {
  return page.locator(sel.htmlOutput);
}
function detectedCount(page: Page) {
  return page.locator(sel.detectedCount);
}
function detectedText(page: Page) {
  return page.locator(sel.detectedText);
}
function detectedIndicator(page: Page) {
  return page.locator(sel.detectedIndicator);
}

test('@ triggers start event', async ({ page }) => {
  await gotoMentionTest(page);
  const editor = mentionEditor(page);
  await editor.click();
  await editor.pressSequentially('@', { delay: 80 });
  await expect(eventType(page)).toHaveText('start');
  await expect(eventIndicator(page)).toHaveText('@');
  await expect(eventText(page)).toHaveText('');
});

test('# triggers start event', async ({ page }) => {
  await gotoMentionTest(page);
  const editor = mentionEditor(page);
  await editor.click();
  await editor.pressSequentially('#', { delay: 80 });
  await expect(eventType(page)).toHaveText('start');
  await expect(eventIndicator(page)).toHaveText('#');
});

test('query text updates on each keystroke', async ({ page }) => {
  await gotoMentionTest(page);
  const editor = mentionEditor(page);
  await editor.click();
  await editor.pressSequentially('@Jane', { delay: 80 });
  await expect(eventText(page)).toHaveText('Jane');
});

test('one space in query keeps mention active', async ({ page }) => {
  await gotoMentionTest(page);
  const editor = mentionEditor(page);
  await editor.click();
  await editor.pressSequentially('@a ', { delay: 80 });
  await expect(eventType(page)).toHaveText('change');
});

test('two spaces end the mention', async ({ page }) => {
  await gotoMentionTest(page);
  const editor = mentionEditor(page);
  await editor.click();
  await editor.pressSequentially('@a  ', { delay: 80 });
  await expect(eventType(page)).toHaveText('end');
});

test('blur ends an active mention', async ({ page }) => {
  await gotoMentionTest(page);
  const editor = mentionEditor(page);
  await editor.click();
  await editor.pressSequentially('@Jane', { delay: 80 });
  await page.locator(sel.blurTarget).click();
  await expect(eventType(page)).toHaveText('end');
});

test('setMention outputs correct HTML attributes', async ({ page }) => {
  await gotoMentionTest(page);
  const editor = mentionEditor(page);
  await editor.click();
  await editor.pressSequentially('@', { delay: 80 });
  await page.locator(sel.setUserButton).click();
  await expect
    .poll(async () => {
      const html = await htmlOutput(page).textContent();
      return (
        html?.includes('indicator="@"') &&
        html?.includes('text="Jane"') &&
        html?.includes('id="1"')
      );
    })
    .toBe(true);
});

test('typing after setMention is not wrapped in mention', async ({ page }) => {
  await gotoMentionTest(page);
  const editor = mentionEditor(page);
  await editor.click();
  await editor.pressSequentially('@', { delay: 80 });
  await page.locator(sel.setUserButton).click();
  await expect
    .poll(async () =>
      (await htmlOutput(page).textContent())?.includes('<mention')
    )
    .toBe(true);
  await editor.click();
  await editor.press('End');
  await editor.pressSequentially(' more', { delay: 80 });
  await expect
    .poll(async () => {
      const html = await htmlOutput(page).textContent();
      return (
        html?.includes('Jane</mention>') && !html?.includes('more</mention>')
      );
    })
    .toBe(true);
});

test('setMention with # indicator outputs correct HTML attributes', async ({
  page,
}) => {
  await gotoMentionTest(page);
  const editor = mentionEditor(page);
  await editor.click();
  await editor.pressSequentially('#', { delay: 80 });
  await page.locator(sel.setChannelButton).click();
  await expect
    .poll(async () => {
      const html = await htmlOutput(page).textContent();
      return (
        html?.includes('indicator="#"') &&
        html?.includes('text="general"') &&
        html?.includes('id="42"')
      );
    })
    .toBe(true);
});

test('startMention (user) fires onStartMention', async ({ page }) => {
  await gotoMentionTest(page);
  const editor = mentionEditor(page);
  await editor.click();
  await page.locator(sel.startUserButton).click();
  await expect(eventType(page)).toHaveText('start');
  await expect(eventIndicator(page)).toHaveText('@');
});

test('startMention (channel) fires onStartMention', async ({ page }) => {
  await gotoMentionTest(page);
  const editor = mentionEditor(page);
  await editor.click();
  await page.locator(sel.startChannelButton).click();
  await expect(eventType(page)).toHaveText('start');
  await expect(eventIndicator(page)).toHaveText('#');
});

test('entering a mention fires onMentionDetected with correct data', async ({
  page,
}) => {
  await gotoMentionTest(page);
  const editor = mentionEditor(page);
  await editor.click();
  await editor.pressSequentially('@', { delay: 80 });
  await page.locator(sel.setUserButton).click();
  await expect
    .poll(async () =>
      (await htmlOutput(page).textContent())?.includes('<mention')
    )
    .toBe(true);
  await editor.click();
  await editor.press('End');
  await editor.press('ArrowLeft'); // skip trailing space after mention
  await editor.press('ArrowLeft'); // caret inside mention text
  await expect(detectedCount(page)).toHaveText('1');
  await expect(detectedText(page)).toHaveText('Jane');
  await expect(detectedIndicator(page)).toHaveText('@');
});

test('moving within the same mention does not re-fire onMentionDetected', async ({
  page,
}) => {
  await gotoMentionTest(page);
  const editor = mentionEditor(page);
  await editor.click();
  await editor.pressSequentially('@', { delay: 80 });
  await page.locator(sel.setUserButton).click();
  await expect
    .poll(async () =>
      (await htmlOutput(page).textContent())?.includes('<mention')
    )
    .toBe(true);
  await editor.click();
  await editor.press('End');
  await editor.press('ArrowLeft');
  await editor.press('ArrowLeft'); // enter mention - count = 1
  await editor.press('ArrowLeft'); // move within mention
  await editor.press('ArrowRight'); // move within mention
  await expect(detectedCount(page)).toHaveText('1');
});

test('moving out of a mention fires clear onMentionDetected', async ({
  page,
}) => {
  await gotoMentionTest(page);
  const editor = mentionEditor(page);
  await editor.click();
  await editor.pressSequentially('@', { delay: 80 });
  await page.locator(sel.setUserButton).click();
  await expect
    .poll(async () =>
      (await htmlOutput(page).textContent())?.includes('<mention')
    )
    .toBe(true);
  await editor.click();
  await editor.press('End');
  await editor.press('ArrowLeft'); // skip trailing space after mention
  await editor.press('ArrowLeft'); // caret inside mention text
  await expect(detectedCount(page)).toHaveText('1');
  await editor.press('End');
  await editor.press('Enter');
  await expect(detectedCount(page)).toHaveText('2');
  await expect(detectedText(page)).toHaveText('');
  await expect(detectedIndicator(page)).toHaveText('');
});

test('mention renders correctly', async ({ page }) => {
  await gotoVisualRegression(page);
  await setEditorHtml(
    page,
    '<html><p>Hello <mention indicator="@" text="@Jane" id="1">@Jane</mention> world</p></html>'
  );
  await expect(editorLocator(page)).toHaveScreenshot('mention-visual.png');
});
