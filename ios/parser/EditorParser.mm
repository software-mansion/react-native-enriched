#import "EditorParser.h"
#import "ReactNativeRichTextEditorView.h"
#import "StyleHeaders.h"

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
      [result appendString:@"</p>"];
      
      // clear the previous styles
      previousActiveStyles = [[NSSet<NSNumber *> alloc]init];
      
      // next character opens new paragraph
      newLine = YES;
    } else {
      // new line - open the paragraph
      if(newLine) {
        newLine = NO;
        [result appendString:@"\n<p>"];
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
    [result appendString:@"</p>"];
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
              options:NSJSONReadingMutableContainers
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
  }
  return @"";
}

@end
