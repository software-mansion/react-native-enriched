#import "LayoutManagerExtension.h"
#import <objc/runtime.h>
#import "ReactNativeRichTextEditorView.h"
#import "StyleHeaders.h"

@implementation NSLayoutManager (LayoutManagerExtension)

+ (void)load {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Class myClass = [NSLayoutManager class];
    SEL originalSelector = @selector(drawBackgroundForGlyphRange:atPoint:);
    SEL swizzledSelector = @selector(my_drawBackgroundForGlyphRange:atPoint:);
    Method originalMethod = class_getInstanceMethod(myClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(myClass, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(myClass, originalSelector,
      method_getImplementation(swizzledMethod),
      method_getTypeEncoding(swizzledMethod)
    );
    
    if(didAddMethod) {
      class_replaceMethod(myClass, swizzledSelector,
        method_getImplementation(originalMethod),
        method_getTypeEncoding(originalMethod)
      );
    } else {
      method_exchangeImplementations(originalMethod, swizzledMethod);
    }
  });
}

- (void)my_drawBackgroundForGlyphRange:(NSRange)glyphRange atPoint:(CGPoint)origin {
  [self my_drawBackgroundForGlyphRange:glyphRange atPoint:origin];
  
  ReactNativeRichTextEditorView *typedEditor = (ReactNativeRichTextEditorView *)self.editor;
  if(typedEditor == nullptr) { return; }
  
  BlockQuoteStyle *bqStyle = typedEditor->stylesDict[@([BlockQuoteStyle getStyleType])];
  if(bqStyle == nullptr) { return; }
  
  // it isn't the most performant but we have to check for all the blockquotes each time and redraw them
  NSArray *allBlockquotes = [bqStyle findAllOccurences:NSMakeRange(0, typedEditor->textView.textStorage.length)];
  
  for(StylePair *pair in allBlockquotes) {
    NSRange paragraphRange = [typedEditor->textView.textStorage.string paragraphRangeForRange:[pair.rangeValue rangeValue]];
    NSRange paragraphGlyphRange = [self glyphRangeForCharacterRange:paragraphRange actualCharacterRange:nullptr];
    [self enumerateLineFragmentsForGlyphRange:paragraphGlyphRange
      usingBlock:^(CGRect rect, CGRect usedRect, NSTextContainer * _Nonnull textContainer, NSRange glyphRange, BOOL * _Nonnull stop) {
        CGFloat paddingLeft = origin.x;
        CGFloat paddingTop = origin.y;
        CGFloat x = paddingLeft + 16; // TODO: blockquote style config
        CGFloat y = paddingTop + rect.origin.y;
        CGFloat width = 4; // TODO: blockquote style config
        CGFloat height = rect.size.height;
        
        CGRect lineRect = CGRectMake(x, y, width, height);
        [[UIColor blueColor] setFill];
        UIRectFill(lineRect);
      }
    ];
  }
}

- (id)editor {
  return objc_getAssociatedObject(self, @selector(editor));
}

- (void)setEditor:(id)editor {
  objc_setAssociatedObject(self, @selector(editor), editor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
