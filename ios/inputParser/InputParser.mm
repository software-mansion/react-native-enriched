#import "InputParser.h"
#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"
#import "UIView+React.h"
#import "TextInsertionUtils.h"
#import "StringExtension.h"

@implementation InputParser {
  EnrichedTextInputView *_input;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  return self;
}

- (NSString *)parseToHtmlFromRange:(NSRange)range {
  NSInteger offset = range.location;
  NSString *text = [_input->textView.textStorage.string substringWithRange:range];

  if(text.length == 0) {
    return @"<html>\n<p></p>\n</html>";
  }

  NSMutableString *result = [[NSMutableString alloc] initWithString: @"<html>"];
  NSSet<NSNumber *>*previousActiveStyles = [[NSSet<NSNumber *> alloc]init];
  BOOL newLine = YES;
  BOOL inUnorderedList = NO;
  BOOL inOrderedList = NO;
  BOOL inBlockQuote = NO;
  unichar lastCharacter = 0;
  
  for(int i = 0; i < text.length; i++) {
    NSRange currentRange = NSMakeRange(offset + i, 1);
    NSMutableSet<NSNumber *>*currentActiveStyles = [[NSMutableSet<NSNumber *> alloc]init];
    NSMutableDictionary *currentActiveStylesBeginning = [[NSMutableDictionary alloc] init];
    
    // check each existing style existence
    for(NSNumber* type in _input->stylesDict) {
      id<BaseStyleProtocol> style = _input->stylesDict[type];
      if([style detectStyle:currentRange]) {
        [currentActiveStyles addObject:type];
        
        if(![previousActiveStyles member:type]) {
          currentActiveStylesBeginning[type] = [NSNumber numberWithInt:i];
        }
      } else if([previousActiveStyles member:type]) {
        [currentActiveStylesBeginning removeObjectForKey:type];
      }
    }
    
    NSString *currentCharacterStr = [_input->textView.textStorage.string substringWithRange:currentRange];
    unichar currentCharacterChar = [_input->textView.textStorage.string characterAtIndex:currentRange.location];
    
    if([[NSCharacterSet newlineCharacterSet] characterIsMember:currentCharacterChar]) {
      if(newLine) {
        // we can either have an empty list item OR need to close the list and put a BR in such a situation
        // the existence of the list must be checked on 0 length range, not on the newline character
        if(inOrderedList) {
          OrderedListStyle *oStyle = _input->stylesDict[@(OrderedList)];
          BOOL detected = [oStyle detectStyle: NSMakeRange(currentRange.location, 0)];
          if(detected) {
            [result appendString:@"\n<li></li>"];
          } else {
            [result appendString:@"\n</ol>\n<br>"];
            inOrderedList = NO;
          }
        } else if(inUnorderedList) {
          UnorderedListStyle *uStyle = _input->stylesDict[@(UnorderedList)];
          BOOL detected = [uStyle detectStyle: NSMakeRange(currentRange.location, 0)];
          if(detected) {
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
        NSArray<NSNumber*> *sortedEndedStyles = [previousActiveStyles sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"intValue" ascending:NO]]];
        
        // append closing tags
        for(NSNumber *style in sortedEndedStyles) {
          NSString *tagContent = [self tagContentForStyle:style openingTag:NO location:currentRange.location];
          [result appendString: [NSString stringWithFormat:@"</%@>", tagContent]];
        }
        
        // append closing paragraph tag
        if([previousActiveStyles containsObject:@([UnorderedListStyle getStyleType])] ||
           [previousActiveStyles containsObject:@([OrderedListStyle getStyleType])] ||
           [previousActiveStyles containsObject:@([H1Style getStyleType])] ||
           [previousActiveStyles containsObject:@([H2Style getStyleType])] ||
           [previousActiveStyles containsObject:@([H3Style getStyleType])] ||
           [previousActiveStyles containsObject:@([BlockQuoteStyle getStyleType])]
        ) {
          // do nothing, proper closing paragraph tags have been already appended
        } else {
          [result appendString:@"</p>"];
        }
      }
      
      // clear the previous styles
      previousActiveStyles = [[NSSet<NSNumber *> alloc]init];
      
      // next character opens new paragraph
      newLine = YES;
    } else {
      // new line - open the paragraph
      if(newLine) {
        newLine = NO;
        
        // handle ending unordered list
        if(inUnorderedList && ![currentActiveStyles containsObject:@([UnorderedListStyle getStyleType])]) {
          inUnorderedList = NO;
          [result appendString:@"\n</ul>"];
        }
        // handle ending ordered list
        if(inOrderedList && ![currentActiveStyles containsObject:@([OrderedListStyle getStyleType])]) {
          inOrderedList = NO;
          [result appendString:@"\n</ol>"];
        }
        // handle ending blockquotes
        if(inBlockQuote && ![currentActiveStyles containsObject:@([BlockQuoteStyle getStyleType])]) {
          inBlockQuote = NO;
          [result appendString:@"\n</blockquote>"];
        }
        
        // handle starting unordered list
        if(!inUnorderedList && [currentActiveStyles containsObject:@([UnorderedListStyle getStyleType])]) {
          inUnorderedList = YES;
          [result appendString:@"\n<ul>"];
        }
        // handle starting ordered list
        if(!inOrderedList && [currentActiveStyles containsObject:@([OrderedListStyle getStyleType])]) {
          inOrderedList = YES;
          [result appendString:@"\n<ol>"];
        }
        // handle starting blockquotes
        if(!inBlockQuote && [currentActiveStyles containsObject:@([BlockQuoteStyle getStyleType])]) {
          inBlockQuote = YES;
          [result appendString:@"\n<blockquote>"];
        }
        
        // don't add the <p> tag if some paragraph styles are present
        if([currentActiveStyles containsObject:@([UnorderedListStyle getStyleType])] ||
           [currentActiveStyles containsObject:@([OrderedListStyle getStyleType])] ||
           [currentActiveStyles containsObject:@([H1Style getStyleType])] ||
           [currentActiveStyles containsObject:@([H2Style getStyleType])] ||
           [currentActiveStyles containsObject:@([H3Style getStyleType])] ||
           [currentActiveStyles containsObject:@([BlockQuoteStyle getStyleType])]
        ) {
          [result appendString:@"\n"];
        } else {
          [result appendString:@"\n<p>"];
        }
      }
    
      // get styles that have ended
      NSMutableSet<NSNumber *> *endedStyles = [previousActiveStyles mutableCopy];
      [endedStyles minusSet: currentActiveStyles];
      
      // also finish styles that should be ended becasue they are nested in a style that ended
      NSMutableSet *fixedEndedStyles = [endedStyles mutableCopy];
      NSMutableSet *stylesToBeReAdded = [[NSMutableSet alloc] init];
      
      for(NSNumber *style in endedStyles) {
        NSInteger styleBeginning = [currentActiveStylesBeginning[style] integerValue];
        
        for(NSNumber *activeStyle in currentActiveStyles) {
          NSInteger activeStyleBeginning = [currentActiveStylesBeginning[activeStyle] integerValue];
                  
          // we end the styles that began after the currently ended style but not at the "i" (cause the old style ended at exactly "i-1"
          // also the ones that began in the exact same place but are "inner" in relation to them due to StyleTypeEnum integer values
          
          if((activeStyleBeginning > styleBeginning && activeStyleBeginning < i) ||
             (activeStyleBeginning == styleBeginning && activeStyleBeginning < i && [activeStyle integerValue]  > [style integerValue])) {
            [fixedEndedStyles addObject:activeStyle];
            [stylesToBeReAdded addObject:activeStyle];
          }
        }
      }
      
      // they are sorted in a descending order
      NSArray<NSNumber*> *sortedEndedStyles = [fixedEndedStyles sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"intValue" ascending:NO]]];
      
      // append closing tags
      for(NSNumber *style in sortedEndedStyles) {
        NSString *tagContent = [self tagContentForStyle:style openingTag:NO location:currentRange.location];
        [result appendString: [NSString stringWithFormat:@"</%@>", tagContent]];
      }
      
      // get styles that have begun: they are sorted in a ascending manner to properly keep tags' FILO order
      NSMutableSet<NSNumber *> *newStyles = [currentActiveStyles mutableCopy];
      [newStyles minusSet: previousActiveStyles];
      [newStyles unionSet: stylesToBeReAdded];
      NSArray<NSNumber*> *sortedNewStyles = [newStyles sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"intValue" ascending:YES]]];
      
      // append opening tags
      for(NSNumber *style in sortedNewStyles) {
        NSString *tagContent = [self tagContentForStyle:style openingTag:YES location:currentRange.location];
        [result appendString: [NSString stringWithFormat:@"<%@>", tagContent]];
      }
      
      // append the letter and escape it if needed
      [result appendString: [NSString stringByEscapingHtml:currentCharacterStr]];
      
      // save current styles for next character's checks
      previousActiveStyles = currentActiveStyles;
    }
    
    // set last character
    lastCharacter = currentCharacterChar;
  }
  
  if(![[NSCharacterSet newlineCharacterSet] characterIsMember:lastCharacter]) {
    // not-newline character was last - finish the paragraph
    // close all pending tags
    NSArray<NSNumber*> *sortedEndedStyles = [previousActiveStyles sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"intValue" ascending:NO]]];
      
    // append closing tags
    for(NSNumber *style in sortedEndedStyles) {
      NSString *tagContent = [self tagContentForStyle:style openingTag:NO location:_input->textView.textStorage.string.length - 1];
      [result appendString: [NSString stringWithFormat:@"</%@>", tagContent]];
    }
    
    // finish the paragraph
    // handle ending of some paragraph styles
    if([previousActiveStyles containsObject:@([UnorderedListStyle getStyleType])]) {
      [result appendString:@"\n</ul>"];
    } else if([previousActiveStyles containsObject:@([OrderedListStyle getStyleType])]) {
      [result appendString:@"\n</ol>"];
    } else if([previousActiveStyles containsObject:@([BlockQuoteStyle getStyleType])]) {
      [result appendString:@"\n</blockquote>"];
    } else if(
      [previousActiveStyles containsObject:@([H1Style getStyleType])] ||
      [previousActiveStyles containsObject:@([H2Style getStyleType])] ||
      [previousActiveStyles containsObject:@([H3Style getStyleType])]
    ) {
      // do nothing, heading closing tag has already ben appended
    } else {
      [result appendString:@"</p>"];
    }
  } else {
    // newline character was last - some paragraph styles need to be closed
    if(inUnorderedList) {
      inUnorderedList = NO;
      [result appendString:@"\n</ul>"];
    }
    if(inOrderedList) {
      inOrderedList = NO;
      [result appendString:@"\n</ol>"];
    }
    if(inBlockQuote) {
      inBlockQuote = NO;
      [result appendString:@"\n</blockquote>"];
    }
  }
  
  [result appendString: @"\n</html>"];
  
  // remove zero width spaces in the very end
  NSRange resultRange = NSMakeRange(0, result.length);
  [result replaceOccurrencesOfString:@"\u200B" withString:@"" options:0 range:resultRange];
  return result;
}

