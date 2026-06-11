/**
 * Best-effort intrinsic pixel size for pasted images (from Blob, with URL fallback).
 * Returns 0×0 when decode fails (caller still emits onPasteImages).
 */

export async function readImageDimensionsFromBlob(
  blob: Blob,
  fallbackUrl: string
): Promise<{ width: number; height: number }> {
  try {
    const bitmap = await createImageBitmap(blob);
    const { width, height } = bitmap;
    bitmap.close();
    return { width, height };
  } catch {
    return tryImageElementDimensions(fallbackUrl);
  }
}

function tryImageElementDimensions(
  url: string
): Promise<{ width: number; height: number }> {
  return new Promise((resolve) => {
    if (typeof Image === 'undefined') {
      resolve({ width: 0, height: 0 });
      return;
    }
    const img = new Image();
    img.onload = () => {
      const w = img.naturalWidth;
      const h = img.naturalHeight;
      resolve({
        width: Number.isFinite(w) ? w : 0,
        height: Number.isFinite(h) ? h : 0,
      });
    };
    img.onerror = () => resolve({ width: 0, height: 0 });
    img.src = url;
  });
}
