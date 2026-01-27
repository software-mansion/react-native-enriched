export const DEFAULT_IMAGE_WIDTH = 80;
export const DEFAULT_IMAGE_HEIGHT = 80;

export const prepareImageDimensions = (
  assetWidth: number | undefined,
  assetHeight: number | undefined,
  width?: number,
  height?: number
) => {
  const imgWidth = assetWidth;
  const imgHeight = assetHeight;

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