- (NSString *)tagContentForStyle:(NSNumber *)style openingTag:(BOOL)openingTag location:(NSInteger)location {
  if([style isEqualToNumber: @([BoldStyle getStyleType])]) {
    return @"b";
  } else if([style isEqualToNumber: @([ItalicStyle getStyleType])]) {
    return @"i";
  } else if([style isEqualToNumber: @([UnderlineStyle getStyleType])]) {
    return @"u";
  } else if([style isEqualToNumber: @([StrikethroughStyle getStyleType])]) {
    return @"s";
  } else if([style isEqualToNumber: @([InlineCodeStyle getStyleType])]) {
    return @"code";
  } else if([style isEqualToNumber: @([LinkStyle getStyleType])]) {
    if(openingTag) {
      LinkStyle *linkStyle = (LinkStyle *)_input->stylesDict[@([LinkStyle getStyleType])];
      if(linkStyle != nullptr) {
        LinkData *data = [linkStyle getLinkDataAt: location];
        if(data != nullptr && data.url != nullptr) {
          return [NSString stringWithFormat:@"a href=\"%@\"", data.url];
        }
      }
      return @"a";
    } else {
      return @"a";
    }
  } else if([style isEqualToNumber: @([MentionStyle getStyleType])]) {
    if(openingTag) {
      MentionStyle *mentionStyle = (MentionStyle *)_input->stylesDict[@([MentionStyle getStyleType])];
      if(mentionStyle != nullptr) {
        MentionParams *params = [mentionStyle getMentionParamsAt:location];
        // attributes can theoretically be nullptr
        if(params != nullptr && params.indicator != nullptr && params.text != nullptr) {
          NSMutableString *attrsStr = [[NSMutableString alloc] initWithString: @""];
          if(params.attributes != nullptr) {
            // turn attributes to Data and then into dict
            NSData *attrsData = [params.attributes dataUsingEncoding:NSUTF8StringEncoding];
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:attrsData
              options:0
              error:&jsonError
            ];
            // format dict keys and values into string
            [json enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
              [attrsStr appendString: [NSString stringWithFormat:@" %@=\"%@\"", (NSString *)key, (NSString *)obj]];
            }];
          }
          return [NSString stringWithFormat:@"mention text=\"%@\" indicator=\"%@\"%@", params.text, params.indicator, attrsStr];
        }
      }
      return @"mention";
    } else {
      return @"mention";
    }
  } else if([style isEqualToNumber:@([H1Style getStyleType])]) {
    return @"h1";
  } else if([style isEqualToNumber:@([H2Style getStyleType])]) {
    return @"h2";
  } else if([style isEqualToNumber:@([H3Style getStyleType])]) {
    return @"h3";
  } else if([style isEqualToNumber:@([UnorderedListStyle getStyleType])] || [style isEqualToNumber:@([OrderedListStyle getStyleType])]) {
    return @"li";
  } else if([style isEqualToNumber:@([BlockQuoteStyle getStyleType])]) {
    // blockquotes use <p> tags the same way lists use <li>
    return @"p";
  }
  return @"";
}

