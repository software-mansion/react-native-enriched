#import "HtmlParser.h"
#import "ImageData.h"
#import "LinkData.h"
#import "MentionParams.h"
#import "StringExtension.h"
#import "StyleHeaders.h"
#import "StylePair.h"

#include "GumboParser.hpp"

@implementation HtmlParser

+ (BOOL)isBlockTag:(NSString *)tagName {
  return [tagName isEqualToString:@"ul"] || [tagName isEqualToString:@"ol"] ||
         [tagName isEqualToString:@"blockquote"] ||
         [tagName isEqualToString:@"codeblock"];
}

/**
 * Prepares HTML for the parser by stripping extraneous whitespace and newlines
 * from structural tags, while preserving them within text content.
 *
 * APPROACH:
 * This function treats the HTML as having two distinct states:
 * 1. Structure Mode (Depth == 0): We are inside or between container tags (like
 * blockquote, ul, codeblock). In this mode whitespace and newlines are
 * considered layout artifacts and are REMOVED to prevent the parser from
 * creating unwanted spaces.
 * 2. Content Mode (Depth > 0): We are inside a text-containing tag (like p,
 * b, li). In this mode, all whitespace is PRESERVED exactly as is, ensuring
 * that sentences and inline formatting remain readable.
 *
 * The function iterates character-by-character, using a depth counter to track
 * nesting levels of the specific tags defined in `textTags`.
 *
 * IMPORTANT:
 * The `textTags` set acts as a whitelist for "Content Mode". If you add support
 * for a new HTML tag that contains visible text (e.g., h4, h5, h6),
 * you MUST add it to the `textTags` set below.
 */
+ (NSString *)stripExtraWhiteSpacesAndNewlines:(NSString *)html {
  NSSet *textTags = [NSSet setWithObjects:@"p", @"h1", @"h2", @"h3", @"h4",
                                          @"h5", @"h6", @"li", @"b", @"a", @"s",
                                          @"mention", @"code", @"u", @"i", nil];

  NSMutableString *output = [NSMutableString stringWithCapacity:html.length];
  NSMutableString *currentTagBuffer = [NSMutableString string];
  NSCharacterSet *whitespaceAndNewlineSet =
      [NSCharacterSet whitespaceAndNewlineCharacterSet];

  BOOL isReadingTag = NO;
  NSInteger textDepth = 0;

  for (NSUInteger i = 0; i < html.length; i++) {
    unichar c = [html characterAtIndex:i];

    if (c == '<') {
      isReadingTag = YES;
      [currentTagBuffer setString:@""];
      [output appendString:@"<"];
    } else if (c == '>') {
      isReadingTag = NO;
      [output appendString:@">"];

      NSString *fullTag = [currentTagBuffer lowercaseString];

      NSString *cleanName = [fullTag
          stringByTrimmingCharactersInSet:
              [NSCharacterSet characterSetWithCharactersInString:@"/"]];
      NSArray *parts =
          [cleanName componentsSeparatedByCharactersInSet:
                         [NSCharacterSet whitespaceAndNewlineCharacterSet]];
      NSString *tagName = parts.firstObject;

      if (![textTags containsObject:tagName]) {
        continue;
      }

      if ([fullTag hasPrefix:@"/"]) {
        textDepth--;
        if (textDepth < 0)
          textDepth = 0;
      } else {
        // Opening tag (e.g. <h1>) -> Enter Text Mode
        // (Ignore self-closing tags like <img/> if they happen to be in the
        // list)
        if (![fullTag hasSuffix:@"/"]) {
          textDepth++;
        }
      }
    } else {
      if (isReadingTag) {
        [currentTagBuffer appendFormat:@"%C", c];
        [output appendFormat:@"%C", c];
        continue;
      }

      if (textDepth > 0) {
        [output appendFormat:@"%C", c];
      } else {
        if (![whitespaceAndNewlineSet characterIsMember:c]) {
          [output appendFormat:@"%C", c];
        }
      }
    }
  }

  return output;
}

