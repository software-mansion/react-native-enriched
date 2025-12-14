#import "EnrichedHtmlParser.h"
#import "EnrichedHTMLTagUtils.h"
#import "HtmlNode.h"
#import "StyleHeaders.h"

@implementation EnrichedHTMLParser {
  NSDictionary<NSNumber *, id<BaseStyleProtocol>> *_styles;
  NSArray<id<BaseStyleProtocol>> *_inlineStyles;
  NSArray<id<BaseStyleProtocol>> *_paragraphStyles;
}

- (instancetype)initWithStyles:(NSDictionary<NSNumber *, id> *)stylesDict {
  self = [super init];
  if (!self)
    return nil;

  _styles = stylesDict ?: @{};

  NSMutableArray *inlineStylesArray = [NSMutableArray array];
  NSMutableArray *paragraphStylesArray = [NSMutableArray array];

  NSArray *allKeys = stylesDict.allKeys;
  for (NSInteger i = 0; i < allKeys.count; i++) {
    NSNumber *key = allKeys[i];
    id<BaseStyleProtocol> style = stylesDict[key];
    Class cls = style.class;

    BOOL isParagraph = ([cls respondsToSelector:@selector(isParagraphStyle)]) &&
                       [cls isParagraphStyle];

    if (isParagraph) {
      [paragraphStylesArray addObject:style];
    } else {
      [inlineStylesArray addObject:style];
    }
  }

  _inlineStyles = inlineStylesArray.copy;
  _paragraphStyles = paragraphStylesArray.copy;

  return self;
}

