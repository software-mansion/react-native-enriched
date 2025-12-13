#import "EnrichedHtmlParser.h"
#import "EnrichedHTMLTagUtils.h"
#import "HtmlNode.h"
#import "StyleHeaders.h"

@implementation EnrichedHTMLParser {
  NSDictionary<NSNumber *, id<BaseStyleProtocol>> *_styles;
  NSArray<NSNumber *> *_inlineOrder;
  NSArray<NSNumber *> *_paragraphOrder;
}

- (instancetype)initWithStyles:(NSDictionary<NSNumber *, id> *)stylesDict {
  self = [super init];
  if (!self)
    return nil;

  _styles = stylesDict ?: @{};

  NSMutableArray *inlineArr = [NSMutableArray array];
  NSMutableArray *paragraphArr = [NSMutableArray array];

  for (NSNumber *type in _styles) {
    id<BaseStyleProtocol> style = _styles[type];
    Class cls = style.class;

    BOOL isParagraph = ([cls respondsToSelector:@selector(isParagraphStyle)] &&
                        [cls isParagraphStyle]);

    if (isParagraph)
      [paragraphArr addObject:type];
    else
      [inlineArr addObject:type];
  }

  [inlineArr sortUsingSelector:@selector(compare:)];
  [paragraphArr sortUsingSelector:@selector(compare:)];

  _inlineOrder = inlineArr.copy;
  _paragraphOrder = paragraphArr.copy;

  return self;
}

- (NSString *)buildHtmlFromAttributedString:(NSAttributedString *)text
                                    pretify:(BOOL)pretify {

  if (text.length == 0)
    return @"<html>\n<p></p>\n</html>";

  HTMLElement *root = [self buildRootNodeFromAttributedString:text];

  NSMutableData *buf = [NSMutableData data];
  [self createHtmlFromNode:root into:buf pretify:pretify];

  return [[NSString alloc] initWithData:buf encoding:NSUTF8StringEncoding];
}

- (HTMLElement *)buildRootNodeFromAttributedString:(NSAttributedString *)text {
  NSString *plain = text.string;

  HTMLElement *root = [HTMLElement new];
  root.tag = "html";

  HTMLElement *br = [HTMLElement new];
  br.tag = "br";
  br.selfClosing = YES;

  __block NSNumber *previousParagraphType = nil;
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
                          previousParagraphType = nil;
                          previousNode = nil;
                          return;
                        }
                        NSDictionary *attrsAtStart =
                            [text attributesAtIndex:paragraphRange.location
                                     effectiveRange:nil];

                        NSNumber *ptype = nil;
                        for (NSNumber *sty in self->_paragraphOrder) {
                          id<BaseStyleProtocol> s = self->_styles[sty];
                          NSString *key = [s.class attributeKey];
                          id val = attrsAtStart[key];
                          if (val && [s styleCondition:val
                                                 range:paragraphRange]) {
                            ptype = sty;
                            break;
                          }
                        }

                        HTMLElement *container =
                            [self containerForBlock:ptype
                                        reuseLastOf:previousParagraphType
                                       previousNode:previousNode
                                           rootNode:root];

                        previousParagraphType = ptype;
                        previousNode = container;

                        HTMLElement *target = [self getNextContainer:ptype
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

- (HTMLElement *)containerForBlock:(NSNumber *)currentParagraphType
                       reuseLastOf:(NSNumber *)previousParagraphType
                      previousNode:(HTMLElement *)previousNode
                          rootNode:(HTMLElement *)rootNode {
  if (!currentParagraphType) {
    HTMLElement *outer = [HTMLElement new];
    outer.tag = "p";
    [rootNode.children addObject:outer];
    return outer;
  }

  BOOL isTheSameBlock = currentParagraphType == previousParagraphType;
  id<BaseStyleProtocol> styleObject = _styles[currentParagraphType];
  Class styleClass = styleObject.class;

  BOOL hasSubTags = [styleClass subTagName] != NULL;

  if (isTheSameBlock && hasSubTags)
    return previousNode;

  HTMLElement *outer = [HTMLElement new];

  outer.tag = [styleClass tagName];

  [rootNode.children addObject:outer];
  return outer;
}

- (HTMLElement *)getNextContainer:(NSNumber *)blockType
                 currentContainer:(HTMLElement *)container {

  if (!blockType)
    return container;

  id<BaseStyleProtocol> style = _styles[blockType];

  const char *subTagName = [style.class subTagName];

  if (subTagName) {
    HTMLElement *inner = [HTMLElement new];
    inner.tag = subTagName;
    [container.children addObject:inner];
    return inner;
  }

  return container;
}
- (HTMLNode *)getInlineStyleNodes:(NSAttributedString *)text
                            range:(NSRange)range
                            attrs:(NSDictionary *)attrs
                            plain:(NSString *)plain {
  HTMLTextNode *textNode = [HTMLTextNode new];
  textNode.source = plain;
  textNode.range = range;
  HTMLNode *currentNode = textNode;

  for (NSNumber *sty in _inlineOrder) {

    id<BaseStyleProtocol> obj = _styles[sty];
    Class cls = obj.class;

    NSString *key = [cls attributeKey];
    id v = attrs[key];

    if (!v || ![obj styleCondition:v range:range])
      continue;

    HTMLElement *wrap = [HTMLElement new];
    const char *tag = [cls tagName];

    wrap.tag = tag;
    wrap.attributes =
        [cls respondsToSelector:@selector(getParametersFromValue:)]
            ? [cls getParametersFromValue:v]
            : nullptr;
    wrap.selfClosing = [cls isSelfClosing];
    [wrap.children addObject:currentNode];
    currentNode = wrap;
  }

  return currentNode;
}

#pragma mark - Rendering

- (void)createHtmlFromNode:(HTMLNode *)node
                      into:(NSMutableData *)buf
                   pretify:(BOOL)pretify {
  if ([node isKindOfClass:[HTMLTextNode class]]) {
    HTMLTextNode *t = (HTMLTextNode *)node;
    appendEscapedRange(buf, t.source, t.range);
    return;
  }

  if (![node isKindOfClass:[HTMLElement class]])
    return;

  HTMLElement *el = (HTMLElement *)node;

  BOOL addNewLineBefore = pretify && isBlockTag(el.tag);
  BOOL addNewLineAfter = pretify && needsNewLineAfter(el.tag);

  if (el.selfClosing) {
    appendSelfClosingTagC(buf, el.tag, el.attributes, addNewLineBefore);
    return;
  }

  appendOpenTagC(buf, el.tag, el.attributes ?: nullptr, addNewLineBefore);

  for (HTMLNode *child in el.children)
    [self createHtmlFromNode:child into:buf pretify:pretify];

  if (addNewLineAfter)
    appendC(buf, "\n");

  appendCloseTagC(buf, el.tag);
}

@end
