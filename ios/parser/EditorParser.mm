#import "EditorParser.h"
#import "ReactNativeRichTextEditorView.h"
#import "StyleHeaders.h"
#import "UIView+React.h"
#import "TextInsertionUtils.h"

@implementation EditorParser {
  ReactNativeRichTextEditorView *_editor;
}

- (instancetype)initWithEditor:(id)editor {
  self = [super init];
  _editor = (ReactNativeRichTextEditorView *) editor;
  return self;
}

- (NSString *)parseToHtml {
  if(_editor->textView.textStorage.string.length == 0) {
    return @"";
  }

  NSMutableString *result = [[NSMutableString alloc] initWithString: @"<html>"];
  NSSet<NSNumber *>*previousActiveStyles = [[NSSet<NSNumber *> alloc]init];
  BOOL newLine = YES;
  BOOL inUnorderedList = NO;
  unichar lastCharacter = 0;
  
  for(int i = 0; i < _editor->textView.textStorage.length; i++) {
    NSRange currentRange = NSMakeRange(i, 1);
    NSMutableSet<NSNumber *>*currentActiveStyles = [[NSMutableSet<NSNumber *> alloc]init];
    
    // check each existing style existence
    for(NSNumber* type in _editor->stylesDict) {
      id<BaseStyleProtocol> style = _editor->stylesDict[type];
      if([style detectStyle:currentRange]) {
        [currentActiveStyles addObject: type];
      }
    }
    
    NSString *currentCharacterStr = [_editor->textView.textStorage.string substringWithRange:currentRange];
    unichar currentCharacterChar = [_editor->textView.textStorage.string characterAtIndex:currentRange.location];
    
    if([[NSCharacterSet newlineCharacterSet] characterIsMember:currentCharacterChar]) {
      // just an empty line - only br tag and no style tags
      if(newLine) {
        // keep the newLine at YES
        [result appendString:@"\n<br>"];
        continue;
      }
    
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
         [previousActiveStyles containsObject:@([H1Style getStyleType])] ||
         [previousActiveStyles containsObject:@([H2Style getStyleType])] ||
         [previousActiveStyles containsObject:@([H3Style getStyleType])]
      ) {
        // do nothing, proper closing paragraph tags have been already appended
      } else {
        [result appendString:@"</p>"];
      }
      
      // clear the previous styles
      previousActiveStyles = [[NSSet<NSNumber *> alloc]init];
      
      // next character opens new paragraph
      newLine = YES;
    } else {
      // new line - open the paragraph
      if(newLine) {
        newLine = NO;
        
        // handle ending lists
        if(inUnorderedList && ![currentActiveStyles containsObject:@([UnorderedListStyle getStyleType])]) {
          inUnorderedList = NO;
          [result appendString:@"\n</ul>"];
        }
        
        // handle starting lists
        if(!inUnorderedList && [currentActiveStyles containsObject:@([UnorderedListStyle getStyleType])]) {
          inUnorderedList = YES;
          [result appendString:@"\n<ul>"];
        }
        
        // don't add the <p> tag if paragraph styles are present
        if([currentActiveStyles containsObject:@([UnorderedListStyle getStyleType])] ||
           [currentActiveStyles containsObject:@([H1Style getStyleType])] ||
           [currentActiveStyles containsObject:@([H2Style getStyleType])] ||
           [currentActiveStyles containsObject:@([H3Style getStyleType])]
        ) {
          [result appendString:@"\n"];
        } else {
          [result appendString:@"\n<p>"];
        }
      }
    
      // get styles that have ended: they are sorted in an ascending manner
      NSMutableSet<NSNumber *> *endedStyles = [previousActiveStyles mutableCopy];
      [endedStyles minusSet: currentActiveStyles];
      NSArray<NSNumber*> *sortedEndedStyles = [endedStyles sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"intValue" ascending:NO]]];
      
      // append closing tags
      for(NSNumber *style in sortedEndedStyles) {
        NSString *tagContent = [self tagContentForStyle:style openingTag:NO location:currentRange.location];
        [result appendString: [NSString stringWithFormat:@"</%@>", tagContent]];
      }
      
      // get styles that have begun: they are sorted in a descending manner to properly keep tags' FILO order
      NSMutableSet<NSNumber *> *newStyles = [currentActiveStyles mutableCopy];
      [newStyles minusSet: previousActiveStyles];
      NSArray<NSNumber*> *sortedNewStyles = [newStyles sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"intValue" ascending:YES]]];
      
      // append opening tags
      for(NSNumber *style in sortedNewStyles) {
        NSString *tagContent = [self tagContentForStyle:style openingTag:YES location:currentRange.location];
        [result appendString: [NSString stringWithFormat:@"<%@>", tagContent]];
      }
      
      // append the letter
      [result appendString:currentCharacterStr];
      
      // save current styles for next character's checks
      previousActiveStyles = currentActiveStyles;
    }
    
    // set last character
    lastCharacter = currentCharacterChar;
  }
  
  // not-newline character was last - finish the paragraph
  if(![[NSCharacterSet newlineCharacterSet] characterIsMember:lastCharacter]) {
    // close all pending tags
    NSArray<NSNumber*> *sortedEndedStyles = [previousActiveStyles sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"intValue" ascending:NO]]];
      
    // append closing tags
    for(NSNumber *style in sortedEndedStyles) {
      NSString *tagContent = [self tagContentForStyle:style openingTag:NO location:_editor->textView.textStorage.string.length - 1];
      [result appendString: [NSString stringWithFormat:@"</%@>", tagContent]];
    }
    
    // finish the paragraph
    // handle ending paragraph styles
    if([previousActiveStyles containsObject:@([UnorderedListStyle getStyleType])]) {
      [result appendString:@"\n</ul>"];
    } else if(
      [previousActiveStyles containsObject:@([H1Style getStyleType])] ||
      [previousActiveStyles containsObject:@([H2Style getStyleType])] ||
      [previousActiveStyles containsObject:@([H3Style getStyleType])]
    ) {
      // do nothing, heading closing tag has already ben appended
    } else {
      [result appendString:@"</p>"];
    }
  }
  
  [result appendString: @"\n</html>"];
  
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
      LinkStyle *linkStyle = (LinkStyle *)_editor->stylesDict[@([LinkStyle getStyleType])];
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
      MentionStyle *mentionStyle = (MentionStyle *)_editor->stylesDict[@([MentionStyle getStyleType])];
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
  } else if([style isEqualToNumber:@([UnorderedListStyle getStyleType])]) {
    return @"li";
  }
  return @"";
}