- (NSString *)buildHtmlFromAttributedString:(NSAttributedString *)text
                                    pretify:(BOOL)pretify {

  if (text.length == 0)
    return @"<html>\n<p></p>\n</html>";

  HTMLElement *root = [self buildRootNodeFromAttributedString:text];

  NSMutableData *buffer = [NSMutableData data];
  [self createHtmlFromNode:root into:buffer pretify:pretify];

  return [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
}

- (HTMLElement *)buildRootNodeFromAttributedString:(NSAttributedString *)text {
  NSString *plain = text.string;

  HTMLElement *root = [HTMLElement new];
  root.tag = "html";

  HTMLElement *br = [HTMLElement new];
  br.tag = "br";
  br.selfClosing = YES;

  __block id<BaseStyleProtocol> previousParagraphStyle = nil;
  __block HTMLElement *previousNode = nil;

  [plain
      enumerateSubstringsInRange:NSMakeRange(0, plain.length)
                         options:NSStringEnumerationByParagraphs
                      usingBlock:^(NSString *_Nullable substring,
                                   NSRange paragraphRange,
                                   NSRange __unused enclosingRange,
                                   BOOL *__unused stop) {
                        if (paragraphRange.length == 0) {
                          [root.children addObject:br];
                          previousParagraphStyle = nil;
                          previousNode = nil;
                          return;
                        }

                        id<BaseStyleProtocol> paragraphStyle =
                            [self detectParagraphStyle:text
                                        paragraphRange:paragraphRange];

                        HTMLElement *container = [self
                            containerForParagraphStyle:paragraphStyle
                                previousParagraphStyle:previousParagraphStyle
                                          previousNode:previousNode
                                              rootNode:root];

                        previousParagraphStyle = paragraphStyle;
                        previousNode = container;

                        HTMLElement *target =
                            [self nextContainerForParagraphStyle:paragraphStyle
                                                currentContainer:container];

                        [text
                            enumerateAttributesInRange:paragraphRange
                                               options:0
                                            usingBlock:^(
                                                NSDictionary *attrs,
                                                NSRange runRange,
                                                BOOL *__unused stopRun) {
                                              HTMLNode *node = [self
                                                  getInlineStyleNodes:text
                                                                range:runRange
                                                                attrs:attrs
                                                                plain:plain];
                                              [target.children addObject:node];
                                            }];
                      }];

  return root;
}

- (HTMLElement *)nextContainerForParagraphStyle:
                     (id<BaseStyleProtocol> _Nullable)style
                               currentContainer:(HTMLElement *)container {
  if (!style)
    return container;

  const char *sub = [style.class subTagName];
  if (!sub)
    return container;

  HTMLElement *inner = [HTMLElement new];
  inner.tag = sub;
  [container.children addObject:inner];
  return inner;
}

- (id<BaseStyleProtocol> _Nullable)
    detectParagraphStyle:(NSAttributedString *)text
          paragraphRange:(NSRange)paragraphRange {
  NSDictionary *attrsAtStart = [text attributesAtIndex:paragraphRange.location
                                        effectiveRange:nil];
  id<BaseStyleProtocol> _Nullable foundParagraphStyle = nil;
  for (NSInteger i = 0; i < _paragraphStyles.count; i++) {
    id<BaseStyleProtocol> paragraphStyle = _paragraphStyles[i];
    Class paragraphStyleClass = paragraphStyle.class;

    NSAttributedStringKey attributeKey = [paragraphStyleClass attributeKey];
    id value = attrsAtStart[attributeKey];

    if (value && [paragraphStyle styleCondition:value range:paragraphRange]) {
      return paragraphStyle;
    }
  }

  return foundParagraphStyle;
}

- (HTMLElement *)currentParagraphType:(NSNumber *)currentParagraphType
                previousParagraphType:(NSNumber *)previousParagraphType
                         previousNode:(HTMLElement *)previousNode
                             rootNode:(HTMLElement *)rootNode {
  if (!currentParagraphType) {
    HTMLElement *outer = [HTMLElement new];
    outer.tag = "p";
    [rootNode.children addObject:outer];
    return outer;
  }

  BOOL isTheSameParagraph = currentParagraphType == previousParagraphType;
  id<BaseStyleProtocol> styleObject = _styles[currentParagraphType];
  Class styleClass = styleObject.class;

  BOOL hasSubTags = [styleClass subTagName] != NULL;

  if (isTheSameParagraph && hasSubTags)
    return previousNode;

  HTMLElement *outer = [HTMLElement new];

  outer.tag = [styleClass tagName];

  [rootNode.children addObject:outer];
  return outer;
}

- (HTMLElement *)
    containerForParagraphStyle:(id<BaseStyleProtocol> _Nullable)currentStyle
        previousParagraphStyle:(id<BaseStyleProtocol> _Nullable)previousStyle
                  previousNode:(HTMLElement *)previousNode
                      rootNode:(HTMLElement *)rootNode {
  if (!currentStyle) {
    HTMLElement *outer = [HTMLElement new];
    outer.tag = "p";
    [rootNode.children addObject:outer];
    return outer;
  }

  BOOL sameStyle = (currentStyle == previousStyle);
  Class styleClass = currentStyle.class;
  BOOL hasSub = ([styleClass subTagName] != NULL);

  if (sameStyle && hasSub)
    return previousNode;

  HTMLElement *outer = [HTMLElement new];
  outer.tag = [styleClass tagName];
  [rootNode.children addObject:outer];
  return outer;
}

- (HTMLNode *)getInlineStyleNodes:(NSAttributedString *)text
                            range:(NSRange)range
                            attrs:(NSDictionary *)attrs
                            plain:(NSString *)plain {
  HTMLTextNode *textNode = [HTMLTextNode new];
  textNode.source = plain;
  textNode.range = range;
  HTMLNode *currentNode = textNode;

  for (NSInteger i = 0; i < _inlineStyles.count; i++) {
    id<BaseStyleProtocol> styleObject = _inlineStyles[i];
    Class styleClass = styleObject.class;

    NSAttributedStringKey attributeKey = [styleClass attributeKey];
    id value = attrs[attributeKey];

    if (!value || ![styleObject styleCondition:value range:range])
      continue;

    HTMLElement *wrap = [HTMLElement new];
    const char *tag = [styleClass tagName];

    wrap.tag = tag;
    wrap.attributes =
        [styleClass respondsToSelector:@selector(getParametersFromValue:)]
            ? [styleClass getParametersFromValue:value]
            : nullptr;
    wrap.selfClosing = [styleClass isSelfClosing];
    [wrap.children addObject:currentNode];
    currentNode = wrap;
  }

  return currentNode;
}

- (void)createHtmlFromNode:(HTMLNode *)node
                      into:(NSMutableData *)buffer
                   pretify:(BOOL)pretify {
  if ([node isKindOfClass:[HTMLTextNode class]]) {
    HTMLTextNode *t = (HTMLTextNode *)node;
    appendEscapedRange(buffer, t.source, t.range);
    return;
  }

  if (![node isKindOfClass:[HTMLElement class]])
    return;

  HTMLElement *element = (HTMLElement *)node;

  BOOL addNewLineBefore = pretify && isBlockTag(element.tag);
  BOOL addNewLineAfter = pretify && needsNewLineAfter(element.tag);

  if (element.selfClosing) {
    appendSelfClosingTag(buffer, element.tag, element.attributes,
                         addNewLineBefore);
    return;
  }

  appendOpenTag(buffer, element.tag, element.attributes ?: nullptr,
                addNewLineBefore);

  for (HTMLNode *child in element.children)
    [self createHtmlFromNode:child into:buffer pretify:pretify];

  if (addNewLineAfter)
    appendC(buffer, "\n");

  appendCloseTag(buffer, element.tag);
}

@end