- (void)replaceWholeFromHtml:(NSString * _Nonnull)html {
  NSArray *processingResult = [self getTextAndStylesFromHtml:html];
  NSString *plainText = (NSString *)processingResult[0];
  NSArray *stylesInfo = (NSArray *)processingResult[1];
  
  // reset the text first and reset typing attributes
  _input->textView.text = @"";
  _input->textView.typingAttributes = _input->defaultTypingAttributes;
  
  // set new text
  _input->textView.text = plainText;
  
  // re-apply the styles
  [self applyProcessedStyles:stylesInfo offsetFromBeginning:0];
}

- (void)replaceFromHtml:(NSString * _Nonnull)html range:(NSRange)range {
  NSArray *processingResult = [self getTextAndStylesFromHtml:html];
  NSString *plainText = (NSString *)processingResult[0];
  NSArray *stylesInfo = (NSArray *)processingResult[1];
  
  // we can use ready replace util
  [TextInsertionUtils replaceText:plainText at:range additionalAttributes:nil input:_input withSelection:YES];
  
  [self applyProcessedStyles:stylesInfo offsetFromBeginning:range.location];
}

- (void)insertFromHtml:(NSString * _Nonnull)html location:(NSInteger)location {
  NSArray *processingResult = [self getTextAndStylesFromHtml:html];
  NSString *plainText = (NSString *)processingResult[0];
  NSArray *stylesInfo = (NSArray *)processingResult[1];
  
  // same here, insertion utils got our back
  [TextInsertionUtils insertText:plainText at:location additionalAttributes:nil input:_input withSelection:YES];
  
  [self applyProcessedStyles:stylesInfo offsetFromBeginning:location];
}