- (void)replaceWholeFromHtml:(NSString * _Nonnull)html {
  NSArray *processingResult = [self getTextAndStylesFromHtml:html];
  NSString *plainText = (NSString *)processingResult[0];
  NSArray *stylesInfo = (NSArray *)processingResult[1];
  
  // reset the text first and reset typing attributes
  _editor->textView.text = @"";
  _editor->textView.typingAttributes = _editor->defaultTypingAttributes;
  
  // set new text
  _editor->textView.text = plainText;
  
  // re-apply the styles
  [self applyProcessedStyles:stylesInfo offsetFromBeginning:0];
  // run the editor changes callback
  [_editor anyTextMayHaveBeenModified];
}

- (void)replaceRangeFromHtml:(NSString * _Nonnull)html range:(NSRange)range {
  NSArray *processingResult = [self getTextAndStylesFromHtml:html];
  NSString *plainText = (NSString *)processingResult[0];
  NSArray *stylesInfo = (NSArray *)processingResult[1];
  
  // we can use ready replace util
  [TextInsertionUtils replaceText:plainText inView:_editor->textView at:range additionalAttributes:nil];
  
  [self applyProcessedStyles:stylesInfo offsetFromBeginning:range.location];
  [_editor anyTextMayHaveBeenModified];
}

