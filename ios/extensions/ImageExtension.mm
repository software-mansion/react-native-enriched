#import "ImageExtension.h"
#import <ImageIO/ImageIO.h>
#include <cmath>
#include <vector>

#if __has_feature(objc_arc)
#define toCF (__bridge CFTypeRef)
#define fromCF (__bridge id)
#else
#define toCF (CFTypeRef)
#define fromCF (id)
#endif

// implementation from:
// https://github.com/mayoff/uiimage-from-animated-gif/blob/master/uiimage-from-animated-gif/UIImage%2BanimatedGIF.m
@implementation UIImage (ImageExtension)

static int delayCentisecondsForImageAtIndex(CGImageSourceRef const source,
                                            size_t const i) {
  int delayCentiseconds = 1;
  CFDictionaryRef const properties =
      CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
  if (properties) {
    CFDictionaryRef const gifProperties = (CFDictionaryRef)CFDictionaryGetValue(
        properties, kCGImagePropertyGIFDictionary);
    if (gifProperties) {
      NSNumber *number = fromCF CFDictionaryGetValue(
          gifProperties, kCGImagePropertyGIFUnclampedDelayTime);
      if (number == NULL || [number doubleValue] == 0) {
        number = fromCF CFDictionaryGetValue(gifProperties,
                                             kCGImagePropertyGIFDelayTime);
      }
      if ([number doubleValue] > 0) {
        // Even though the GIF stores the delay as an integer number of
        // centiseconds, ImageIO “helpfully” converts that to seconds for us.
        delayCentiseconds = (int)lrint([number doubleValue] * 100);
      }
    }
    CFRelease(properties);
  }
  return delayCentiseconds;
}

// Changed to use std::vector references instead of C-arrays
static void createImagesAndDelays(CGImageSourceRef source, size_t count,
                                  std::vector<CGImageRef> &imagesOut,
                                  std::vector<int> &delayCentisecondsOut) {
  for (size_t i = 0; i < count; ++i) {
    imagesOut[i] = CGImageSourceCreateImageAtIndex(source, i, NULL);
    delayCentisecondsOut[i] = delayCentisecondsForImageAtIndex(source, i);
  }
}

static int sum(const std::vector<int> &values) {
  int theSum = 0;
  for (int value : values) {
    theSum += value;
  }
  return theSum;
}

static int pairGCD(int a, int b) {
  if (a < b)
    return pairGCD(b, a);
  while (true) {
    int const r = a % b;
    if (r == 0)
      return b;
    a = b;
    b = r;
  }
}

static int vectorGCD(const std::vector<int> &values) {
  if (values.empty())
    return 1;

  int gcd = values[0];
  for (size_t i = 1; i < values.size(); ++i) {
    // Note that after I process the first few elements of the vector, `gcd`
    // will probably be smaller than any remaining element. By passing the
    // smaller value as the second argument to `pairGCD`, I avoid making it swap
    // the arguments.
    gcd = pairGCD(values[i], gcd);
  }
  return gcd;
}

static NSArray *frameArray(const std::vector<CGImageRef> &images,
                           const std::vector<int> &delayCentiseconds,
                           int const totalDurationCentiseconds) {
  int const gcd = vectorGCD(delayCentiseconds);
  size_t const frameCount = totalDurationCentiseconds / gcd;

  // Replaced VLA with NSMutableArray for safety and OBJ-C++ compatibility
  NSMutableArray *frames = [NSMutableArray arrayWithCapacity:frameCount];

  for (size_t i = 0; i < images.size(); ++i) {
    UIImage *const frame = [UIImage imageWithCGImage:images[i]];
    for (size_t j = delayCentiseconds[i] / gcd; j > 0; --j) {
      [frames addObject:frame];
    }
  }
  return frames;
}

static void releaseImages(const std::vector<CGImageRef> &images) {
  for (CGImageRef image : images) {
    if (image)
      CGImageRelease(image);
  }
}

static UIImage *
animatedImageWithAnimatedGIFImageSource(CGImageSourceRef const source) {
  size_t const count = CGImageSourceGetCount(source);
  if (count == 0) {
    return nil;
  }

  // Replaced VLAs (variable length arrays) with std::vector
  std::vector<CGImageRef> images(count);
  std::vector<int> delayCentiseconds(count); // in centiseconds

  createImagesAndDelays(source, count, images, delayCentiseconds);

  int const totalDurationCentiseconds = sum(delayCentiseconds);
  NSArray *const frames =
      frameArray(images, delayCentiseconds, totalDurationCentiseconds);

  UIImage *const animation = [UIImage
      animatedImageWithImages:frames
                     duration:(NSTimeInterval)totalDurationCentiseconds /
                              100.0];

  releaseImages(images);
  return animation;
}

static UIImage *animatedImageWithAnimatedGIFReleasingImageSource(
    CGImageSourceRef CF_RELEASES_ARGUMENT source) {
  if (source) {
    UIImage *const image = animatedImageWithAnimatedGIFImageSource(source);
    CFRelease(source);
    return image;
  } else {
    return nil;
  }
}

+ (UIImage *)animatedImageWithAnimatedGIFData:(NSData *)data {
  return animatedImageWithAnimatedGIFReleasingImageSource(
      CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL));
}

@end
