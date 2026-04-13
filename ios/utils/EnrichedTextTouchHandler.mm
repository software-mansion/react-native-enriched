#import "EnrichedTextTouchHandler.h"
#import "EnrichedTextView.h"
#import "LinkData.h"
#import "MentionParams.h"
#import "MentionStyleProps.h"
#import "StyleBase.h"

@implementation EnrichedTextTouchHandler {
  NSRange _activeRange;
  NSString *_activeAttrKey;
  id _activeValue;
}

- (instancetype)initWithView:(EnrichedTextView *)view {
  if (self = [super init]) {
    _view = view;
  }
  return self;
}

- (void)handleTouchBeganAtPoint:(CGPoint)point {
  NSUInteger charIndex = [self characterIndexAtPoint:point];
  NSRange range;
  NSString *key;
  id value = [self findClickableAt:charIndex range:&range key:&key];
  if (value) {
    _activeRange = range;
    _activeAttrKey = key;
    _activeValue = value;
    [self updateVisualsPressed:YES];
  }
}

- (void)handleTouchEndedAtPoint:(CGPoint)point {
  if (!_activeValue) {
    return;
  }

  NSUInteger charIndex = [self characterIndexAtPoint:point];
  if (NSLocationInRange(charIndex, _activeRange)) {
    [self dispatchEvent];
  }

  [self updateVisualsPressed:NO];
  [self reset];
}

- (void)handleTouchCancelled {
  [self updateVisualsPressed:NO];
  [self reset];
}

- (NSUInteger)characterIndexAtPoint:(CGPoint)point {
  UITextView *tv = self.view.textView;
  NSLayoutManager *lm = tv.layoutManager;
  NSTextContainer *tc = tv.textContainer;

  CGPoint textOffset =
      CGPointMake(tv.textContainerInset.left, tv.textContainerInset.top);
  CGPoint locationInContainer =
      CGPointMake(point.x - textOffset.x, point.y - textOffset.y);

  NSUInteger glyphIndex = [lm glyphIndexForPoint:locationInContainer
                                 inTextContainer:tc];
  CGRect glyphRect = [lm boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)
                                   inTextContainer:tc];

  if (!CGRectContainsPoint(glyphRect, locationInContainer)) {
    return NSNotFound;
  }
  return [lm characterIndexForGlyphAtIndex:glyphIndex];
}

- (id)findClickableAt:(NSUInteger)idx
                range:(NSRangePointer)range
                  key:(NSString **)key {
  if (idx == NSNotFound || idx >= self.view.textView.textStorage.length)
    return nil;

  NSArray *keys =
      @[ @"EnrichedManualLink", @"EnrichedAutomaticLink", @"EnrichedMention" ];
  for (NSString *k in keys) {
    id val = [self.view.textView.textStorage attribute:k
                                               atIndex:idx
                                        effectiveRange:range];
    if (val) {
      *key = k;
      return val;
    }
  }
  return nil;
}

- (void)updateVisualsPressed:(BOOL)pressed {
  if (pressed) {
    UIColor *color = nil;
    UIColor *bgColor = nil;

    if ([_activeAttrKey isEqualToString:@"EnrichedMention"]) {
      MentionParams *m = (MentionParams *)_activeValue;
      MentionStyleProps *mProps =
          [self.view.config mentionStylePropsForIndicator:m.indicator];
      color = [mProps pressColor];
      bgColor = [mProps pressBackgroundColor];
    } else {
      color = [self.view.config linkPressColor];
    }

    NSMutableDictionary *newAttrs = [[NSMutableDictionary alloc] init];
    if (color) {
      newAttrs[NSForegroundColorAttributeName] = color;
      newAttrs[NSUnderlineColorAttributeName] = color;
      newAttrs[NSStrikethroughColorAttributeName] = color;
    }
    if (bgColor) {
      newAttrs[NSBackgroundColorAttributeName] = bgColor;
    }

    [self.view.textView.textStorage addAttributes:newAttrs range:_activeRange];
  } else {
    // REVERT using the Style Engine in the View
    for (StyleBase *style in self.view.stylesDict.allValues) {
      NSString *styleKey = [style getKey];
      // If the style key matches exactly (Mentions)
      // OR if both the style and the active key are Link-related
      BOOL isMatch = [styleKey isEqualToString:_activeAttrKey];
      BOOL isLinkMatch = ([_activeAttrKey containsString:@"Link"] &&
                          [styleKey containsString:@"Link"]);

      if (isMatch || isLinkMatch) {
        [style applyStyling:_activeRange];
      }
    }
  }
}

- (void)dispatchEvent {
  if ([_activeAttrKey containsString:@"Link"]) {
    [self.view emitOnLinkPressEvent:((LinkData *)_activeValue).url];
  } else if ([_activeAttrKey isEqualToString:@"EnrichedMention"]) {
    [self.view emitOnMentionPressEvent:(MentionParams *)_activeValue];
  }
}

- (void)reset {
  _activeValue = nil;
  _activeAttrKey = nil;
  _activeRange = NSMakeRange(0, 0);
}
@end
