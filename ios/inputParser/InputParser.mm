#import "InputParser.h"
#import "EnrichedTextInputView.h"
#import "HtmlParser.h"
#import "StringExtension.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

@implementation InputParser {
  EnrichedTextInputView __weak *_input;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  return self;
}

- (NSString *)parseToHtmlFromRange:(NSRange)range {
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
  BOOL inCheckboxList = NO;
  unichar lastCharacter = 0;

  for (int i = 0; i < text.length; i++) {
    NSRange currentRange = NSMakeRange(offset + i, 1);
    NSMutableSet<NSNumber *> *currentActiveStyles =
        [[NSMutableSet<NSNumber *> alloc] init];
    NSMutableDictionary *currentActiveStylesBeginning =
        [[NSMutableDictionary alloc] init];

    // check each existing style existence
    for (NSNumber *type in _input->stylesDict) {
      StyleBase *style = _input->stylesDict[type];
      if ([style detect:currentRange]) {
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
          BOOL detected = [oStyle detect:NSMakeRange(currentRange.location, 0)];
          if (detected) {
            [result appendString:@"\n<li></li>"];
          } else {
            [result appendString:@"\n</ol>\n<br>"];
            inOrderedList = NO;
          }
        } else if (inUnorderedList) {
          UnorderedListStyle *uStyle = _input->stylesDict[@(UnorderedList)];
          BOOL detected = [uStyle detect:NSMakeRange(currentRange.location, 0)];
          if (detected) {
            [result appendString:@"\n<li></li>"];
          } else {
            [result appendString:@"\n</ul>\n<br>"];
            inUnorderedList = NO;
          }
        } else if (inBlockQuote) {
          BlockQuoteStyle *bqStyle = _input->stylesDict[@(BlockQuote)];
          BOOL detected =
              [bqStyle detect:NSMakeRange(currentRange.location, 0)];
          if (detected) {
            [result appendString:@"\n<br>"];
          } else {
            [result appendString:@"\n</blockquote>\n<br>"];
            inBlockQuote = NO;
          }
        } else if (inCodeBlock) {
          CodeBlockStyle *cbStyle = _input->stylesDict[@(CodeBlock)];
          BOOL detected =
              [cbStyle detect:NSMakeRange(currentRange.location, 0)];
          if (detected) {
            [result appendString:@"\n<br>"];
          } else {
            [result appendString:@"\n</codeblock>\n<br>"];
            inCodeBlock = NO;
          }
        } else if (inCheckboxList) {
          CheckboxListStyle *cbLStyle = _input->stylesDict[@(CheckboxList)];
          BOOL detected =
              [cbLStyle detect:NSMakeRange(currentRange.location, 0)];
          if (detected) {
            BOOL checked = [cbLStyle getCheckboxStateAt:currentRange.location];
            if (checked) {
              [result appendString:@"\n<li checked></li>"];
            } else {
              [result appendString:@"\n<li></li>"];
            }
          } else {
            [result appendString:@"\n</ul>\n<br>"];
            inCheckboxList = NO;
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
          if ([style isEqualToNumber:@([ImageStyle getType])]) {
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
                containsObject:@([UnorderedListStyle getType])] ||
            [previousActiveStyles
                containsObject:@([OrderedListStyle getType])] ||
            [previousActiveStyles containsObject:@([H1Style getType])] ||
            [previousActiveStyles containsObject:@([H2Style getType])] ||
            [previousActiveStyles containsObject:@([H3Style getType])] ||
            [previousActiveStyles containsObject:@([H4Style getType])] ||
            [previousActiveStyles containsObject:@([H5Style getType])] ||
            [previousActiveStyles containsObject:@([H6Style getType])] ||
            [previousActiveStyles
                containsObject:@([BlockQuoteStyle getType])] ||
            [previousActiveStyles containsObject:@([CodeBlockStyle getType])] ||
            [previousActiveStyles
                containsObject:@([CheckboxListStyle getType])]) {
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
                containsObject:@([UnorderedListStyle getType])]) {
          inUnorderedList = NO;
          [result appendString:@"\n</ul>"];
        }
        // handle ending ordered list
        if (inOrderedList &&
            ![currentActiveStyles
                containsObject:@([OrderedListStyle getType])]) {
          inOrderedList = NO;
          [result appendString:@"\n</ol>"];
        }
        // handle ending blockquotes
        if (inBlockQuote && ![currentActiveStyles
                                containsObject:@([BlockQuoteStyle getType])]) {
          inBlockQuote = NO;
          [result appendString:@"\n</blockquote>"];
        }
        // handle ending codeblock
        if (inCodeBlock &&
            ![currentActiveStyles containsObject:@([CodeBlockStyle getType])]) {
          inCodeBlock = NO;
          [result appendString:@"\n</codeblock>"];
        }
        // handle ending checkbox list
        if (inCheckboxList &&
            ![currentActiveStyles
                containsObject:@([CheckboxListStyle getType])]) {
          inCheckboxList = NO;
          [result appendString:@"\n</ul>"];
        }

        // handle starting unordered list
        if (!inUnorderedList &&
            [currentActiveStyles
                containsObject:@([UnorderedListStyle getType])]) {
          inUnorderedList = YES;
          [result appendString:@"\n<ul>"];
        }
        // handle starting ordered list
        if (!inOrderedList &&
            [currentActiveStyles
                containsObject:@([OrderedListStyle getType])]) {
          inOrderedList = YES;
          [result appendString:@"\n<ol>"];
        }
        // handle starting blockquotes
        if (!inBlockQuote &&
            [currentActiveStyles containsObject:@([BlockQuoteStyle getType])]) {
          inBlockQuote = YES;
          [result appendString:@"\n<blockquote>"];
        }
        // handle starting codeblock
        if (!inCodeBlock &&
            [currentActiveStyles containsObject:@([CodeBlockStyle getType])]) {
          inCodeBlock = YES;
          [result appendString:@"\n<codeblock>"];
        }
        // handle starting checkbox list
        if (!inCheckboxList &&
            [currentActiveStyles
                containsObject:@([CheckboxListStyle getType])]) {
          inCheckboxList = YES;
          [result appendString:@"\n<ul data-type=\"checkbox\">"];
        }

        // don't add the <p> tag if some paragraph styles are present
        if ([currentActiveStyles
                containsObject:@([UnorderedListStyle getType])] ||
            [currentActiveStyles
                containsObject:@([OrderedListStyle getType])] ||
            [currentActiveStyles containsObject:@([H1Style getType])] ||
            [currentActiveStyles containsObject:@([H2Style getType])] ||
            [currentActiveStyles containsObject:@([H3Style getType])] ||
            [currentActiveStyles containsObject:@([H4Style getType])] ||
            [currentActiveStyles containsObject:@([H5Style getType])] ||
            [currentActiveStyles containsObject:@([H6Style getType])] ||
            [currentActiveStyles containsObject:@([BlockQuoteStyle getType])] ||
            [currentActiveStyles containsObject:@([CodeBlockStyle getType])] ||
            [currentActiveStyles
                containsObject:@([CheckboxListStyle getType])]) {
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
        if ([style isEqualToNumber:@([ImageStyle getType])]) {
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
        if ([style isEqualToNumber:@([ImageStyle getType])]) {
          [result
              appendString:[NSString stringWithFormat:@"<%@/>", tagContent]];
          [currentActiveStyles removeObject:@([ImageStyle getType])];
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
      if ([style isEqualToNumber:@([ImageStyle getType])]) {
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
    if ([previousActiveStyles containsObject:@([UnorderedListStyle getType])]) {
      [result appendString:@"\n</ul>"];
    } else if ([previousActiveStyles
                   containsObject:@([OrderedListStyle getType])]) {
      [result appendString:@"\n</ol>"];
    } else if ([previousActiveStyles
                   containsObject:@([BlockQuoteStyle getType])]) {
      [result appendString:@"\n</blockquote>"];
    } else if ([previousActiveStyles
                   containsObject:@([CodeBlockStyle getType])]) {
      [result appendString:@"\n</codeblock>"];
    } else if ([previousActiveStyles
                   containsObject:@([CheckboxListStyle getType])]) {
      [result appendString:@"\n</ul>"];
    } else if ([previousActiveStyles containsObject:@([H1Style getType])] ||
               [previousActiveStyles containsObject:@([H2Style getType])] ||
               [previousActiveStyles containsObject:@([H3Style getType])] ||
               [previousActiveStyles containsObject:@([H4Style getType])] ||
               [previousActiveStyles containsObject:@([H5Style getType])] ||
               [previousActiveStyles containsObject:@([H6Style getType])]) {
      // do nothing, heading closing tag has already been appended
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
    if (inCheckboxList) {
      inCheckboxList = NO;
      [result appendString:@"\n</ul>"];
    }
  }

  [result appendString:@"\n</html>"];

  // remove Object Replacement Characters in the very end
  [result replaceOccurrencesOfString:@"\uFFFC"
                          withString:@""
                             options:0
                               range:NSMakeRange(0, result.length)];

  // remove zero width spaces in the very end
  [result replaceOccurrencesOfString:@"\u200B"
                          withString:@""
                             options:0
                               range:NSMakeRange(0, result.length)];

  // replace empty <p></p> into <br> in the very end
  [result replaceOccurrencesOfString:@"<p></p>"
                          withString:@"<br>"
                             options:0
                               range:NSMakeRange(0, result.length)];

  return result;
}

- (NSString *)tagContentForStyle:(NSNumber *)style
                      openingTag:(BOOL)openingTag
                        location:(NSInteger)location {
  if ([style isEqualToNumber:@([BoldStyle getType])]) {
    return @"b";
  } else if ([style isEqualToNumber:@([ItalicStyle getType])]) {
    return @"i";
  } else if ([style isEqualToNumber:@([ImageStyle getType])]) {
    if (openingTag) {
      ImageStyle *imageStyle =
          (ImageStyle *)_input->stylesDict[@([ImageStyle getType])];
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
  } else if ([style isEqualToNumber:@([UnderlineStyle getType])]) {
    return @"u";
  } else if ([style isEqualToNumber:@([StrikethroughStyle getType])]) {
    return @"s";
  } else if ([style isEqualToNumber:@([InlineCodeStyle getType])]) {
    return @"code";
  } else if ([style isEqualToNumber:@([LinkStyle getType])]) {
    if (openingTag) {
      LinkStyle *linkStyle =
          (LinkStyle *)_input->stylesDict[@([LinkStyle getType])];
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
  } else if ([style isEqualToNumber:@([MentionStyle getType])]) {
    if (openingTag) {
      MentionStyle *mentionStyle =
          (MentionStyle *)_input->stylesDict[@([MentionStyle getType])];
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
  } else if ([style isEqualToNumber:@([H1Style getType])]) {
    return @"h1";
  } else if ([style isEqualToNumber:@([H2Style getType])]) {
    return @"h2";
  } else if ([style isEqualToNumber:@([H3Style getType])]) {
    return @"h3";
  } else if ([style isEqualToNumber:@([H4Style getType])]) {
    return @"h4";
  } else if ([style isEqualToNumber:@([H5Style getType])]) {
    return @"h5";
  } else if ([style isEqualToNumber:@([H6Style getType])]) {
    return @"h6";
  } else if ([style isEqualToNumber:@([UnorderedListStyle getType])] ||
             [style isEqualToNumber:@([OrderedListStyle getType])]) {
    return @"li";
  } else if ([style isEqualToNumber:@([CheckboxListStyle getType])]) {
    if (openingTag) {
      CheckboxListStyle *checkboxListStyleClass =
          (CheckboxListStyle *)
              _input->stylesDict[@([CheckboxListStyle getType])];
      BOOL checked = [checkboxListStyleClass getCheckboxStateAt:location];

      if (checked) {
        return @"li checked";
      }
      return @"li";
    } else {
      return @"li";
    }
  } else if ([style isEqualToNumber:@([BlockQuoteStyle getType])] ||
             [style isEqualToNumber:@([CodeBlockStyle getType])]) {
    // blockquotes and codeblock use <p> tags the same way lists use <li>
    return @"p";
  }
  return @"";
}

- (void)replaceWholeFromHtml:(NSString *_Nonnull)html {
  NSArray *processingResult = [HtmlParser getTextAndStylesFromHtml:html];
  NSString *plainText = (NSString *)processingResult[0];
  NSArray *stylesInfo = (NSArray *)processingResult[1];

  // reset the text first and reset typing attributes
  _input->textView.text = @"";
  _input->textView.typingAttributes = _input->defaultTypingAttributes;

  // set new text
  _input->textView.text = plainText;

  // re-apply the styles
  [self applyProcessedStyles:stylesInfo
         offsetFromBeginning:0
             plainTextLength:plainText.length];
}

- (void)replaceFromHtml:(NSString *_Nonnull)html range:(NSRange)range {
  NSArray *processingResult = [HtmlParser getTextAndStylesFromHtml:html];
  NSString *plainText = (NSString *)processingResult[0];
  NSArray *stylesInfo = (NSArray *)processingResult[1];

  // we can use ready replace util
  [TextInsertionUtils replaceText:plainText
                               at:range
             additionalAttributes:nil
                            input:_input
                    withSelection:YES];

  [self applyProcessedStyles:stylesInfo
         offsetFromBeginning:range.location
             plainTextLength:plainText.length];
}

- (void)insertFromHtml:(NSString *_Nonnull)html location:(NSInteger)location {
  NSArray *processingResult = [HtmlParser getTextAndStylesFromHtml:html];
  NSString *plainText = (NSString *)processingResult[0];
  NSArray *stylesInfo = (NSArray *)processingResult[1];

  // same here, insertion utils got our back
  [TextInsertionUtils insertText:plainText
                              at:location
            additionalAttributes:nil
                           input:_input
                   withSelection:YES];

  [self applyProcessedStyles:stylesInfo
         offsetFromBeginning:location
             plainTextLength:plainText.length];
}

- (void)applyProcessedStyles:(NSArray *)processedStyles
         offsetFromBeginning:(NSInteger)offset
             plainTextLength:(NSUInteger)plainTextLength {
  for (NSArray *arr in processedStyles) {
    // unwrap all info from processed style
    NSNumber *styleType = (NSNumber *)arr[0];
    StylePair *stylePair = (StylePair *)arr[1];
    StyleBase *baseStyle = _input->stylesDict[styleType];
    // range must be taking offest into consideration because processed styles'
    // ranges are relative to only the new text while we need absolute ranges
    // relative to the whole existing text
    NSRange styleRange =
        NSMakeRange(offset + [stylePair.rangeValue rangeValue].location,
                    [stylePair.rangeValue rangeValue].length);

    // of course any changes here need to take blocks and conflicts into
    // consideration
    if ([_input handleStyleBlocksAndConflicts:[[baseStyle class] getType]
                                        range:styleRange]) {
      if ([styleType isEqualToNumber:@([LinkStyle getType])]) {
        LinkData *linkData = (LinkData *)stylePair.styleValue;
        [((LinkStyle *)baseStyle) addLink:linkData
                                    range:styleRange
                            withSelection:NO];
      } else if ([styleType isEqualToNumber:@([MentionStyle getType])]) {
        MentionParams *params = (MentionParams *)stylePair.styleValue;
        [((MentionStyle *)baseStyle) addMentionAtRange:styleRange
                                                params:params];
      } else if ([styleType isEqualToNumber:@([ImageStyle getType])]) {
        ImageData *imgData = (ImageData *)stylePair.styleValue;
        [((ImageStyle *)baseStyle) addImageAtRange:styleRange
                                         imageData:imgData
                                     withSelection:NO];
      } else if ([styleType isEqualToNumber:@([CheckboxListStyle getType])]) {
        NSDictionary *checkboxStates = (NSDictionary *)stylePair.styleValue;
        CheckboxListStyle *cbLStyle = (CheckboxListStyle *)baseStyle;

        // First apply the checkbox list style to the entire range with
        // unchecked value
        BOOL shouldAddTypingAttr =
            styleRange.location + styleRange.length == plainTextLength;
        [cbLStyle addWithChecked:NO
                           range:styleRange
                      withTyping:shouldAddTypingAttr
                  withDirtyRange:YES];

        if (!checkboxStates && checkboxStates.count == 0) {
          continue;
        }
        // Then toggle checked checkboxes
        for (NSNumber *key in checkboxStates) {
          NSUInteger checkboxPosition = offset + [key unsignedIntegerValue];
          BOOL isChecked = [checkboxStates[key] boolValue];
          if (isChecked) {
            [cbLStyle toggleCheckedAt:checkboxPosition];
          }
        }
      } else {
        BOOL shouldAddTypingAttr =
            styleRange.location + styleRange.length == plainTextLength;
        [baseStyle add:styleRange
                withTyping:shouldAddTypingAttr
            withDirtyRange:YES];
      }
    }
  }
  [_input anyTextMayHaveBeenModified];
}

- (NSString *_Nullable)initiallyProcessHtml:(NSString *_Nonnull)html {
  return [HtmlParser initiallyProcessHtml:html
                        useHtmlNormalizer:_input->useHtmlNormalizer];
}

@end
