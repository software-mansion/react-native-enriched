#pragma once
#import <UIKit/UIKit.h>

@interface NSLayoutManager (LayoutManagerExtension)
- (void)_drawListMarkerForRange:(NSRange)range atPoint:(CGPoint)point;
@end