- (void)applyProcessedStyles:(NSArray *)processedStyles offsetFromBeginning:(NSInteger)offset {
  for(NSArray* arr in processedStyles) {
    // unwrap all info from processed style
    NSNumber *styleType = (NSNumber *)arr[0];
    StylePair *stylePair = (StylePair *)arr[1];
    id<BaseStyleProtocol> baseStyle = _input->stylesDict[styleType];
    // range must be taking offest into consideration because processed styles' ranges are relative to only the new text
    // while we need absolute ranges relative to the whole existing text
    NSRange styleRange = NSMakeRange(offset + [stylePair.rangeValue rangeValue].location, [stylePair.rangeValue rangeValue].length);
    
    // of course any changes here need to take blocks and conflicts into consideration
    if([_input handleStyleBlocksAndConflicts:[[baseStyle class] getStyleType] range:styleRange]) {
      if([styleType isEqualToNumber: @([LinkStyle getStyleType])]) {
        NSString *text = [_input->textView.textStorage.string substringWithRange:styleRange];
        NSString *url = (NSString *)stylePair.styleValue;
        BOOL isManual = ![text isEqualToString:url];
        [((LinkStyle *)baseStyle) addLink:text url:url range:styleRange manual:isManual];
      } else if([styleType isEqualToNumber: @([MentionStyle getStyleType])]) {
        MentionParams *params = (MentionParams *)stylePair.styleValue;
        [((MentionStyle *)baseStyle) addMentionAtRange:styleRange params:params];
      } else {
        [baseStyle addAttributes:styleRange];
      }
    }
  }
  [_input anyTextMayHaveBeenModified];
}