+ (NSString *)stringByAddingNewlinesToTag:(NSString *)tag
                                 inString:(NSString *)html
                                  leading:(BOOL)leading
                                 trailing:(BOOL)trailing {
  NSString *str = [html copy];
  if (leading) {
    NSString *formattedTag = [NSString stringWithFormat:@">%@", tag];
    NSString *formattedNewTag = [NSString stringWithFormat:@">\n%@", tag];
    str = [str stringByReplacingOccurrencesOfString:formattedTag
                                         withString:formattedNewTag];
  }
  if (trailing) {
    NSString *formattedTag = [NSString stringWithFormat:@"%@<", tag];
    NSString *formattedNewTag = [NSString stringWithFormat:@"%@\n<", tag];
    str = [str stringByReplacingOccurrencesOfString:formattedTag
                                         withString:formattedNewTag];
  }
  return str;
}

#pragma mark - External HTML normalization

/**
 * Normalizes external HTML (from Google Docs, Word, web pages, etc.) into our
 * canonical tag subset using the Gumbo-based C++ normalizer.
 *
 * Converts: strong → b, em → i, span style="font-weight:bold" → b,
 * strips unknown tags while preserving text
 */
+ (NSString *_Nullable)normalizeExternalHtml:(NSString *_Nonnull)html {
  std::string result =
      GumboParser::normalizeHtml(std::string([html UTF8String]));
  if (result.empty())
    return nil;
  return [NSString stringWithUTF8String:result.c_str()];
}

+ (void)finalizeTagEntry:(NSMutableString *)tagName
               ongoingTags:(NSMutableDictionary *)ongoingTags
    initiallyProcessedTags:(NSMutableArray *)processedTags
                 plainText:(NSMutableString *)plainText
       precedingImageCount:(NSInteger *)precedingImageCount {
  NSMutableArray *tagEntry = [[NSMutableArray alloc] init];

  NSArray *tagData = ongoingTags[tagName];
  NSInteger tagLocation = [((NSNumber *)tagData[0]) intValue];

  // 'tagLocation' is an index based on 'plainText' which currently only holds
  // raw text.
  //
  // Since 'plainText' does not yet contain the special placeholders for images,
  // the indices for any text following an image are lower than they will be
  // in the final NSTextStorage.
  //
  // We add 'precedingImageCount' to shift the start index forward, aligning
  // this style's range with the actual position in the final text (where each
  // image adds 1 character).
  NSRange tagRange = NSMakeRange(tagLocation + *precedingImageCount,
                                 plainText.length - tagLocation);

  [tagEntry addObject:[tagName copy]];
  [tagEntry addObject:[NSValue valueWithRange:tagRange]];
  if (tagData.count > 1) {
    [tagEntry addObject:[(NSString *)tagData[1] copy]];
  }

  [processedTags addObject:tagEntry];
  [ongoingTags removeObjectForKey:tagName];

  if ([tagName isEqualToString:@"img"]) {
    (*precedingImageCount)++;
  }
}

+ (BOOL)isUlCheckboxList:(NSString *)params {
  return ([params containsString:@"data-type=\"checkbox\""] ||
          [params containsString:@"data-type='checkbox'"]);
}

+ (NSDictionary *)prepareCheckboxListStyleValue:(NSValue *)rangeValue
                                 checkboxStates:(NSDictionary *)checkboxStates {
  NSRange range = [rangeValue rangeValue];
  NSMutableDictionary *statesInRange = [[NSMutableDictionary alloc] init];

  for (NSNumber *key in checkboxStates) {
    NSUInteger pos = [key unsignedIntegerValue];
    if (pos >= range.location && pos < range.location + range.length) {
      [statesInRange setObject:checkboxStates[key] forKey:key];
    }
  }

  return statesInRange;
}