- (void)insertFromHtml:(NSString * _Nonnull)html location:(NSInteger)location {
  NSArray *processingResult = [self getTextAndStylesFromHtml:html];
  NSString *plainText = (NSString *)processingResult[0];
  NSArray *stylesInfo = (NSArray *)processingResult[1];
  
  // same here, insertion utils got our back
  [TextInsertionUtils insertText:plainText inView:_editor->textView at:location additionalAttributes:nil];
  
  [self applyProcessedStyles:stylesInfo offsetFromBeginning:location];
  [_editor anyTextMayHaveBeenModified];
}

- (void)applyProcessedStyles:(NSArray *)processedStyles offsetFromBeginning:(NSInteger)offset {
  for(NSArray* arr in processedStyles) {
    // unwrap all info from processed style
    NSNumber *styleType = (NSNumber *)arr[0];
    StylePair *stylePair = (StylePair *)arr[1];
    id<BaseStyleProtocol> baseStyle = _editor->stylesDict[styleType];
    // range must be taking offest into consideration because processed styles' ranges are relative to only the new text
    // while we need absolute ranges relative to the whole existing text
    NSRange styleRange = NSMakeRange(offset + [stylePair.rangeValue rangeValue].location, [stylePair.rangeValue rangeValue].length);
    
    // of course any changes here need to take blocks and conflicts into consideration
    if([_editor handleStyleBlocksAndConflicts:[[baseStyle class] getStyleType] range:styleRange]) {
      if([styleType isEqualToNumber: @([LinkStyle getStyleType])]) {
        NSString *text = [_editor->textView.textStorage.string substringWithRange:styleRange];
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
}

- (NSArray *)getTextAndStylesFromHtml:(NSString *)html {
  NSString *fixedHtml = [html copy];
  if(html.length > 0) {
    // we want to get the string without <html> and </html> and their newlines
    // so we skip first 7 characters and get the string 7+8 = 15 characters shorter
    fixedHtml = [html substringWithRange: NSMakeRange(7, html.length-15)];
  }
  
  NSMutableString *plainText = [[NSMutableString alloc] initWithString: @""];
  NSMutableDictionary *ongoingTags = [[NSMutableDictionary alloc] init];
  NSMutableArray *initiallyProcessedTags = [[NSMutableArray alloc] init];
  BOOL insideTag = NO;
  BOOL gettingTagName = NO;
  BOOL gettingTagParams = NO;
  BOOL closingTag = NO;
  NSMutableString *currentTagName = [[NSMutableString alloc] initWithString:@""];
  NSMutableString *currentTagParams = [[NSMutableString alloc] initWithString:@""];
  
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
        [tagArr addObject:[NSNumber numberWithInt:plainText.length]];
        if(currentTagParams.length > 0) {
          [tagArr addObject:[currentTagParams copy]];
        }
        ongoingTags[currentTagName] = tagArr;
        
        // skip one newline after lists' opening tags
        if([currentTagName isEqualToString:@"ul"]) {
          i += 1;
        }
      } else {
        // we finish closing tags - pack tag name, tag range and optionally tag params into an entry that goes inside initiallyProcessedTags
        
        // skip one newline that was added before lists' closing tags
        if([currentTagName isEqualToString:@"ul"]) {
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
        // no tags logic - just append text
        [plainText appendString:currentCharacterStr];
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
      [styleArr addObject:@([LinkStyle getStyleType])];
      // cut only the url from the href="..." string
      NSString *url = [params substringWithRange:NSMakeRange(6, params.length - 7)];
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
    }
    
    stylePair.rangeValue = tagRangeValue;
    [styleArr addObject:stylePair];
    [processedStyles addObject:styleArr];
  }
  
  return @[plainText, processedStyles];
}

@end