- (NSString * _Nullable)initiallyProcessHtml:(NSString * _Nonnull)html {
  NSString *fixedHtml = nullptr;
  
  if(html.length >= 13) {
    NSString *firstSix = [html substringWithRange:NSMakeRange(0, 6)];
    NSString *lastSeven = [html substringWithRange:NSMakeRange(html.length-7, 7)];
    
    if([firstSix isEqualToString:@"<html>"] && [lastSeven isEqualToString:@"</html>"]) {
      // remove html tags, might be with newlines or without them
      fixedHtml = [html copy];
      // firstly remove newlined html tags if any:
      fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"<html>\n" withString:@""];
      fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"\n</html>" withString:@""];
      // fallback; remove html tags without their newlines
      fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"<html>" withString:@""];
      fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"</html>" withString:@""];
    } else {
      // in other case we are most likely working with some external html - try getting the styles from between body tags
      NSRange openingBodyRange = [html rangeOfString:@"<body>"];
      NSRange closingBodyRange = [html rangeOfString:@"</body>"];
      
      if(openingBodyRange.length != 0 && closingBodyRange.length != 0) {
        NSInteger newStart = openingBodyRange.location + 7;
        NSInteger newEnd = closingBodyRange.location - 1;
        fixedHtml = [html substringWithRange:NSMakeRange(newStart, newEnd - newStart + 1)];
      }
    }
  }
  
  // second processing - try fixing htmls with wrong newlines' setup
  if(fixedHtml != nullptr) {
    // add <br> tag wherever needed
    fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"<p></p>" withString:@"<br>"];
    
    // remove <p> tags inside of <li>
    fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"<li><p>" withString:@"<li>"];
    fixedHtml = [fixedHtml stringByReplacingOccurrencesOfString:@"</p></li>" withString:@"</li>"];
    
    // tags that have to be in separate lines
    fixedHtml = [self stringByAddingNewlinesToTag:@"<br>" inString:fixedHtml leading:YES trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<ul>" inString:fixedHtml leading:YES trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"</ul>" inString:fixedHtml leading:YES trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<ol>" inString:fixedHtml leading:YES trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"</ol>" inString:fixedHtml leading:YES trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<blockquote>" inString:fixedHtml leading:YES trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"</blockquote>" inString:fixedHtml leading:YES trailing:YES];
    
    // line opening tags
    fixedHtml = [self stringByAddingNewlinesToTag:@"<p>" inString:fixedHtml leading:YES trailing:NO];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<li>" inString:fixedHtml leading:YES trailing:NO];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<h1>" inString:fixedHtml leading:YES trailing:NO];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<h2>" inString:fixedHtml leading:YES trailing:NO];
    fixedHtml = [self stringByAddingNewlinesToTag:@"<h3>" inString:fixedHtml leading:YES trailing:NO];
    
    // line closing tags
    fixedHtml = [self stringByAddingNewlinesToTag:@"</p>" inString:fixedHtml leading:NO trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"</li>" inString:fixedHtml leading:NO trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"</h1>" inString:fixedHtml leading:NO trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"</h2>" inString:fixedHtml leading:NO trailing:YES];
    fixedHtml = [self stringByAddingNewlinesToTag:@"</h3>" inString:fixedHtml leading:NO trailing:YES];
  }
  
  return fixedHtml;
}

