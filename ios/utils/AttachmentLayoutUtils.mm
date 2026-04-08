#import "AttachmentLayoutUtils.h"

@implementation AttachmentLayoutUtils

+ (void)handleAttachmentUpdate:(MediaAttachment *)attachment
                      textView:(UITextView *)textView
                 onLayoutBlock:(dispatch_block_t)layoutBlock {
  NSTextStorage *storage = textView.textStorage;
  NSRange fullRange = NSMakeRange(0, storage.length);

  __block NSRange foundRange = NSMakeRange(NSNotFound, 0);

  [storage enumerateAttribute:NSAttachmentAttributeName
                      inRange:fullRange
                      options:0
                   usingBlock:^(id value, NSRange range, BOOL *stop) {
                     if (value == attachment) {
                       foundRange = range;
                       *stop = YES;
                     }
                   }];

  if (foundRange.location == NSNotFound) {
    return;
  }

  [storage edited:NSTextStorageEditedAttributes
               range:foundRange
      changeInLength:0];

  dispatch_async(dispatch_get_main_queue(), layoutBlock);
}

+ (NSMutableDictionary<NSValue *, UIImageView *> *)
    layoutAttachmentsInTextView:(UITextView *)textView
                         config:(InputConfig *)config
                  existingViews:
                      (NSMutableDictionary<NSValue *, UIImageView *> *)
                          attachmentViews {
  NSTextStorage *storage = textView.textStorage;
  if (storage.length == 0)
    return attachmentViews;

  NSMutableDictionary<NSValue *, UIImageView *> *activeAttachmentViews =
      [NSMutableDictionary dictionary];

  // Iterate over the entire text to find ImageAttachments
  [storage enumerateAttribute:NSAttachmentAttributeName
                      inRange:NSMakeRange(0, storage.length)
                      options:0
                   usingBlock:^(id value, NSRange range, BOOL *stop) {
                     if ([value isKindOfClass:[ImageAttachment class]]) {
                       ImageAttachment *attachment = (ImageAttachment *)value;

                       CGRect rect = [self frameForAttachment:attachment
                                                      atRange:range
                                                     textView:textView
                                                       config:config];

                       // Get or Create the UIImageView for this specific
                       // attachment key
                       NSValue *key =
                           [NSValue valueWithNonretainedObject:attachment];
                       UIImageView *imgView = attachmentViews[key];

                       if (!imgView) {
                         // It doesn't exist yet, create it
                         imgView = [[UIImageView alloc] initWithFrame:rect];
                         imgView.contentMode = UIViewContentModeScaleAspectFit;
                         imgView.tintColor = [UIColor labelColor];

                         // Add it directly to the TextView
                         [textView addSubview:imgView];
                       }

                       // Update position (in case text moved/scrolled)
                       if (!CGRectEqualToRect(imgView.frame, rect)) {
                         imgView.frame = rect;
                       }
                       UIImage *targetImage =
                           attachment.storedAnimatedImage ?: attachment.image;

                       // Only set if different to avoid resetting the animation
                       // loop
                       if (imgView.image != targetImage) {
                         imgView.image = targetImage;
                       }

                       // Ensure it is visible on top
                       imgView.hidden = NO;
                       [textView bringSubviewToFront:imgView];

                       activeAttachmentViews[key] = imgView;
                       // Remove from the old map so we know it has been claimed
                       [attachmentViews removeObjectForKey:key];
                     }
                   }];

  // Everything remaining in attachmentViews is dead or off-screen
  for (UIImageView *danglingView in attachmentViews.allValues) {
    [danglingView removeFromSuperview];
  }

  return activeAttachmentViews;
}

+ (CGRect)frameForAttachment:(ImageAttachment *)attachment
                     atRange:(NSRange)range
                    textView:(UITextView *)textView
                      config:(InputConfig *)config {
  NSLayoutManager *layoutManager = textView.layoutManager;
  NSTextContainer *textContainer = textView.textContainer;
  NSTextStorage *storage = textView.textStorage;

  NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:range
                                             actualCharacterRange:NULL];
  CGRect glyphRect = [layoutManager boundingRectForGlyphRange:glyphRange
                                              inTextContainer:textContainer];

  CGRect lineRect =
      [layoutManager lineFragmentRectForGlyphAtIndex:glyphRange.location
                                      effectiveRange:NULL];
  CGSize attachmentSize = attachment.bounds.size;

  UIFont *font = [storage attribute:NSFontAttributeName
                            atIndex:range.location
                     effectiveRange:NULL];
  if (!font) {
    font = [config primaryFont];
  }

  // Calculate (Baseline Alignment)
  CGFloat targetY =
      CGRectGetMaxY(lineRect) + font.descender - attachmentSize.height;
  CGRect rect =
      CGRectMake(glyphRect.origin.x + textView.textContainerInset.left,
                 targetY + textView.textContainerInset.top,
                 attachmentSize.width, attachmentSize.height);

  return CGRectIntegral(rect);
}

@end
