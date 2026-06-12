/**
 * Collect image `File`s from the clipboard and build `OnPasteImagesEvent` payloads with `blob:` URIs.
 */

import type { Editor } from '@tiptap/react';
import type { NativeSyntheticEvent } from 'react-native';

import type { OnPasteImagesEvent } from '../types';
import { adaptWebToNativeEvent } from './adaptWebToNativeEvent';
import { isImageBlocked } from './formats/formatRules';
import { readImageDimensionsFromBlob } from './pastedImageDimensions';

const isImageLikeClipboardFile = (file: File, reportedMime: string) =>
  reportedMime.startsWith('image/') || file.type.startsWith('image/');

/** Browsers often expose the same paste as two `File`s (items vs files) with different `name`. */
function dedupeImageFiles(files: File[]): File[] {
  const seen = new Set<string>();
  const out: File[] = [];
  for (const file of files) {
    const key = `${file.size}\0${file.lastModified}\0${file.type}`;
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(file);
  }
  return out;
}

export function clipboardImageFiles(data: DataTransfer): File[] {
  const fromItems: File[] = [];
  for (const item of [...data.items]) {
    if (item == null || item.kind !== 'file') continue;
    const file = item.getAsFile();
    if (!file) continue;
    if (isImageLikeClipboardFile(file, item.type)) fromItems.push(file);
  }
  if (fromItems.length > 0) return dedupeImageFiles(fromItems);

  const fromFiles: File[] = [];
  for (const file of [...data.files]) {
    if (isImageLikeClipboardFile(file, file.type)) fromFiles.push(file);
  }
  return dedupeImageFiles(fromFiles);
}

export async function buildPasteImagesPayload(
  files: File[]
): Promise<OnPasteImagesEvent['images']> {
  return Promise.all(
    files.map(async (file) => {
      const uri = URL.createObjectURL(file);
      const { width, height } = await readImageDimensionsFromBlob(file, uri);
      return {
        uri,
        type: file.type || 'image/png',
        width,
        height,
      };
    })
  );
}

export function handleClipboardPasteImages(
  event: ClipboardEvent,
  getEditor: () => Editor | null,
  getOnPasteImages: () =>
    | ((e: NativeSyntheticEvent<OnPasteImagesEvent>) => void)
    | undefined
): boolean {
  const clipboardData = event.clipboardData;
  if (!clipboardData) return false;

  const files = clipboardImageFiles(clipboardData);
  if (files.length === 0) return false;

  const ed = getEditor();
  if (!ed || isImageBlocked(ed)) return false;

  const onPasteImages = getOnPasteImages();
  if (!onPasteImages) return false;

  event.preventDefault();

  (async () => {
    try {
      const images = await buildPasteImagesPayload(files);
      const editor = getEditor();
      if (!editor || isImageBlocked(editor)) return;
      onPasteImages(adaptWebToNativeEvent(event, { images }));
    } catch (err) {
      console.error(err);
    }
  })();

  return true;
}
