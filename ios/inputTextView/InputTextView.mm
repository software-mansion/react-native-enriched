#import "InputTextView.h"
#import "EnrichedTextInputView.h"
#import "StringExtension.h"
#import "TextInsertionUtils.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@implementation InputTextView

- (void)copy:(id)sender {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)_input;
  if (typedInput == nullptr) {
    return;
  }

  // remove zero width spaces before copying the text
  NSString *plainText = [typedInput->textView.textStorage.string
      substringWithRange:typedInput->textView.selectedRange];
  NSString *fixedPlainText =
      [plainText stringByReplacingOccurrencesOfString:@"\u200B" withString:@""];

  NSString *parsedHtml = [typedInput->parser
      parseToHtmlFromRange:typedInput->textView.selectedRange];

  NSMutableAttributedString *attrStr = [[typedInput->textView.textStorage
      attributedSubstringFromRange:typedInput->textView.selectedRange]
      mutableCopy];
  NSRange fullAttrStrRange = NSMakeRange(0, attrStr.length);
  [attrStr.mutableString replaceOccurrencesOfString:@"\u200B"
                                         withString:@""
                                            options:0
                                              range:fullAttrStrRange];

  NSData *rtfData =
      [attrStr dataFromRange:NSMakeRange(0, attrStr.length)
          documentAttributes:@{
            NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType
          }
                       error:nullptr];

  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
  [pasteboard setItems:@[ @{
                UTTypeUTF8PlainText.identifier : fixedPlainText,
                UTTypeHTML.identifier : parsedHtml,
                UTTypeRTF.identifier : rtfData
              } ]];
}

- (void)paste:(id)sender {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)_input;
  if (typedInput == nullptr) {
    return;
  }

  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
  NSArray<NSString *> *pasteboardTypes = pasteboard.pasteboardTypes;
  NSRange currentRange = typedInput->textView.selectedRange;

  NSMutableArray<NSDictionary *> *foundImages = [NSMutableArray new];

  for (NSDictionary<NSString *, id> *item in pasteboard.items) {
    NSData *imageData = nil;
    BOOL added = NO;
    NSString *ext = nil;
    NSString *mimeType = nil;

    for (int j = 0; j < item.allKeys.count; j++) {
      if (added) {
        break;
      }

      NSString *type = item.allKeys[j];
      if ([type isEqual:UTTypeJPEG.identifier] ||
          [type isEqual:UTTypePNG.identifier] ||
          [type isEqual:UTTypeWebP.identifier] ||
          [type isEqual:UTTypeHEIC.identifier] ||
          [type isEqual:UTTypeTIFF.identifier]) {
        imageData = [self getDataForImageItem:item[type] type:type];
      } else if ([type isEqual:UTTypeGIF.identifier]) {
        // gifs
        imageData = [pasteboard dataForPasteboardType:type];
      }
      if (!imageData) {
        continue;
      }

      NSDictionary *info = [self detectImageFormat:type];
      if (!info) {
        continue;
      }
      ext = info[@"ext"];
      mimeType = info[@"mime"];

      UIImage *imageInfo = [UIImage imageWithData:imageData];

      if (imageInfo) {
        NSString *path = [self saveToTempFile:imageData extension:ext];

        if (path) {
          added = YES;
          [foundImages addObject:@{
            @"uri" : path,
            @"type" : mimeType,
            @"width" : @(imageInfo.size.width),
            @"height" : @(imageInfo.size.height)
          }];
        }
      }
    }
  }

  if (foundImages.count > 0) {
    [typedInput emitOnPasteImagesEvent:foundImages];
    return;
  }

  if ([pasteboardTypes containsObject:UTTypeHTML.identifier]) {
    // we try processing the html contents

    NSString *htmlString;
    id htmlValue = [pasteboard valueForPasteboardType:UTTypeHTML.identifier];

    if ([htmlValue isKindOfClass:[NSData class]]) {
      htmlString = [[NSString alloc] initWithData:htmlValue
                                         encoding:NSUTF8StringEncoding];
    } else if ([htmlValue isKindOfClass:[NSString class]]) {
      htmlString = htmlValue;
    }

    // validate the html
    NSString *initiallyProcessedHtml =
        [typedInput->parser initiallyProcessHtml:htmlString];

    if (initiallyProcessedHtml != nullptr) {
      // valid html, let's apply it
      currentRange.length > 0
          ? [typedInput->parser replaceFromHtml:initiallyProcessedHtml
                                          range:currentRange]
          : [typedInput->parser insertFromHtml:initiallyProcessedHtml
                                      location:currentRange.location];
    } else {
      // fall back to plain text, otherwise do nothing
      [self tryHandlingPlainTextItemsIn:pasteboard
                                  range:currentRange
                                  input:typedInput];
    }
  } else {
    [self tryHandlingPlainTextItemsIn:pasteboard
                                range:currentRange
                                input:typedInput];
  }

  [typedInput anyTextMayHaveBeenModified];
}

