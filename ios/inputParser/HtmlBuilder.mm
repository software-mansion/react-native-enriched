#import "HtmlBuilder.h"
#import "StringExtension.h"
#import "StyleHeaders.h"

@implementation HtmlBuilder

- (NSString *)htmlFromRange:(NSRange)range {
  NSInteger offset = range.location;
  NSString *text =
      [_input->textView.textStorage.string substringWithRange:range];

  if (text.length == 0) {
    return @"<html>\n<p></p>\n</html>";
  }

  NSMutableString *result = [[NSMutableString alloc] initWithString:@"<html>"];
  NSSet<NSNumber *> *previousActiveStyles = [[NSSet<NSNumber *> alloc] init];
  BOOL newLine = YES;
  BOOL inUnorderedList = NO;
  BOOL inOrderedList = NO;
  BOOL inBlockQuote = NO;
  BOOL inCodeBlock = NO;
  unichar lastCharacter = 0;

  for (int i = 0; i < text.length; i++) {
    NSRange currentRange = NSMakeRange(offset + i, 1);
    NSMutableSet<NSNumber *> *currentActiveStyles =
        [[NSMutableSet<NSNumber *> alloc] init];
    NSMutableDictionary *currentActiveStylesBeginning =
        [[NSMutableDictionary alloc] init];

    // check each existing style existence
    for (NSNumber *type in _input->stylesDict) {
      id<BaseStyleProtocol> style = _input->stylesDict[type];
      if ([style detectStyle:currentRange]) {
        [currentActiveStyles addObject:type];

        if (![previousActiveStyles member:type]) {
          currentActiveStylesBeginning[type] = [NSNumber numberWithInt:i];
        }
      } else if ([previousActiveStyles member:type]) {
        [currentActiveStylesBeginning removeObjectForKey:type];
      }
    }

    NSString *currentCharacterStr =
        [_input->textView.textStorage.string substringWithRange:currentRange];
    unichar currentCharacterChar = [_input->textView.textStorage.string
        characterAtIndex:currentRange.location];

    if ([[NSCharacterSet newlineCharacterSet]
            characterIsMember:currentCharacterChar]) {
      if (newLine) {
        // we can either have an empty list item OR need to close the list and
        // put a BR in such a situation the existence of the list must be
        // checked on 0 length range, not on the newline character
        if (inOrderedList) {
          OrderedListStyle *oStyle = _input->stylesDict[@(OrderedList)];
          BOOL detected =
              [oStyle detectStyle:NSMakeRange(currentRange.location, 0)];
          if (detected) {
            [result appendString:@"\n<li></li>"];
          } else {
            [result appendString:@"\n</ol>\n<br>"];
            inOrderedList = NO;
          }
        } else if (inUnorderedList) {
          UnorderedListStyle *uStyle = _input->stylesDict[@(UnorderedList)];
          BOOL detected =
              [uStyle detectStyle:NSMakeRange(currentRange.location, 0)];
          if (detected) {
            [result appendString:@"\n<li></li>"];
          } else {
            [result appendString:@"\n</ul>\n<br>"];
            inUnorderedList = NO;
          }
        } else {
          [result appendString:@"\n<br>"];
        }
      } else {
        // newline finishes a paragraph and all style tags need to be closed
        // we use previous styles
        NSArray<NSNumber *> *sortedEndedStyles = [previousActiveStyles
            sortedArrayUsingDescriptors:@[ [NSSortDescriptor
                                            sortDescriptorWithKey:@"intValue"
                                                        ascending:NO] ]];

        // append closing tags
        for (NSNumber *style in sortedEndedStyles) {
          if ([style isEqualToNumber:@([ImageStyle getStyleType])]) {
            continue;
          }
          NSString *tagContent =
              [self tagContentForStyle:style
                            openingTag:NO
                              location:currentRange.location];
          [result
              appendString:[NSString stringWithFormat:@"</%@>", tagContent]];
        }

        // append closing paragraph tag
        if ([previousActiveStyles
                containsObject:@([UnorderedListStyle getStyleType])] ||
            [previousActiveStyles
                containsObject:@([OrderedListStyle getStyleType])] ||
            [previousActiveStyles containsObject:@([H1Style getStyleType])] ||
            [previousActiveStyles containsObject:@([H2Style getStyleType])] ||
            [previousActiveStyles containsObject:@([H3Style getStyleType])] ||
            [previousActiveStyles
                containsObject:@([BlockQuoteStyle getStyleType])] ||
            [previousActiveStyles
                containsObject:@([CodeBlockStyle getStyleType])]) {
          // do nothing, proper closing paragraph tags have been already
          // appended
        } else {
          [result appendString:@"</p>"];
        }
      }

      // clear the previous styles
      previousActiveStyles = [[NSSet<NSNumber *> alloc] init];

      // next character opens new paragraph
      newLine = YES;
    } else {
      // new line - open the paragraph
      if (newLine) {
        newLine = NO;

        // handle ending unordered list
        if (inUnorderedList &&
            ![currentActiveStyles
                containsObject:@([UnorderedListStyle getStyleType])]) {
          inUnorderedList = NO;
          [result appendString:@"\n</ul>"];
        }
        // handle ending ordered list
        if (inOrderedList &&
            ![currentActiveStyles
                containsObject:@([OrderedListStyle getStyleType])]) {
          inOrderedList = NO;
          [result appendString:@"\n</ol>"];
        }
        // handle ending blockquotes
        if (inBlockQuote &&
            ![currentActiveStyles
                containsObject:@([BlockQuoteStyle getStyleType])]) {
          inBlockQuote = NO;
          [result appendString:@"\n</blockquote>"];
        }
        // handle ending codeblock
        if (inCodeBlock &&
            ![currentActiveStyles
                containsObject:@([CodeBlockStyle getStyleType])]) {
          inCodeBlock = NO;
          [result appendString:@"\n</codeblock>"];
        }

        // handle starting unordered list
        if (!inUnorderedList &&
            [currentActiveStyles
                containsObject:@([UnorderedListStyle getStyleType])]) {
          inUnorderedList = YES;
          [result appendString:@"\n<ul>"];
        }
        // handle starting ordered list
        if (!inOrderedList &&
            [currentActiveStyles
                containsObject:@([OrderedListStyle getStyleType])]) {
          inOrderedList = YES;
          [result appendString:@"\n<ol>"];
        }
        // handle starting blockquotes
        if (!inBlockQuote &&
            [currentActiveStyles
                containsObject:@([BlockQuoteStyle getStyleType])]) {
          inBlockQuote = YES;
          [result appendString:@"\n<blockquote>"];
        }
        // handle starting codeblock
        if (!inCodeBlock &&
            [currentActiveStyles
                containsObject:@([CodeBlockStyle getStyleType])]) {
          inCodeBlock = YES;
          [result appendString:@"\n<codeblock>"];
        }

        // don't add the <p> tag if some paragraph styles are present
        if ([currentActiveStyles
                containsObject:@([UnorderedListStyle getStyleType])] ||
            [currentActiveStyles
                containsObject:@([OrderedListStyle getStyleType])] ||
            [currentActiveStyles containsObject:@([H1Style getStyleType])] ||
            [currentActiveStyles containsObject:@([H2Style getStyleType])] ||
            [currentActiveStyles containsObject:@([H3Style getStyleType])] ||
            [currentActiveStyles
                containsObject:@([BlockQuoteStyle getStyleType])] ||
            [currentActiveStyles
                containsObject:@([CodeBlockStyle getStyleType])]) {
          [result appendString:@"\n"];
        } else {
          [result appendString:@"\n<p>"];
        }
      }

      // get styles that have ended
      NSMutableSet<NSNumber *> *endedStyles =
          [previousActiveStyles mutableCopy];
      [endedStyles minusSet:currentActiveStyles];

      // also finish styles that should be ended becasue they are nested in a
      // style that ended
      NSMutableSet *fixedEndedStyles = [endedStyles mutableCopy];
      NSMutableSet *stylesToBeReAdded = [[NSMutableSet alloc] init];

      for (NSNumber *style in endedStyles) {
        NSInteger styleBeginning =
            [currentActiveStylesBeginning[style] integerValue];

        for (NSNumber *activeStyle in currentActiveStyles) {
          NSInteger activeStyleBeginning =
              [currentActiveStylesBeginning[activeStyle] integerValue];

          // we end the styles that began after the currently ended style but
          // not at the "i" (cause the old style ended at exactly "i-1" also the
          // ones that began in the exact same place but are "inner" in relation
          // to them due to StyleTypeEnum integer values

          if ((activeStyleBeginning > styleBeginning &&
               activeStyleBeginning < i) ||
              (activeStyleBeginning == styleBeginning &&
               activeStyleBeginning<
                   i && [activeStyle integerValue]>[style integerValue])) {
            [fixedEndedStyles addObject:activeStyle];
            [stylesToBeReAdded addObject:activeStyle];
          }
        }
      }

      // if a style begins but there is a style inner to it that is (and was
      // previously) active, it also should be closed and readded

      // newly added styles
      NSMutableSet *newStyles = [currentActiveStyles mutableCopy];
      [newStyles minusSet:previousActiveStyles];
      // styles that were and still are active
      NSMutableSet *stillActiveStyles = [previousActiveStyles mutableCopy];
      [stillActiveStyles intersectSet:currentActiveStyles];

      for (NSNumber *style in newStyles) {
        for (NSNumber *ongoingStyle in stillActiveStyles) {
          if ([ongoingStyle integerValue] > [style integerValue]) {
            // the prev style is inner; needs to be closed and re-added later
            [fixedEndedStyles addObject:ongoingStyle];
            [stylesToBeReAdded addObject:ongoingStyle];
          }
        }
      }

      // they are sorted in a descending order
      NSArray<NSNumber *> *sortedEndedStyles = [fixedEndedStyles
          sortedArrayUsingDescriptors:@[ [NSSortDescriptor
                                          sortDescriptorWithKey:@"intValue"
                                                      ascending:NO] ]];

      // append closing tags
      for (NSNumber *style in sortedEndedStyles) {
        if ([style isEqualToNumber:@([ImageStyle getStyleType])]) {
          continue;
        }
        NSString *tagContent = [self tagContentForStyle:style
                                             openingTag:NO
                                               location:currentRange.location];
        [result appendString:[NSString stringWithFormat:@"</%@>", tagContent]];
      }

      // all styles that have begun: new styles + the ones that need to be
      // re-added they are sorted in a ascending manner to properly keep tags'
      // FILO order
      [newStyles unionSet:stylesToBeReAdded];
      NSArray<NSNumber *> *sortedNewStyles = [newStyles
          sortedArrayUsingDescriptors:@[ [NSSortDescriptor
                                          sortDescriptorWithKey:@"intValue"
                                                      ascending:YES] ]];

      // append opening tags
      for (NSNumber *style in sortedNewStyles) {
        NSString *tagContent = [self tagContentForStyle:style
                                             openingTag:YES
                                               location:currentRange.location];
        if ([style isEqualToNumber:@([ImageStyle getStyleType])]) {
          [result
              appendString:[NSString stringWithFormat:@"<%@/>", tagContent]];
          [currentActiveStyles removeObject:@([ImageStyle getStyleType])];
        } else {
          [result appendString:[NSString stringWithFormat:@"<%@>", tagContent]];
        }
      }

      // append the letter and escape it if needed
      [result appendString:[NSString stringByEscapingHtml:currentCharacterStr]];

      // save current styles for next character's checks
      previousActiveStyles = currentActiveStyles;
    }

    // set last character
    lastCharacter = currentCharacterChar;
  }

  if (![[NSCharacterSet newlineCharacterSet] characterIsMember:lastCharacter]) {
    // not-newline character was last - finish the paragraph
    // close all pending tags
    NSArray<NSNumber *> *sortedEndedStyles = [previousActiveStyles
        sortedArrayUsingDescriptors:@[ [NSSortDescriptor
                                        sortDescriptorWithKey:@"intValue"
                                                    ascending:NO] ]];

    // append closing tags
    for (NSNumber *style in sortedEndedStyles) {
      if ([style isEqualToNumber:@([ImageStyle getStyleType])]) {
        continue;
      }
      NSString *tagContent = [self
          tagContentForStyle:style
                  openingTag:NO
                    location:_input->textView.textStorage.string.length - 1];
      [result appendString:[NSString stringWithFormat:@"</%@>", tagContent]];
    }

    // finish the paragraph
    // handle ending of some paragraph styles
    if ([previousActiveStyles
            containsObject:@([UnorderedListStyle getStyleType])]) {
      [result appendString:@"\n</ul>"];
    } else if ([previousActiveStyles
                   containsObject:@([OrderedListStyle getStyleType])]) {
      [result appendString:@"\n</ol>"];
    } else if ([previousActiveStyles
                   containsObject:@([BlockQuoteStyle getStyleType])]) {
      [result appendString:@"\n</blockquote>"];
    } else if ([previousActiveStyles
                   containsObject:@([CodeBlockStyle getStyleType])]) {
      [result appendString:@"\n</codeblock>"];
    } else if ([previousActiveStyles
                   containsObject:@([H1Style getStyleType])] ||
               [previousActiveStyles
                   containsObject:@([H2Style getStyleType])] ||
               [previousActiveStyles
                   containsObject:@([H3Style getStyleType])]) {
      // do nothing, heading closing tag has already ben appended
    } else {
      [result appendString:@"</p>"];
    }
  } else {
    // newline character was last - some paragraph styles need to be closed
    if (inUnorderedList) {
      inUnorderedList = NO;
      [result appendString:@"\n</ul>"];
    }
    if (inOrderedList) {
      inOrderedList = NO;
      [result appendString:@"\n</ol>"];
    }
    if (inBlockQuote) {
      inBlockQuote = NO;
      [result appendString:@"\n</blockquote>"];
    }
    if (inCodeBlock) {
      inCodeBlock = NO;
      [result appendString:@"\n</codeblock>"];
    }
  }

  [result appendString:@"\n</html>"];

  // remove zero width spaces in the very end
  NSRange resultRange = NSMakeRange(0, result.length);
  [result replaceOccurrencesOfString:@"\u200B"
                          withString:@""
                             options:0
                               range:resultRange];
  return result;
}

