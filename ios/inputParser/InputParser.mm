#import "InputParser.h"
#import "EnrichedTextInputView.h"
#import "StringExtension.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"
#import "UIView+React.h"

@implementation InputParser {
  EnrichedTextInputView *_input;
  NSInteger _precedingImageCount;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  _precedingImageCount = 0;
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
              [bqStyle detectStyle:NSMakeRange(currentRange.location, 0)];
          if (detected) {
            [result appendString:@"\n<br>"];
          } else {
            [result appendString:@"\n</blockquote>\n<br>"];
            inBlockQuote = NO;
          }
        } else if (inCodeBlock) {
          CodeBlockStyle *cbStyle = _input->stylesDict[@(CodeBlock)];
          BOOL detected =
              [cbStyle detectStyle:NSMakeRange(currentRange.location, 0)];
          if (detected) {
            [result appendString:@"\n<br>"];
          } else {
            [result appendString:@"\n</codeblock>\n<br>"];
            inCodeBlock = NO;
          }
        } else if (inCheckboxList) {
          CheckboxListStyle *cbLStyle = _input->stylesDict[@(CheckboxList)];
          BOOL detected =
              [cbLStyle detectStyle:NSMakeRange(currentRange.location, 0)];
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
                containsObject:@([UnorderedListStyle getType])] ||
            [previousActiveStyles
                containsObject:@([OrderedListStyle getStyleType])] ||
            [previousActiveStyles containsObject:@([H1Style getStyleType])] ||
            [previousActiveStyles containsObject:@([H2Style getStyleType])] ||
            [previousActiveStyles containsObject:@([H3Style getStyleType])] ||
            [previousActiveStyles containsObject:@([H4Style getStyleType])] ||
            [previousActiveStyles containsObject:@([H5Style getStyleType])] ||
            [previousActiveStyles containsObject:@([H6Style getStyleType])] ||
            [previousActiveStyles
                containsObject:@([BlockQuoteStyle getStyleType])] ||
            [previousActiveStyles
                containsObject:@([CodeBlockStyle getStyleType])] ||
            [previousActiveStyles
                containsObject:@([CheckboxListStyle getStyleType])]) {
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
        // handle ending checkbox list
        if (inCheckboxList &&
            ![currentActiveStyles
                containsObject:@([CheckboxListStyle getStyleType])]) {
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
        // handle starting checkbox list
        if (!inCheckboxList &&
            [currentActiveStyles
                containsObject:@([CheckboxListStyle getStyleType])]) {
          inCheckboxList = YES;
          [result appendString:@"\n<ul data-type=\"checkbox\">"];
        }

        // don't add the <p> tag if some paragraph styles are present
        if ([currentActiveStyles
                containsObject:@([UnorderedListStyle getType])] ||
            [currentActiveStyles
                containsObject:@([OrderedListStyle getStyleType])] ||
            [currentActiveStyles containsObject:@([H1Style getStyleType])] ||
            [currentActiveStyles containsObject:@([H2Style getStyleType])] ||
            [currentActiveStyles containsObject:@([H3Style getStyleType])] ||
            [currentActiveStyles containsObject:@([H4Style getStyleType])] ||
            [currentActiveStyles containsObject:@([H5Style getStyleType])] ||
            [currentActiveStyles containsObject:@([H6Style getStyleType])] ||
            [currentActiveStyles
                containsObject:@([BlockQuoteStyle getStyleType])] ||
            [currentActiveStyles
                containsObject:@([CodeBlockStyle getStyleType])] ||
            [currentActiveStyles
                containsObject:@([CheckboxListStyle getStyleType])]) {
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
    if ([previousActiveStyles containsObject:@([UnorderedListStyle getType])]) {
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
                   containsObject:@([CheckboxListStyle getStyleType])]) {
      [result appendString:@"\n</ul>"];
    } else if ([previousActiveStyles
                   containsObject:@([H1Style getStyleType])] ||
               [previousActiveStyles
                   containsObject:@([H2Style getStyleType])] ||
               [previousActiveStyles
                   containsObject:@([H3Style getStyleType])] ||
               [previousActiveStyles
                   containsObject:@([H4Style getStyleType])] ||
               [previousActiveStyles
                   containsObject:@([H5Style getStyleType])] ||
               [previousActiveStyles
                   containsObject:@([H6Style getStyleType])]) {
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
  if ([style isEqualToNumber:@([BoldStyle getStyleType])]) {
    return @"b";
  } else if ([style isEqualToNumber:@([ItalicStyle getType])]) {
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
  } else if ([style isEqualToNumber:@([StrikethroughStyle getType])]) {
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
  } else if ([style isEqualToNumber:@([H4Style getStyleType])]) {
    return @"h4";
  } else if ([style isEqualToNumber:@([H5Style getStyleType])]) {
    return @"h5";
  } else if ([style isEqualToNumber:@([H6Style getStyleType])]) {
    return @"h6";
  } else if ([style isEqualToNumber:@([UnorderedListStyle getType])] ||
             [style isEqualToNumber:@([OrderedListStyle getStyleType])]) {
    return @"li";
  } else if ([style isEqualToNumber:@([CheckboxListStyle getStyleType])]) {
    if (openingTag) {
      CheckboxListStyle *checkboxListStyleClass =
          (CheckboxListStyle *)
              _input->stylesDict[@([CheckboxListStyle getStyleType])];
      BOOL checked = [checkboxListStyleClass getCheckboxStateAt:location];

      if (checked) {
        return @"li checked";
      }
      return @"li";
    } else {
      return @"li";
    }
  } else if ([style isEqualToNumber:@([BlockQuoteStyle getStyleType])] ||
             [style isEqualToNumber:@([CodeBlockStyle getStyleType])]) {
    // blockquotes and codeblock use <p> tags the same way lists use <li>
    return @"p";
  }
  return @"";
}

- (void)replaceWholeFromHtml:(NSString *_Nonnull)html {
  NSArray *processingResult = [self getTextAndStylesFromHtml:html];
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
  NSArray *processingResult = [self getTextAndStylesFromHtml:html];
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
  NSArray *processingResult = [self getTextAndStylesFromHtml:html];
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
    id<BaseStyleProtocol> baseStyle = _input->stylesDict[styleType];
    // range must be taking offest into consideration because processed styles'
    // ranges are relative to only the new text while we need absolute ranges
    // relative to the whole existing text
    NSRange styleRange =
        NSMakeRange(offset + [stylePair.rangeValue rangeValue].location,
                    [stylePair.rangeValue rangeValue].length);

    // of course any changes here need to take blocks and conflicts into
    // consideration
    if ([_input handleStyleBlocksAndConflicts:[[baseStyle class] getStyleType]
                                        range:styleRange]) {
      if ([styleType isEqualToNumber:@([LinkStyle getStyleType])]) {
        NSString *text =
            [_input->textView.textStorage.string substringWithRange:styleRange];
        NSString *url = (NSString *)stylePair.styleValue;
        BOOL isManual = ![text isEqualToString:url];
        [((LinkStyle *)baseStyle) addLink:text
                                      url:url
                                    range:styleRange
                                   manual:isManual
                            withSelection:NO];
      } else if ([styleType isEqualToNumber:@([MentionStyle getStyleType])]) {
        MentionParams *params = (MentionParams *)stylePair.styleValue;
        [((MentionStyle *)baseStyle) addMentionAtRange:styleRange
                                                params:params];
      } else if ([styleType isEqualToNumber:@([ImageStyle getStyleType])]) {
        ImageData *imgData = (ImageData *)stylePair.styleValue;
        [((ImageStyle *)baseStyle) addImageAtRange:styleRange
                                         imageData:imgData
                                     withSelection:NO];
      } else if ([styleType
                     isEqualToNumber:@([CheckboxListStyle getStyleType])]) {
        NSDictionary *checkboxStates = (NSDictionary *)stylePair.styleValue;
        CheckboxListStyle *cbLStyle = (CheckboxListStyle *)baseStyle;

        // First apply the checkbox list style to the entire range with
        // unchecked value
        BOOL shouldAddTypingAttr =
            styleRange.location + styleRange.length == plainTextLength;
        [cbLStyle addAttributes:styleRange withTypingAttr:shouldAddTypingAttr];

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
        [baseStyle addAttributes:styleRange withTypingAttr:shouldAddTypingAttr];
      }
    }
  }
  [_input anyTextMayHaveBeenModified];
}

- (NSString *_Nullable)initiallyProcessHtml:(NSString *_Nonnull)html {
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
    } else {
      // in other case we are most likely working with some external html - try
      // getting the styles from between body tags
      NSRange openingBodyRange = [htmlWithoutSpaces rangeOfString:@"<body>"];
      NSRange closingBodyRange = [htmlWithoutSpaces rangeOfString:@"</body>"];

      if (openingBodyRange.length != 0 && closingBodyRange.length != 0) {
        NSInteger newStart = openingBodyRange.location + 7;
        NSInteger newEnd = closingBodyRange.location - 1;
        fixedHtml = [htmlWithoutSpaces
            substringWithRange:NSMakeRange(newStart, newEnd - newStart + 1)];
      }
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
- (NSString *)stripExtraWhiteSpacesAndNewlines:(NSString *)html {
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

- (void)finalizeTagEntry:(NSMutableString *)tagName
               ongoingTags:(NSMutableDictionary *)ongoingTags
    initiallyProcessedTags:(NSMutableArray *)processedTags
                 plainText:(NSMutableString *)plainText {
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
  // We add '_precedingImageCount' to shift the start index forward, aligning
  // this style's range with the actual position in the final text (where each
  // image adds 1 character).
  NSRange tagRange = NSMakeRange(tagLocation + _precedingImageCount,
                                 plainText.length - tagLocation);

  [tagEntry addObject:[tagName copy]];
  [tagEntry addObject:[NSValue valueWithRange:tagRange]];
  if (tagData.count > 1) {
    [tagEntry addObject:[(NSString *)tagData[1] copy]];
  }

  [processedTags addObject:tagEntry];
  [ongoingTags removeObjectForKey:tagName];

  if ([tagName isEqualToString:@"img"]) {
    _precedingImageCount++;
  }
}

- (NSArray *)getTextAndStylesFromHtml:(NSString *)fixedHtml {
  NSMutableString *plainText = [[NSMutableString alloc] initWithString:@""];
  NSMutableDictionary *ongoingTags = [[NSMutableDictionary alloc] init];
  NSMutableArray *initiallyProcessedTags = [[NSMutableArray alloc] init];
  NSMutableDictionary *checkboxStates = [[NSMutableDictionary alloc] init];
  BOOL insideCheckboxList = NO;
  _precedingImageCount = 0;
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

        // skip one newline after opening tags that are in separate lines
        // intentionally
        if ([currentTagName isEqualToString:@"ul"] ||
            [currentTagName isEqualToString:@"ol"] ||
            [currentTagName isEqualToString:@"blockquote"] ||
            [currentTagName isEqualToString:@"codeblock"]) {
          i += 1;
        }

        if (isSelfClosing) {
          [self finalizeTagEntry:currentTagName
                         ongoingTags:ongoingTags
              initiallyProcessedTags:initiallyProcessedTags
                           plainText:plainText];
        }
      } else {
        // we finish closing tags - pack tag name, tag range and optionally tag
        // params into an entry that goes inside initiallyProcessedTags

        // Check if we're closing a checkbox list by looking at the params
        if ([currentTagName isEqualToString:@"ul"] &&
            [self isUlCheckboxList:currentTagParams]) {
          insideCheckboxList = NO;
        }

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

        [self finalizeTagEntry:currentTagName
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
      [styleArr addObject:@([BoldStyle getStyleType])];
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
      [styleArr addObject:@([ImageStyle getStyleType])];
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
      [styleArr addObject:@([UnderlineStyle getStyleType])];
    } else if ([tagName isEqualToString:@"s"]) {
      [styleArr addObject:@([StrikethroughStyle getType])];
    } else if ([tagName isEqualToString:@"code"]) {
      [styleArr addObject:@([InlineCodeStyle getStyleType])];
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
      [styleArr addObject:@([LinkStyle getStyleType])];
      // cut only the url from the href="..." string
      NSString *url =
          [params substringWithRange:NSMakeRange(hrefRange.location + 6,
                                                 hrefRange.length - 7)];
      stylePair.styleValue = url;
    } else if ([tagName isEqualToString:@"mention"]) {
      [styleArr addObject:@([MentionStyle getStyleType])];
      // extract html expression into dict using some regex
      NSMutableDictionary *paramsDict = [[NSMutableDictionary alloc] init];
      NSString *pattern = @"(\\w+)=\"([^\"]*)\"";
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
                             if (result.numberOfRanges == 3) {
                               NSString *key = [params
                                   substringWithRange:[result rangeAtIndex:1]];
                               NSString *value = [params
                                   substringWithRange:[result rangeAtIndex:2]];
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
    } else if ([[tagName substringWithRange:NSMakeRange(0, 1)]
                   isEqualToString:@"h"]) {
      if ([tagName isEqualToString:@"h1"]) {
        [styleArr addObject:@([H1Style getStyleType])];
      } else if ([tagName isEqualToString:@"h2"]) {
        [styleArr addObject:@([H2Style getStyleType])];
      } else if ([tagName isEqualToString:@"h3"]) {
        [styleArr addObject:@([H3Style getStyleType])];
      } else if ([tagName isEqualToString:@"h4"]) {
        [styleArr addObject:@([H4Style getStyleType])];
      } else if ([tagName isEqualToString:@"h5"]) {
        [styleArr addObject:@([H5Style getStyleType])];
      } else if ([tagName isEqualToString:@"h6"]) {
        [styleArr addObject:@([H6Style getStyleType])];
      }
    } else if ([tagName isEqualToString:@"ul"]) {
      if ([self isUlCheckboxList:params]) {
        [styleArr addObject:@([CheckboxListStyle getStyleType])];
        stylePair.styleValue =
            [self prepareCheckboxListStyleValue:tagRangeValue
                                 checkboxStates:checkboxStates];
      } else {
        [styleArr addObject:@([UnorderedListStyle getType])];
      }
    } else if ([tagName isEqualToString:@"ol"]) {
      [styleArr addObject:@([OrderedListStyle getStyleType])];
    } else if ([tagName isEqualToString:@"blockquote"]) {
      [styleArr addObject:@([BlockQuoteStyle getStyleType])];
    } else if ([tagName isEqualToString:@"codeblock"]) {
      [styleArr addObject:@([CodeBlockStyle getStyleType])];
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

- (BOOL)isUlCheckboxList:(NSString *)params {
  return ([params containsString:@"data-type=\"checkbox\""] ||
          [params containsString:@"data-type='checkbox'"]);
}

- (NSDictionary *)prepareCheckboxListStyleValue:(NSValue *)rangeValue
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

@end
