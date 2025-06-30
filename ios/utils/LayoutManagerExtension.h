#pragma once
#import <UIKit/UIKit.h>

@interface NSLayoutManager (LayoutManagerExtension)
@property (nonatomic, weak) id editor;
- (void)my_drawBackgroundForGlyphRange:(NSRange)glyphRange atPoint:(CGPoint)origin;
@end