- (NSString *)tagContentForStyle:(NSNumber *)style
                      openingTag:(BOOL)openingTag
                        location:(NSInteger)location {
  if ([style isEqualToNumber:@([BoldStyle getStyleType])]) {
    return @"b";
  } else if ([style isEqualToNumber:@([ItalicStyle getStyleType])]) {
    return @"i";
  } else if ([style isEqualToNumber:@([ImageStyle getStyleType])]) {
    if (openingTag) {
      ImageStyle *imageStyle =
          (ImageStyle *)_input->stylesDict[@([ImageStyle getStyleType])];
      if (imageStyle != nullptr) {
        ImageData *data = [imageStyle getImageDataAt:location];
        if (data != nullptr && data.uri != nullptr) {
          return [NSString
              stringWithFormat:@"img src=\"%@\" width=\"%f\" height=\"%f\"",
                               data.uri, data.width, data.height];
        }
      }
      return @"img";
    } else {
      return @"";
    }
  } else if ([style isEqualToNumber:@([UnderlineStyle getStyleType])]) {
    return @"u";
  } else if ([style isEqualToNumber:@([StrikethroughStyle getStyleType])]) {
    return @"s";
  } else if ([style isEqualToNumber:@([InlineCodeStyle getStyleType])]) {
    return @"code";
  } else if ([style isEqualToNumber:@([LinkStyle getStyleType])]) {
    if (openingTag) {
      LinkStyle *linkStyle =
          (LinkStyle *)_input->stylesDict[@([LinkStyle getStyleType])];
      if (linkStyle != nullptr) {
        LinkData *data = [linkStyle getLinkDataAt:location];
        if (data != nullptr && data.url != nullptr) {
          return [NSString stringWithFormat:@"a href=\"%@\"", data.url];
        }
      }
      return @"a";
    } else {
      return @"a";
    }
  } else if ([style isEqualToNumber:@([MentionStyle getStyleType])]) {
    if (openingTag) {
      MentionStyle *mentionStyle =
          (MentionStyle *)_input->stylesDict[@([MentionStyle getStyleType])];
      if (mentionStyle != nullptr) {
        MentionParams *params = [mentionStyle getMentionParamsAt:location];
        // attributes can theoretically be nullptr
        if (params != nullptr && params.indicator != nullptr &&
            params.text != nullptr) {
          NSMutableString *attrsStr =
              [[NSMutableString alloc] initWithString:@""];
          if (params.attributes != nullptr) {
            // turn attributes to Data and then into dict
            NSData *attrsData =
                [params.attributes dataUsingEncoding:NSUTF8StringEncoding];
            NSError *jsonError;
            NSDictionary *json =
                [NSJSONSerialization JSONObjectWithData:attrsData
                                                options:0
                                                  error:&jsonError];
            // format dict keys and values into string
            [json enumerateKeysAndObjectsUsingBlock:^(
                      id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
              [attrsStr
                  appendString:[NSString stringWithFormat:@" %@=\"%@\"",
                                                          (NSString *)key,
                                                          (NSString *)obj]];
            }];
          }
          return [NSString
              stringWithFormat:@"mention text=\"%@\" indicator=\"%@\"%@",
                               params.text, params.indicator, attrsStr];
        }
      }
      return @"mention";
    } else {
      return @"mention";
    }
  } else if ([style isEqualToNumber:@([H1Style getStyleType])]) {
    return @"h1";
  } else if ([style isEqualToNumber:@([H2Style getStyleType])]) {
    return @"h2";
  } else if ([style isEqualToNumber:@([H3Style getStyleType])]) {
    return @"h3";
  } else if ([style isEqualToNumber:@([UnorderedListStyle getStyleType])] ||
             [style isEqualToNumber:@([OrderedListStyle getStyleType])]) {
    return @"li";
  } else if ([style isEqualToNumber:@([BlockQuoteStyle getStyleType])] ||
             [style isEqualToNumber:@([CodeBlockStyle getStyleType])]) {
    // blockquotes and codeblock use <p> tags the same way lists use <li>
    return @"p";
  }
  return @"";
}

@end
