#import "LayoutManagerExtension.h"
#import <objc/runtime.h>
#import "EditorManager.h"
#import "ReactNativeRichTextEditorView.h"
#import "StyleHeaders.h"
#import "ParagraphsUtils.h"

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
  
  id editor = [EditorManager sharedManager].currentEditor;
  if(editor == nullptr) { return; }
  
  ReactNativeRichTextEditorView *typedEditor = (ReactNativeRichTextEditorView *)editor;
  if(typedEditor == nullptr) { return; }
  
  BlockQuoteStyle *bqStyle = typedEditor->stylesDict[@([BlockQuoteStyle getStyleType])];
  if(bqStyle == nullptr) { return; }
  
  NSRange editorRange = NSMakeRange(0, typedEditor->textView.textStorage.length);
  
  // it isn't the most performant but we have to check for all the blockquotes each time and redraw them
  NSArray *allBlockquotes = [bqStyle findAllOccurences:editorRange];
  
  for(StylePair *pair in allBlockquotes) {
    NSRange paragraphRange = [typedEditor->textView.textStorage.string paragraphRangeForRange:[pair.rangeValue rangeValue]];
    NSRange paragraphGlyphRange = [self glyphRangeForCharacterRange:paragraphRange actualCharacterRange:nullptr];
    [self enumerateLineFragmentsForGlyphRange:paragraphGlyphRange
      usingBlock:^(CGRect rect, CGRect usedRect, NSTextContainer * _Nonnull textContainer, NSRange glyphRange, BOOL * _Nonnull stop) {
        CGFloat paddingLeft = origin.x;
        CGFloat paddingTop = origin.y;
        CGFloat x = paddingLeft;
        CGFloat y = paddingTop + rect.origin.y;
        CGFloat width = [typedEditor->config blockquoteWidth];
        CGFloat height = rect.size.height;
        
        CGRect lineRect = CGRectMake(x, y, width, height);
        [[typedEditor->config blockquoteColor] setFill];
        UIRectFill(lineRect);
      }
    ];
  }
    
  UnorderedListStyle *ulStyle = typedEditor->stylesDict[@([UnorderedListStyle getStyleType])];
  OrderedListStyle *olStyle = typedEditor->stylesDict[@([OrderedListStyle getStyleType])];
  if(ulStyle == nullptr || olStyle == nullptr) { return; }
  
  // also not the most performant but we redraw all the lists
  NSMutableArray *allLists = [[NSMutableArray alloc] init];
  [allLists addObjectsFromArray:[ulStyle findAllOccurences:editorRange]];
  [allLists addObjectsFromArray:[olStyle findAllOccurences:editorRange]];
  
  for(StylePair *pair in allLists) {
    NSParagraphStyle *pStyle = (NSParagraphStyle *)pair.styleValue;
    NSDictionary *markerAttributes = @{
      NSFontAttributeName: [typedEditor->config primaryFont],
      NSForegroundColorAttributeName: [typedEditor->config primaryColor]
    };
    
    NSArray *paragraphs = [ParagraphsUtils getSeparateParagraphsRangesIn:typedEditor->textView range:[pair.rangeValue rangeValue]];
    
    for(NSValue *paragraph in paragraphs) {
      NSRange paragraphGlyphRange = [self glyphRangeForCharacterRange:[paragraph rangeValue] actualCharacterRange:nullptr];
      
      [self enumerateLineFragmentsForGlyphRange:paragraphGlyphRange
        usingBlock:^(CGRect rect, CGRect usedRect, NSTextContainer *container, NSRange lineGlyphRange, BOOL *stop) {
          NSString *marker = [self markerForList:pStyle.textLists.firstObject charIndex:[self characterIndexForGlyphAtIndex:lineGlyphRange.location] editor:typedEditor];
          
          if(pStyle.textLists.firstObject.markerFormat == NSTextListMarkerDecimal) {
            CGFloat gapWidth = [typedEditor->config orderedListGapWidth];
            CGFloat markerWidth = [marker sizeWithAttributes:markerAttributes].width;
            CGFloat rightEdge = usedRect.origin.x - gapWidth;
            CGFloat numberX = rightEdge - markerWidth;
            
            [marker drawAtPoint:CGPointMake(numberX, usedRect.origin.y + origin.y) withAttributes:markerAttributes];
          } else {
            CGFloat gapWidth = [typedEditor->config unorderedListGapWidth];
            CGFloat bulletSize = [typedEditor->config unorderedListBulletSize];
            CGFloat bulletX = usedRect.origin.x - gapWidth - bulletSize;
            CGFloat centerY = CGRectGetMidY(usedRect);
            
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSaveGState(context); {
              [[typedEditor->config unorderedListBulletColor] setFill];
              CGContextAddArc(context, bulletX, centerY, bulletSize/2, 0, 2 * M_PI, YES);
              CGContextFillPath(context);
            }
            CGContextRestoreGState(context);
          }
          // only first line of a list gets its marker drawn
          *stop = YES;
        }
      ];
    }
  }
}

- (NSString *)markerForList:(NSTextList *)list charIndex:(NSUInteger)index editor:(ReactNativeRichTextEditorView *)editor {
  if(list.markerFormat == NSTextListMarkerDecimal) {
    NSString *fullText = editor->textView.textStorage.string;
    NSInteger itemNumber = 1;
    
    NSRange currentParagraph = [fullText paragraphRangeForRange:NSMakeRange(index, 0)];
    if(currentParagraph.location > 0) {
      OrderedListStyle *olStyle = editor->stylesDict[@([OrderedListStyle getStyleType])];
      
      NSInteger prevParagraphsCount = 0;
      NSInteger recentParagraphLocation = [fullText paragraphRangeForRange:NSMakeRange(currentParagraph.location - 1, 0)].location;
      
      // seek for previous lists
      while(true) {
        if([olStyle detectStyle:NSMakeRange(recentParagraphLocation, 0)]) {
          prevParagraphsCount += 1;
          
          if(recentParagraphLocation > 0) {
            recentParagraphLocation = [fullText paragraphRangeForRange:NSMakeRange(recentParagraphLocation - 1, 0)].location;
          } else {
            break;
          }
        } else {
          break;
        }
      }
      
      itemNumber = prevParagraphsCount + 1;
    }
    
    return [NSString stringWithFormat:@"%ld.", (long)(itemNumber)];
  } else {
    return @"•";
  }
}

@end