- (NSString *)stringByAddingNewlinesToTag:(NSString *)tag inString:(NSString *)html leading:(BOOL)leading trailing:(BOOL)trailing {
  NSString *str = [html copy];
  if(leading) {
    NSString *formattedTag = [NSString stringWithFormat:@">%@", tag];
    NSString *formattedNewTag = [NSString stringWithFormat:@">\n%@", tag];
    str = [str stringByReplacingOccurrencesOfString:formattedTag withString:formattedNewTag];
  }
  if(trailing) {
    NSString *formattedTag = [NSString stringWithFormat:@"%@<", tag];
    NSString *formattedNewTag = [NSString stringWithFormat:@"%@\n<", tag];
    str = [str stringByReplacingOccurrencesOfString:formattedTag withString:formattedNewTag];
  }
  return str;
}

- (NSArray *)getTextAndStylesFromHtml:(NSString *)fixedHtml {
  NSMutableString *plainText = [[NSMutableString alloc] initWithString: @""];
  NSMutableDictionary *ongoingTags = [[NSMutableDictionary alloc] init];
  NSMutableArray *initiallyProcessedTags = [[NSMutableArray alloc] init];
  BOOL insideTag = NO;
  BOOL gettingTagName = NO;
  BOOL gettingTagParams = NO;
  BOOL closingTag = NO;
  NSMutableString *currentTagName = [[NSMutableString alloc] initWithString:@""];
  NSMutableString *currentTagParams = [[NSMutableString alloc] initWithString:@""];
  NSDictionary *htmlEntitiesDict = [NSString getEscapedCharactersInfoFrom:fixedHtml];
  
  // firstly, extract text and initially processed tags
  for(int i = 0; i < fixedHtml.length; i++) {
    NSString *currentCharacterStr = [fixedHtml substringWithRange:NSMakeRange(i, 1)];
    unichar currentCharacterChar = [fixedHtml characterAtIndex:i];
    
    if(currentCharacterChar == '<') {
      // opening the tag, mark that we are inside and getting its name
      insideTag = YES;
      gettingTagName = YES;
    } else if(currentCharacterChar == '>') {
      // finishing some tag, no longer marked as inside or getting its name/params
      insideTag = NO;
      gettingTagName = NO;
      gettingTagParams = NO;
      
      if([currentTagName isEqualToString:@"p"] || [currentTagName isEqualToString:@"br"] || [currentTagName isEqualToString:@"li"]) {
        // do nothing, we don't include these tags in styles
      } else if(!closingTag) {
        // we finish opening tag - get its location and optionally params and put them under tag name key in ongoingTags
        NSMutableArray *tagArr = [[NSMutableArray alloc] init];
        [tagArr addObject:[NSNumber numberWithInteger:plainText.length]];
        if(currentTagParams.length > 0) {
          [tagArr addObject:[currentTagParams copy]];
        }
        ongoingTags[currentTagName] = tagArr;
        
        // skip one newline after opening tags that are in separate lines intentionally
        if([currentTagName isEqualToString:@"ul"] || [currentTagName isEqualToString:@"ol"] || [currentTagName isEqualToString:@"blockquote"]) {
          i += 1;
        }
      } else {
        // we finish closing tags - pack tag name, tag range and optionally tag params into an entry that goes inside initiallyProcessedTags
        
        // skip one newline that was added before some closing tags that are in separate lines
        if([currentTagName isEqualToString:@"ul"] || [currentTagName isEqualToString:@"ol"] || [currentTagName isEqualToString:@"blockquote"]) {
          plainText = [[plainText substringWithRange: NSMakeRange(0, plainText.length - 1)] mutableCopy];
        }
        
        NSMutableArray *tagEntry = [[NSMutableArray alloc] init];
      
        NSArray *tagData = ongoingTags[currentTagName];
        NSInteger tagLocation = [((NSNumber *)tagData[0]) intValue];
        NSRange tagRange = NSMakeRange(tagLocation, plainText.length - tagLocation);
        
        [tagEntry addObject:[currentTagName copy]];
        [tagEntry addObject:[NSValue valueWithRange:tagRange]];
        if(tagData.count > 1) {
          [tagEntry addObject:[(NSString *)tagData[1] copy]];
        }
        
        [initiallyProcessedTags addObject:tagEntry];
        [ongoingTags removeObjectForKey:currentTagName];
      }
      // post-tag cleanup
      closingTag = NO;
      currentTagName = [[NSMutableString alloc] initWithString:@""];
      currentTagParams = [[NSMutableString alloc] initWithString:@""];
    } else {
      if(!insideTag) {
        // no tags logic - just append the right text
        
        // html entity on the index; use unescaped character and forward iterator accordingly
        NSArray *entityInfo = htmlEntitiesDict[@(i)];
        if(entityInfo != nullptr) {
          NSString *escaped = entityInfo[0];
          NSString *unescaped = entityInfo[1];
          [plainText appendString:unescaped];
          // the iterator will forward by 1 itself
          i += escaped.length - 1;
        } else {
          [plainText appendString:currentCharacterStr];
        }
      } else {
        if(gettingTagName) {
          if(currentCharacterChar == ' ') {
            // no longer getting tag name - switch to params
            gettingTagName = NO;
            gettingTagParams = YES;
          } else if(currentCharacterChar == '/') {
            // mark that the tag is closing
            closingTag = YES;
          } else {
            // append next tag char
            [currentTagName appendString:currentCharacterStr];
          }
        } else if(gettingTagParams) {
          // append next tag params char
          [currentTagParams appendString:currentCharacterStr];
        }
      }
    }
  }
  
  // process tags into proper StyleType + StylePair values
  NSMutableArray *processedStyles = [[NSMutableArray alloc] init];
  
  for(NSArray* arr in initiallyProcessedTags) {
    NSString *tagName = (NSString *)arr[0];
    NSValue *tagRangeValue = (NSValue *)arr[1];
    NSMutableString *params = [[NSMutableString alloc] initWithString:@""];
    if(arr.count > 2) {
      [params appendString:(NSString *)arr[2]];
    }
    
    NSMutableArray *styleArr = [[NSMutableArray alloc] init];
    StylePair *stylePair = [[StylePair alloc] init];
    if([tagName isEqualToString:@"b"]) {
      [styleArr addObject:@([BoldStyle getStyleType])];
    } else if([tagName isEqualToString:@"i"]) {
      [styleArr addObject:@([ItalicStyle getStyleType])];
    } else if([tagName isEqualToString:@"u"]) {
      [styleArr addObject:@([UnderlineStyle getStyleType])];
    } else if([tagName isEqualToString:@"s"]) {
      [styleArr addObject:@([StrikethroughStyle getStyleType])];
    } else if([tagName isEqualToString:@"code"]) {
      [styleArr addObject:@([InlineCodeStyle getStyleType])];
    } else if([tagName isEqualToString:@"a"]) {
      NSRegularExpression *hrefRegex = [NSRegularExpression regularExpressionWithPattern:@"href=\".+\""
        options:0
        error:nullptr
      ];
      NSTextCheckingResult* match = [hrefRegex firstMatchInString:params options:0 range: NSMakeRange(0, params.length)];
      
      if(match == nullptr) {
        // same as on Android, no href (or empty href) equals no link style
        continue;
      }
      
      NSRange hrefRange = match.range;
      [styleArr addObject:@([LinkStyle getStyleType])];
      NSString *url = [params substringWithRange:NSMakeRange(hrefRange.location + 6, hrefRange.length - 7)];
      stylePair.styleValue = url;
    } else if([tagName isEqualToString:@"mention"]) {
      [styleArr addObject:@([MentionStyle getStyleType])];
      // extract html expression into dict using some regex
      NSMutableDictionary *paramsDict = [[NSMutableDictionary alloc] init];
      NSString *pattern = @"(\\w+)=\"([^\"]*)\"";
      NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
      
      [regex enumerateMatchesInString:params options:0 range:NSMakeRange(0,params.length)
        usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
          if(result.numberOfRanges == 3) {
            NSString *key = [params substringWithRange:[result rangeAtIndex:1]];
            NSString *value = [params substringWithRange:[result rangeAtIndex:2]];
            paramsDict[key] = value;
          }
        }
      ];
      
      MentionParams *mentionParams = [[MentionParams alloc] init];
      mentionParams.text = paramsDict[@"text"];
      mentionParams.indicator = paramsDict[@"indicator"];
      
      [paramsDict removeObjectsForKeys:@[@"text", @"indicator"]];
      NSError *error;
      NSData *attrsData = [NSJSONSerialization dataWithJSONObject:paramsDict options:0 error:&error];
      NSString *formattedAttrsString = [[NSString alloc] initWithData:attrsData encoding:NSUTF8StringEncoding];
      mentionParams.attributes = formattedAttrsString;
      
      stylePair.styleValue = mentionParams;
    } else if([[tagName substringWithRange:NSMakeRange(0, 1)] isEqualToString: @"h"]) {
      if([tagName isEqualToString:@"h1"]) {
        [styleArr addObject:@([H1Style getStyleType])];
      } else if([tagName isEqualToString:@"h2"]) {
        [styleArr addObject:@([H2Style getStyleType])];
      } else if([tagName isEqualToString:@"h3"]) {
        [styleArr addObject:@([H3Style getStyleType])];
      }
    } else if([tagName isEqualToString:@"ul"]) {
      [styleArr addObject:@([UnorderedListStyle getStyleType])];
    } else if([tagName isEqualToString:@"ol"]) {
      [styleArr addObject:@([OrderedListStyle getStyleType])];
    } else if([tagName isEqualToString:@"blockquote"]) {
      [styleArr addObject:@([BlockQuoteStyle getStyleType])];
    } else {
      // some other external tags like span just don't get put into the processed styles
      continue;
    }
    
    stylePair.rangeValue = tagRangeValue;
    [styleArr addObject:stylePair];
    [processedStyles addObject:styleArr];
  }
  
  return @[plainText, processedStyles];
}

@end