+ (NSString *_Nullable)initiallyProcessHtml:(NSString *_Nonnull)html
                          useHtmlNormalizer:(BOOL)useHtmlNormalizer {
  NSString *htmlWithoutSpaces = [self stripExtraWhiteSpacesAndNewlines:html];
  NSString *fixedHtml = nullptr;

  if (htmlWithoutSpaces.length >= 13) {
    NSString *firstSix =
        [htmlWithoutSpaces substringWithRange:NSMakeRange(0, 6)];
    NSString *lastSeven = [htmlWithoutSpaces
        substringWithRange:NSMakeRange(htmlWithoutSpaces.length - 7, 7)];

    if ([firstSix isEqualToString:@"<html>"] &&
        [lastSeven isEqualToString:@"</html>"]) {
      // remove html tags, might be with newlines or without them
      fixedHtml = [htmlWithoutSpaces copy];
      // firstly remove newlined html tags if any:
      fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"<html>\n"
                                                       withString:@""];
      fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"\n</html>"
                                                       withString:@""];
      // fallback; remove html tags without their newlines
      fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"<html>"
                                                       withString:@""];
      fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"</html>"
                                                       withString:@""];
    } else if (useHtmlNormalizer) {
      // External HTML (from Google Docs, Word, web pages, etc.)
      // Run through the Gumbo-based normalizer to convert arbitrary HTML
      // into our canonical tag subset.
      NSString *normalized = [self normalizeExternalHtml:html];
      if (normalized != nil) {
        fixedHtml = normalized;
      }
    }

    // Additionally, try getting the content from between body tags if there are
    // some:

    // Firstly make sure there are no newlines between them.
    fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"<body>\n"
                                                     withString:@"<body>"];
    fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"\n</body>"
                                                     withString:@"</body>"];
    // Then, if there actually are body tags, use the content between them.
    NSRange openingBodyRange = [htmlWithoutSpaces rangeOfString:@"<body>"];
    NSRange closingBodyRange = [htmlWithoutSpaces rangeOfString:@"</body>"];
    if (openingBodyRange.length != 0 && closingBodyRange.length != 0) {
      NSInteger newStart = openingBodyRange.location + 6;
      NSInteger newEnd = closingBodyRange.location - 1;
      fixedHtml = [htmlWithoutSpaces
          substringWithRange:NSMakeRange(newStart, newEnd - newStart + 1)];
    }
  }

  // second processing - try fixing htmls with wrong newlines' setup
  if (fixedHtml != nullptr) {
    // add <br> tag wherever needed
    fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"<p></p>"
                                                     withString:@"<br>"];

    // remove <p> tags inside of <li>
    fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"<li><p>"
                                                     withString:@"<li>"];
    fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"</p></li>"
                                                     withString:@"</li>"];

    // change <br/> to <br>
    fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"<br/>"
                                                     withString:@"<br>"];

    // remove <p> tags around <br>
    fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"<p><br>"
                                                     withString:@"<br>"];
    fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"<br></p>"
                                                     withString:@"<br>"];

    // add <br> tags inside empty blockquote and codeblock tags
    fixedHtml = [fixedHtml
        stringByReplacingOccurrencesOfString:@"<blockquote></blockquote>"
                                  withString:@"<blockquote><br></"
                                             @"blockquote>"];
    fixedHtml = [fixedHtml
        stringByReplacingOccurrencesOfString:@"<codeblock></codeblock>"
                                  withString:@"<codeblock><br></codeblock>"];

    // remove empty ul and ol tags
    fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"<ul></ul>"
                                                     withString:@""];
    fixedHtml = [fixedHtml
        stringByReplacingOccurrencesOfString:@"<ul data-type=\"checkbox\"></ul>"
                                  withString:@""];
    fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"<ol></ol>"
                                                     withString:@""];

    // tags that have to be in separate lines
    fixedHtml = [self stringByAddingNewlinesToTag:@"<br>"
                                         inString:fixedHtml
                                          leading:YES
                                         trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<ul>"
                                         inString:fixedHtml
                                          leading:YES
                                         trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"</ul>"
                                         inString:fixedHtml
                                          leading:YES
                                         trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<ol>"
                                         inString:fixedHtml
                                          leading:YES
                                         trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"</ol>"
                                         inString:fixedHtml
                                          leading:YES
                                         trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<blockquote>"
                                         inString:fixedHtml
                                          leading:YES
                                         trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"</blockquote>"
                                         inString:fixedHtml
                                          leading:YES
                                         trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<codeblock>"
                                         inString:fixedHtml
                                          leading:YES
                                         trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"</codeblock>"
                                         inString:fixedHtml
                                          leading:YES
                                         trailing:YES];

    // line opening tags
    fixedHtml = [self stringByAddingNewlinesToTag:@"<p>"
                                         inString:fixedHtml
                                          leading:YES
                                         trailing:NO];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<li>"
                                         inString:fixedHtml
                                          leading:YES
                                         trailing:NO];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<li checked>"
                                         inString:fixedHtml
                                          leading:YES
                                         trailing:NO];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<h1>"
                                         inString:fixedHtml
                                          leading:YES
                                         trailing:NO];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<h2>"
                                         inString:fixedHtml
                                          leading:YES
                                         trailing:NO];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<h3>"
                                         inString:fixedHtml
                                          leading:YES
                                         trailing:NO];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<h4>"
                                         inString:fixedHtml
                                          leading:YES
                                         trailing:NO];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<h5>"
                                         inString:fixedHtml
                                          leading:YES
                                         trailing:NO];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<h6>"
                                         inString:fixedHtml
                                          leading:YES
                                         trailing:NO];

    // line closing tags
    fixedHtml = [self stringByAddingNewlinesToTag:@"</p>"
                                         inString:fixedHtml
                                          leading:NO
                                         trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"</li>"
                                         inString:fixedHtml
                                          leading:NO
                                         trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"</h1>"
                                         inString:fixedHtml
                                          leading:NO
                                         trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"</h2>"
                                         inString:fixedHtml
                                          leading:NO
                                         trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"</h3>"
                                         inString:fixedHtml
                                          leading:NO
                                         trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"</h4>"
                                         inString:fixedHtml
                                          leading:NO
                                         trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"</h5>"
                                         inString:fixedHtml
                                          leading:NO
                                         trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"</h6>"
                                         inString:fixedHtml
                                          leading:NO
                                         trailing:YES];

    // this is more like a hack but for some reason the last <br> in
    // <blockquote> and <codeblock> are not properly changed into zero width
    // space so we do that manually here
    fixedHtml = [fixedHtml
        stringByReplacingOccurrencesOfString:@"<br>\n</blockquote>"
                                  withString:@"<p>\u200B</p>\n</blockquote>"];
    fixedHtml = [fixedHtml
        stringByReplacingOccurrencesOfString:@"<br>\n</codeblock>"
                                  withString:@"<p>\u200B</p>\n</codeblock>"];

    // replace "<br>" at the end with "<br>\n" if input is not empty to properly
    // handle last <br> in html
    if ([fixedHtml hasSuffix:@"<br>"] && fixedHtml.length != 4) {
      fixedHtml = [fixedHtml stringByAppendingString:@"\n"];
    }
  }

  return fixedHtml;
}