- (NSDictionary *)detectImageFormat:(NSString *)type {
  if ([type isEqual:UTTypeJPEG.identifier]) {
    return @{@"ext" : @"jpg", @"mime" : @"image/jpeg"};
  } else if ([type isEqual:UTTypePNG.identifier]) {
    return @{@"ext" : @"png", @"mime" : @"image/png"};
  } else if ([type isEqual:UTTypeGIF.identifier]) {
    return @{@"ext" : @"gif", @"mime" : @"image/gif"};
  } else if ([type isEqual:UTTypeHEIC.identifier]) {
    return @{@"ext" : @"heic", @"mime" : @"image/heic"};
  } else if ([type isEqual:UTTypeWebP.identifier]) {
    return @{@"ext" : @"webp", @"mime" : @"image/webp"};
  } else if ([type isEqual:UTTypeTIFF.identifier]) {
    return @{@"ext" : @"tiff", @"mime" : @"image/tiff"};
  } else {
    return nil;
  }
}

- (NSData *)getDataForImageItem:(NSData *)imageData type:(NSString *)type {
  UIImage *image = (UIImage *)imageData;

  if ([type isEqual:UTTypePNG.identifier]) {
    return UIImagePNGRepresentation(image);
  } else if ([type isEqual:UTTypeHEIC.identifier]) {
    return UIImageHEICRepresentation(image);
  } else {
    return UIImageJPEGRepresentation(image, 1.0);
  }
}

- (NSString *)saveToTempFile:(NSData *)data extension:(NSString *)ext {
  if (!data)
    return nil;
  NSString *fileName =
      [NSString stringWithFormat:@"%@.%@", [NSUUID UUID].UUIDString, ext];

  NSString *filePath =
      [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];

  if ([data writeToFile:filePath atomically:YES]) {
    return [NSURL fileURLWithPath:filePath].absoluteString;
  }

  return nil;
}

// Helper to detect if an image needs PNG
- (BOOL)imageHasAlpha:(UIImage *)image {
  CGImageAlphaInfo alpha = CGImageGetAlphaInfo(image.CGImage);
  return (alpha == kCGImageAlphaFirst || alpha == kCGImageAlphaLast ||
          alpha == kCGImageAlphaPremultipliedFirst ||
          alpha == kCGImageAlphaPremultipliedLast);
}

- (void)tryHandlingPlainTextItemsIn:(UIPasteboard *)pasteboard
                              range:(NSRange)range
                              input:(EnrichedTextInputView *)input {
  NSArray *existingTypes = pasteboard.pasteboardTypes;
  NSArray *handledTypes = @[
    UTTypeUTF8PlainText.identifier, UTTypePlainText.identifier,
    UTTypeURL.identifier
  ];
  NSString *plainText;

  for (NSString *type in handledTypes) {
    if (![existingTypes containsObject:type]) {
      continue;
    }

    id value = [pasteboard valueForPasteboardType:type];

    if ([value isKindOfClass:[NSData class]]) {
      plainText = [[NSString alloc] initWithData:value
                                        encoding:NSUTF8StringEncoding];
    } else if ([value isKindOfClass:[NSString class]]) {
      plainText = (NSString *)value;
    } else if ([value isKindOfClass:[NSURL class]]) {
      plainText = [(NSURL *)value absoluteString];
    }
  }

  if (!plainText) {
    return;
  }

  range.length > 0 ? [TextInsertionUtils replaceText:plainText
                                                  at:range
                                additionalAttributes:nullptr
                                               input:input
                                       withSelection:YES]
                   : [TextInsertionUtils insertText:plainText
                                                 at:range.location
                               additionalAttributes:nullptr
                                              input:input
                                      withSelection:YES];
}

- (void)cut:(id)sender {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)_input;
  if (typedInput == nullptr) {
    return;
  }

  [self copy:sender];
  [TextInsertionUtils replaceText:@""
                               at:typedInput->textView.selectedRange
             additionalAttributes:nullptr
                            input:typedInput
                    withSelection:YES];

  [typedInput anyTextMayHaveBeenModified];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
  if (action == @selector(paste:)) {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    // Enable Paste if clipboard has Text OR Images
    if (pasteboard.hasStrings || pasteboard.hasImages) {
      return YES;
    }
  }
  return [super canPerformAction:action withSender:sender];
}

@end
