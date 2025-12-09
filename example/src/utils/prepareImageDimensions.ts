import type { Asset } from 'react-native-image-picker';

export const DEFAULT_IMAGE_WIDTH = 80;
export const DEFAULT_IMAGE_HEIGHT = 80;

export const prepareImageDimensions = (
  asset: Asset,
  width: number | undefined,
  height: number | undefined
) => {
  const imgWidth = asset.width;
  const imgHeight = asset.height;

  const ratio = imgWidth && imgHeight ? imgWidth / imgHeight : 1;

  if (width && height) {
    return {
      finalWidth: width,
      finalHeight: height,
    };
  }

  if (width) {
    return {
      finalWidth: width,
      finalHeight: width / ratio,
    };
  }

  if (height) {
    return {
      finalHeight: height,
      finalWidth: height * ratio,
    };
  }

  if (imgWidth && imgHeight) {
    return {
      finalWidth: DEFAULT_IMAGE_WIDTH,
      finalHeight: DEFAULT_IMAGE_WIDTH / ratio,
    };
  }

  return {
    finalWidth: DEFAULT_IMAGE_WIDTH,
    finalHeight: DEFAULT_IMAGE_HEIGHT,
  };
};
