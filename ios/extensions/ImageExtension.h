#import <UIKit/UIKit.h>

/**
        UIImage (ImageExtension)

    This category adds class methods to `UIImage` to create an animated
   `UIImage` from animated image data (GIF or WebP).
*/
@interface UIImage (ImageExtension)

/*
        UIImage *animation = [UIImage animatedImageWithData:theData];

    I interpret `theData` as an animated image (GIF or WebP).  I create an
   animated `UIImage` using the source images and frame delays from the data.

    The image stores a separate duration for each frame, in units of
   centiseconds (hundredths of a second).  However, a `UIImage` only has a
   single, total `duration` property, which is a floating-point number.

    To handle this mismatch, I add each source image to `animation` a varying
   number of times to match the ratios between the frame durations.

    For example, suppose the image contains three frames.  Frame 0 has duration
   3.  Frame 1 has duration 9.  Frame 2 has duration 15.  I divide each
   duration by the greatest common denominator of all the durations, which is 3,
   and add each frame the resulting number of times.  Thus `animation` will
   contain frame 0 3/3 = 1 time, then frame 1 9/3 = 3 times, then frame 2
   15/3 = 5 times.  I set `animation.duration` to (3+9+15)/100 = 0.27 seconds.
*/
+ (UIImage *_Nullable)animatedImageWithData:(NSData *_Nonnull)theData;

@end