+ (NSArray *_Nonnull)getTextAndStylesFromHtml:(NSString *_Nonnull)fixedHtml {
  NSMutableString *plainText = [[NSMutableString alloc] initWithString:@""];
  NSMutableDictionary *ongoingTags = [[NSMutableDictionary alloc] init];
  NSMutableArray *initiallyProcessedTags = [[NSMutableArray alloc] init];
  NSMutableDictionary *checkboxStates = [[NSMutableDictionary alloc] init];
  BOOL insideCheckboxList = NO;
  NSInteger precedingImageCount = 0;
  BOOL insideTag = NO;
  BOOL gettingTagName = NO;
  BOOL gettingTagParams = NO;
  BOOL closingTag = NO;
  NSMutableString *currentTagName =
      [[NSMutableString alloc] initWithString:@""];
  NSMutableString *currentTagParams =
      [[NSMutableString alloc] initWithString:@""];
  NSDictionary *htmlEntitiesDict =
      [NSString getEscapedCharactersInfoFrom:fixedHtml];

  // firstly, extract text and initially processed tags
  for (int i = 0; i < fixedHtml.length; i++) {
    NSString *currentCharacterStr =
        [fixedHtml substringWithRange:NSMakeRange(i, 1)];
    unichar currentCharacterChar = [fixedHtml characterAtIndex:i];

    if (currentCharacterChar == '<') {
      // opening the tag, mark that we are inside and getting its name
      insideTag = YES;
      gettingTagName = YES;
    } else if (currentCharacterChar == '>') {
      // finishing some tag, no longer marked as inside or getting its
      // name/params
      insideTag = NO;
      gettingTagName = NO;
      gettingTagParams = NO;

      BOOL isSelfClosing = NO;

      // Check if params ended with '/' (e.g. <img src="" />)
      if ([currentTagParams hasSuffix:@"/"]) {
        [currentTagParams
            deleteCharactersInRange:NSMakeRange(currentTagParams.length - 1,
                                                1)];
        isSelfClosing = YES;
      }

      if ([currentTagName isEqualToString:@"p"] ||
          [currentTagName isEqualToString:@"br"]) {
        // do nothing, we don't include these tags in styles
      } else if ([currentTagName isEqualToString:@"li"]) {
        // Only track checkbox state if we're inside a checkbox list
        if (insideCheckboxList && !closingTag) {
          BOOL isChecked = [currentTagParams containsString:@"checked"];
          checkboxStates[@(plainText.length)] = @(isChecked);
        }
      } else if (!closingTag) {
        // we finish opening tag - get its location and optionally params and
        // put them under tag name key in ongoingTags
        NSMutableArray *tagArr = [[NSMutableArray alloc] init];
        [tagArr addObject:[NSNumber numberWithInteger:plainText.length]];
        if (currentTagParams.length > 0) {
          [tagArr addObject:[currentTagParams copy]];
        }
        ongoingTags[currentTagName] = tagArr;

        // Check if this is a checkbox list
        if ([currentTagName isEqualToString:@"ul"] &&
            [self isUlCheckboxList:currentTagParams]) {
          insideCheckboxList = YES;
        }

        // skip one newline if it was added after opening tags that are in
        // separate lines
        if ([self isBlockTag:currentTagName] && i + 1 < fixedHtml.length &&
            [[NSCharacterSet newlineCharacterSet]
                characterIsMember:[fixedHtml characterAtIndex:i + 1]]) {
          i += 1;
        }

        if (isSelfClosing) {
          [self finalizeTagEntry:currentTagName
                         ongoingTags:ongoingTags
              initiallyProcessedTags:initiallyProcessedTags
                           plainText:plainText
                 precedingImageCount:&precedingImageCount];
        }
      } else {
        // we finish closing tags - pack tag name, tag range and optionally tag
        // params into an entry that goes inside initiallyProcessedTags

        // Check if we're closing a checkbox list by looking at the params
        if ([currentTagName isEqualToString:@"ul"] &&
            [self isUlCheckboxList:currentTagParams]) {
          insideCheckboxList = NO;
        }

        BOOL isBlockTag = [self isBlockTag:currentTagName];

        // skip one newline if it was added before some closing tags that are
        // in separate lines
        if (isBlockTag && plainText.length > 0 &&
            [[NSCharacterSet newlineCharacterSet]
                characterIsMember:[plainText
                                      characterAtIndex:plainText.length - 1]]) {
          plainText = [[plainText
              substringWithRange:NSMakeRange(0, plainText.length - 1)]
              mutableCopy];
        }

        [self finalizeTagEntry:currentTagName
                       ongoingTags:ongoingTags
            initiallyProcessedTags:initiallyProcessedTags
                         plainText:plainText
               precedingImageCount:&precedingImageCount];
      }
      // post-tag cleanup
      closingTag = NO;
      currentTagName = [[NSMutableString alloc] initWithString:@""];
      currentTagParams = [[NSMutableString alloc] initWithString:@""];
    } else {
      if (!insideTag) {
        // no tags logic - just append the right text

        // html entity on the index; use unescaped character and forward
        // iterator accordingly
        NSArray *entityInfo = htmlEntitiesDict[@(i)];
        if (entityInfo != nullptr) {
          NSString *escaped = entityInfo[0];
          NSString *unescaped = entityInfo[1];
          [plainText appendString:unescaped];
          // the iterator will forward by 1 itself
          i += escaped.length - 1;
        } else {
          [plainText appendString:currentCharacterStr];
        }
      } else {
        if (gettingTagName) {
          if (currentCharacterChar == ' ') {
            // no longer getting tag name - switch to params
            gettingTagName = NO;
            gettingTagParams = YES;
          } else if (currentCharacterChar == '/') {
            // mark that the tag is closing
            closingTag = YES;
          } else {
            // append next tag char
            [currentTagName appendString:currentCharacterStr];
          }
        } else if (gettingTagParams) {
          // append next tag params char
          [currentTagParams appendString:currentCharacterStr];
        }
      }
    }
  }

  // process tags into proper StyleType + StylePair values
  NSMutableArray *processedStyles = [[NSMutableArray alloc] init];

  for (NSArray *arr in initiallyProcessedTags) {
    NSString *tagName = (NSString *)arr[0];
    NSValue *tagRangeValue = (NSValue *)arr[1];
    NSMutableString *params = [[NSMutableString alloc] initWithString:@""];
    if (arr.count > 2) {
      [params appendString:(NSString *)arr[2]];
    }

    NSMutableArray *styleArr = [[NSMutableArray alloc] init];
    StylePair *stylePair = [[StylePair alloc] init];

    if ([tagName isEqualToString:@"b"]) {
      [styleArr addObject:@([BoldStyle getType])];
    } else if ([tagName isEqualToString:@"i"]) {
      [styleArr addObject:@([ItalicStyle getType])];
    } else if ([tagName isEqualToString:@"img"]) {
      NSRegularExpression *srcRegex =
          [NSRegularExpression regularExpressionWithPattern:@"src=\"([^\"]+)\""
                                                    options:0
                                                      error:nullptr];
      NSTextCheckingResult *match =
          [srcRegex firstMatchInString:params
                               options:0
                                 range:NSMakeRange(0, params.length)];

      if (match == nullptr) {
        continue;
      }

      NSRange srcRange = match.range;
      [styleArr addObject:@([ImageStyle getType])];
      // cut only the uri from the src="..." string
      NSString *uri =
          [params substringWithRange:NSMakeRange(srcRange.location + 5,
                                                 srcRange.length - 6)];
      ImageData *imageData = [[ImageData alloc] init];
      imageData.uri = uri;

      NSRegularExpression *widthRegex = [NSRegularExpression
          regularExpressionWithPattern:@"width=\"([0-9.]+)\""
                               options:0
                                 error:nil];
      NSTextCheckingResult *widthMatch =
          [widthRegex firstMatchInString:params
                                 options:0
                                   range:NSMakeRange(0, params.length)];

      if (widthMatch) {
        NSString *widthString =
            [params substringWithRange:[widthMatch rangeAtIndex:1]];
        imageData.width = [widthString floatValue];
      }

      NSRegularExpression *heightRegex = [NSRegularExpression
          regularExpressionWithPattern:@"height=\"([0-9.]+)\""
                               options:0
                                 error:nil];
      NSTextCheckingResult *heightMatch =
          [heightRegex firstMatchInString:params
                                  options:0
                                    range:NSMakeRange(0, params.length)];

      if (heightMatch) {
        NSString *heightString =
            [params substringWithRange:[heightMatch rangeAtIndex:1]];
        imageData.height = [heightString floatValue];
      }

      stylePair.styleValue = imageData;
    } else if ([tagName isEqualToString:@"u"]) {
      [styleArr addObject:@([UnderlineStyle getType])];
    } else if ([tagName isEqualToString:@"s"]) {
      [styleArr addObject:@([StrikethroughStyle getType])];
    } else if ([tagName isEqualToString:@"code"]) {
      [styleArr addObject:@([InlineCodeStyle getType])];
    } else if ([tagName isEqualToString:@"a"]) {
      NSRegularExpression *hrefRegex =
          [NSRegularExpression regularExpressionWithPattern:@"href=\".+\""
                                                    options:0
                                                      error:nullptr];
      NSTextCheckingResult *match =
          [hrefRegex firstMatchInString:params
                                options:0
                                  range:NSMakeRange(0, params.length)];

      if (match == nullptr) {
        // same as on Android, no href (or empty href) equals no link style
        continue;
      }

      NSRange hrefRange = match.range;
      [styleArr addObject:@([LinkStyle getType])];
      // cut only the url from the href="..." string
      NSString *url =
          [params substringWithRange:NSMakeRange(hrefRange.location + 6,
                                                 hrefRange.length - 7)];
      NSString *text = [plainText substringWithRange:tagRangeValue.rangeValue];

      LinkData *linkData = [[LinkData alloc] init];
      linkData.url = url;
      linkData.text = text;
      linkData.isManual = ![text isEqualToString:url];

      stylePair.styleValue = linkData;
    } else if ([tagName isEqualToString:@"mention"]) {
      [styleArr addObject:@([MentionStyle getType])];
      // extract html expression into dict using some regex
      NSMutableDictionary *paramsDict = [[NSMutableDictionary alloc] init];
      NSString *pattern = @"(\\w+)=(['\"])(.*?)\\2";
      NSRegularExpression *regex =
          [NSRegularExpression regularExpressionWithPattern:pattern
                                                    options:0
                                                      error:nil];

      [regex enumerateMatchesInString:params
                              options:0
                                range:NSMakeRange(0, params.length)
                           usingBlock:^(NSTextCheckingResult *_Nullable result,
                                        NSMatchingFlags flags,
                                        BOOL *_Nonnull stop) {
                             if (result.numberOfRanges == 4) {
                               NSString *key = [params
                                   substringWithRange:[result rangeAtIndex:1]];
                               NSString *value = [params
                                   substringWithRange:[result rangeAtIndex:3]];
                               paramsDict[key] = value;
                             }
                           }];

      MentionParams *mentionParams = [[MentionParams alloc] init];
      mentionParams.text = paramsDict[@"text"];
      mentionParams.indicator = paramsDict[@"indicator"];

      [paramsDict removeObjectsForKeys:@[ @"text", @"indicator" ]];
      NSError *error;
      NSData *attrsData = [NSJSONSerialization dataWithJSONObject:paramsDict
                                                          options:0
                                                            error:&error];
      NSString *formattedAttrsString =
          [[NSString alloc] initWithData:attrsData
                                encoding:NSUTF8StringEncoding];
      mentionParams.attributes = formattedAttrsString;

      stylePair.styleValue = mentionParams;
    } else if ([tagName isEqualToString:@"h1"]) {
      [styleArr addObject:@([H1Style getType])];
    } else if ([tagName isEqualToString:@"h2"]) {
      [styleArr addObject:@([H2Style getType])];
    } else if ([tagName isEqualToString:@"h3"]) {
      [styleArr addObject:@([H3Style getType])];
    } else if ([tagName isEqualToString:@"h4"]) {
      [styleArr addObject:@([H4Style getType])];
    } else if ([tagName isEqualToString:@"h5"]) {
      [styleArr addObject:@([H5Style getType])];
    } else if ([tagName isEqualToString:@"h6"]) {
      [styleArr addObject:@([H6Style getType])];
    } else if ([tagName isEqualToString:@"ul"]) {
      if ([self isUlCheckboxList:params]) {
        [styleArr addObject:@([CheckboxListStyle getType])];
        stylePair.styleValue =
            [self prepareCheckboxListStyleValue:tagRangeValue
                                 checkboxStates:checkboxStates];
      } else {
        [styleArr addObject:@([UnorderedListStyle getType])];
      }
    } else if ([tagName isEqualToString:@"ol"]) {
      [styleArr addObject:@([OrderedListStyle getType])];
    } else if ([tagName isEqualToString:@"blockquote"]) {
      [styleArr addObject:@([BlockQuoteStyle getType])];
    } else if ([tagName isEqualToString:@"codeblock"]) {
      [styleArr addObject:@([CodeBlockStyle getType])];
    } else {
      // some other external tags like span just don't get put into the
      // processed styles
      continue;
    }

    stylePair.rangeValue = tagRangeValue;
    [styleArr addObject:stylePair];
    [processedStyles addObject:styleArr];
  }

  return @[ plainText, processedStyles ];
}

@end
