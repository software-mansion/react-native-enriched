#import "HtmlTokenizer.h"
#import "StringExtension.h"
#import "StyleHeaders.h"

@implementation HtmlTokenizationResult
@end

@implementation HtmlTokenizer

static const int MIN_HTML_SIZE = 13;

- (NSString *_Nullable)initiallyProcessHtml:(NSString *_Nonnull)html {
  NSString *fixedHtml = nullptr;

  if (html.length >= MIN_HTML_SIZE) {
    NSString *firstSix = [html substringWithRange:NSMakeRange(0, 6)];
    NSString *lastSeven =
        [html substringWithRange:NSMakeRange(html.length - 7, 7)];

    if ([firstSix isEqualToString:@"<html>"] &&
        [lastSeven isEqualToString:@"</html>"]) {
      // remove html tags, might be with newlines or without them
      fixedHtml = [html copy];
      NSRegularExpression *regex = [NSRegularExpression
          regularExpressionWithPattern:@"<html>\\n?|</html>\\n?"
                               options:0
                                 error:nil];

      fixedHtml =
          [regex stringByReplacingMatchesInString:html
                                          options:0
                                            range:NSMakeRange(0, html.length)
                                     withTemplate:@""];
    } else {
      // in other case we are most likely working with some external html - try
      // getting the styles from between body tags
      NSRange openingBodyRange = [html rangeOfString:@"<body>"];
      NSRange closingBodyRange = [html rangeOfString:@"</body>"];

      if (openingBodyRange.length != 0 && closingBodyRange.length != 0) {
        NSInteger newStart = openingBodyRange.location + 7;
        NSInteger newEnd = closingBodyRange.location - 1;
        fixedHtml = [html
            substringWithRange:NSMakeRange(newStart, newEnd - newStart + 1)];
      }
    }
  }

  // second processing - try fixing htmls with wrong newlines' setup
  if (fixedHtml) {
    // add <br> tag wherever needed
    fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"<p></p>"
                                                     withString:@"<br>"];

    // remove <p> tags inside of <li>
    fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"<li><p>"
                                                     withString:@"<li>"];
    fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"</p></li>"
                                                     withString:@"</li>"];

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
  }

  return fixedHtml;
}

- (NSString *)stringByAddingNewlinesToTag:(NSString *)tag
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

- (HtmlTokenizationResult *)tokenize:(NSString *)fixedHtml {
  NSMutableString *plainText = [[NSMutableString alloc] initWithString:@""];
  NSMutableDictionary *ongoingTags = [[NSMutableDictionary alloc] init];
  NSMutableArray *initiallyProcessedTags = [[NSMutableArray alloc] init];
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
          [currentTagName isEqualToString:@"br"] ||
          [currentTagName isEqualToString:@"li"]) {
        // do nothing, we don't include these tags in styles
      } else if (!closingTag) {
        // we finish opening tag - get its location and optionally params and
        // put them under tag name key in ongoingTags
        NSMutableArray *tagArr = [[NSMutableArray alloc] init];
        [tagArr addObject:[NSNumber numberWithInteger:plainText.length]];
        if (currentTagParams.length > 0) {
          [tagArr addObject:[currentTagParams copy]];
        }
        ongoingTags[currentTagName] = tagArr;

        // skip one newline after opening tags that are in separate lines
        // intentionally
        if ([currentTagName isEqualToString:@"ul"] ||
            [currentTagName isEqualToString:@"ol"] ||
            [currentTagName isEqualToString:@"blockquote"] ||
            [currentTagName isEqualToString:@"codeblock"]) {
          i += 1;
        }

        if (isSelfClosing) {
          [self finalizeTag:currentTagName
                         ongoingTags:ongoingTags
              initiallyProcessedTags:initiallyProcessedTags
                           plainText:plainText];
        }
      } else {
        // we finish closing tags - pack tag name, tag range and optionally tag
        // params into an entry that goes inside initiallyProcessedTags

        // skip one newline that was added before some closing tags that are in
        // separate lines
        if ([currentTagName isEqualToString:@"ul"] ||
            [currentTagName isEqualToString:@"ol"] ||
            [currentTagName isEqualToString:@"blockquote"] ||
            [currentTagName isEqualToString:@"codeblock"]) {
          plainText = [[plainText
              substringWithRange:NSMakeRange(0, plainText.length - 1)]
              mutableCopy];
        }

        [self finalizeTag:currentTagName
                       ongoingTags:ongoingTags
            initiallyProcessedTags:initiallyProcessedTags
                         plainText:plainText];
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

  HtmlTokenizationResult *result = [[HtmlTokenizationResult alloc] init];
  result.plainText = plainText;
  result.initialTags = initiallyProcessedTags;

  return result;
}

- (void)finalizeTag:(NSMutableString *)tagName
               ongoingTags:(NSMutableDictionary *)ongoingTags
    initiallyProcessedTags:(NSMutableArray *)processedTags
                 plainText:(NSMutableString *)plainText {
  NSMutableArray *tagEntry = [[NSMutableArray alloc] init];

  NSArray *tagData = ongoingTags[tagName];
  NSInteger tagLocation = [((NSNumber *)tagData[0]) intValue];
  NSRange tagRange = NSMakeRange(tagLocation, plainText.length - tagLocation);

  [tagEntry addObject:[tagName copy]];
  [tagEntry addObject:[NSValue valueWithRange:tagRange]];
  if (tagData.count > 1) {
    [tagEntry addObject:[(NSString *)tagData[1] copy]];
  }

  [processedTags addObject:tagEntry];
  [ongoingTags removeObjectForKey:tagName];
}

@end
