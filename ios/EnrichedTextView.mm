#import "EnrichedTextView.h"
#import "AttachmentLayoutUtils.h"
#import "EnrichedTextStyleHeaders.h"
#import "EnrichedTextTouchHandler.h"
#import "EnrichedTouchableTextView.h"
#import "HtmlParser.h"
#import "LayoutManagerExtension.h"
#import "LinkData.h"
#import "MentionParams.h"
#import "MentionStyleProps.h"
#import "RCTFabricComponentsPlugins.h"
#import "StringExtension.h"
#import "StyleUtils.h"
#import "TextDecorationLineEnum.h"
#import "ZeroWidthSpaceUtils.h"
#import <React/RCTConversions.h>
#import <ReactNativeEnriched/EnrichedTextComponentDescriptor.h>
#import <ReactNativeEnriched/EventEmitters.h>
#import <ReactNativeEnriched/Props.h>
#import <folly/dynamic.h>
#import <react/utils/ManagedObjectWrapper.h>

using namespace facebook::react;

@interface EnrichedTextView () <NSObject>
@end

@implementation EnrichedTextView {
  EnrichedTextViewShadowNode::ConcreteState::Shared _state;
  NSMutableDictionary<NSValue *, UIImageView *> *_attachmentViews;
  EnrichedTextTouchHandler *_touchHandler;
}

@synthesize blockEmitting = _blockEmitting;

// MARK: - Component utils

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<EnrichedTextComponentDescriptor>();
}

Class<RCTComponentViewProtocol> EnrichedTextViewCls(void) {
  return EnrichedTextView.class;
}

+ (BOOL)shouldBeRecycled {
  return NO;
}

// MARK: - Init

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps =
        std::make_shared<const EnrichedTextViewProps>();
    _props = defaultProps;
    _attachmentViews = [[NSMutableDictionary alloc] init];
    defaultTypingAttributes = [[NSMutableDictionary alloc] init];
    [self setupTextView];
    [self setupStyles];
    self.contentView = textView;
  }
  return self;
}

- (void)setupTextView {
  EnrichedTouchableTextView *tv = [[EnrichedTouchableTextView alloc] init];
  _touchHandler = [[EnrichedTextTouchHandler alloc] initWithView:self];
  tv.touchHandler = _touchHandler;
  textView = tv;

  textView.backgroundColor = UIColor.clearColor;
  textView.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
  textView.textContainer.lineFragmentPadding = 0;
  textView.editable = NO;
  textView.scrollEnabled = NO;
  textView.adjustsFontForContentSizeCategory = YES;
  textView.layoutManager.input = self;
}

- (void)setupStyles {
  stylesDict = [StyleUtils stylesDictForHost:self isInput:NO];
  conflictingStyles = [[StyleUtils conflictMap] mutableCopy];
  blockingStyles = [[StyleUtils blockingMap] mutableCopy];
}

// MARK: - EnrichedViewHost protocol

- (UITextView *)textView {
  return textView;
}

- (EnrichedConfig *)config {
  return config;
}

- (NSDictionary<NSNumber *, id> *)stylesDict {
  return stylesDict;
}

- (AttributesManager *)attributesManager {
  return nil;
}

- (NSMutableDictionary<NSNumber *, NSArray<NSNumber *> *> *)conflictingStyles {
  return conflictingStyles;
}

- (NSMutableDictionary<NSNumber *, NSArray<NSNumber *> *> *)blockingStyles {
  return blockingStyles;
}

- (NSMutableDictionary<NSAttributedStringKey, id> *)defaultTypingAttributes {
  return defaultTypingAttributes;
}

// MARK: - Props

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps {
  const auto &oldViewProps =
      *std::static_pointer_cast<EnrichedTextViewProps const>(_props);
  const auto &newViewProps =
      *std::static_pointer_cast<EnrichedTextViewProps const>(props);
  BOOL isFirstMount = NO;
  BOOL stylePropChanged = NO;
  BOOL textChanged = NO;

  if (config == nullptr) {
    isFirstMount = YES;
    config = [[EnrichedConfig alloc] init];
  }

  EnrichedConfig *newConfig = [config copy];

  // color
  if (newViewProps.color != oldViewProps.color) {
    if (isColorMeaningful(newViewProps.color)) {
      UIColor *uiColor = RCTUIColorFromSharedColor(newViewProps.color);
      [newConfig setPrimaryColor:uiColor];
    } else {
      [newConfig setPrimaryColor:nullptr];
    }
    stylePropChanged = YES;
  }

  // fontSize
  if (newViewProps.fontSize != oldViewProps.fontSize) {
    if (newViewProps.fontSize) {
      NSNumber *fontSize = @(newViewProps.fontSize);
      [newConfig setPrimaryFontSize:fontSize];
    } else {
      [newConfig setPrimaryFontSize:nullptr];
    }
    stylePropChanged = YES;
  }

  // fontWeight
  if (newViewProps.fontWeight != oldViewProps.fontWeight) {
    if (!newViewProps.fontWeight.empty()) {
      [newConfig
          setPrimaryFontWeight:[NSString
                                   fromCppString:newViewProps.fontWeight]];
    } else {
      [newConfig setPrimaryFontWeight:nullptr];
    }
    stylePropChanged = YES;
  }

  // fontFamily
  if (newViewProps.fontFamily != oldViewProps.fontFamily) {
    if (!newViewProps.fontFamily.empty()) {
      [newConfig
          setPrimaryFontFamily:[NSString
                                   fromCppString:newViewProps.fontFamily]];
    } else {
      [newConfig setPrimaryFontFamily:nullptr];
    }
    stylePropChanged = YES;
  }

  // fontStyle
  if (newViewProps.fontStyle != oldViewProps.fontStyle) {
    // TODO: Implement fontStyle setter on EnrichedConfig
    //    stylePropChanged = YES;
  }

  // htmlStyle headings
  if (newViewProps.htmlStyle.h1.fontSize !=
      oldViewProps.htmlStyle.h1.fontSize) {
    [newConfig setH1FontSize:newViewProps.htmlStyle.h1.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h1.bold != oldViewProps.htmlStyle.h1.bold) {
    [newConfig setH1Bold:newViewProps.htmlStyle.h1.bold];

    // Update style blocks and conflicts for bold
    if (newViewProps.htmlStyle.h1.bold) {
      [StyleUtils addStyleBlock:H1 to:Bold forHost:self];
      [StyleUtils addStyleConflict:Bold to:H1 forHost:self];
    } else {
      [StyleUtils removeStyleBlock:H1 from:Bold forHost:self];
      [StyleUtils removeStyleConflict:Bold from:H1 forHost:self];
    }

    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h2.fontSize !=
      oldViewProps.htmlStyle.h2.fontSize) {
    [newConfig setH2FontSize:newViewProps.htmlStyle.h2.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h2.bold != oldViewProps.htmlStyle.h2.bold) {
    [newConfig setH2Bold:newViewProps.htmlStyle.h2.bold];

    // Update style blocks and conflicts for bold
    if (newViewProps.htmlStyle.h2.bold) {
      [StyleUtils addStyleBlock:H2 to:Bold forHost:self];
      [StyleUtils addStyleConflict:Bold to:H2 forHost:self];
    } else {
      [StyleUtils removeStyleBlock:H2 from:Bold forHost:self];
      [StyleUtils removeStyleConflict:Bold from:H2 forHost:self];
    }

    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h3.fontSize !=
      oldViewProps.htmlStyle.h3.fontSize) {
    [newConfig setH3FontSize:newViewProps.htmlStyle.h3.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h3.bold != oldViewProps.htmlStyle.h3.bold) {
    [newConfig setH3Bold:newViewProps.htmlStyle.h3.bold];

    // Update style blocks and conflicts for bold
    if (newViewProps.htmlStyle.h3.bold) {
      [StyleUtils addStyleBlock:H3 to:Bold forHost:self];
      [StyleUtils addStyleConflict:Bold to:H3 forHost:self];
    } else {
      [StyleUtils removeStyleBlock:H3 from:Bold forHost:self];
      [StyleUtils removeStyleConflict:Bold from:H3 forHost:self];
    }

    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h4.fontSize !=
      oldViewProps.htmlStyle.h4.fontSize) {
    [newConfig setH4FontSize:newViewProps.htmlStyle.h4.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h4.bold != oldViewProps.htmlStyle.h4.bold) {
    [newConfig setH4Bold:newViewProps.htmlStyle.h4.bold];

    // Update style blocks and conflicts for bold
    if (newViewProps.htmlStyle.h4.bold) {
      [StyleUtils addStyleBlock:H4 to:Bold forHost:self];
      [StyleUtils addStyleConflict:Bold to:H4 forHost:self];
    } else {
      [StyleUtils removeStyleBlock:H4 from:Bold forHost:self];
      [StyleUtils removeStyleConflict:Bold from:H4 forHost:self];
    }

    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h5.fontSize !=
      oldViewProps.htmlStyle.h5.fontSize) {
    [newConfig setH5FontSize:newViewProps.htmlStyle.h5.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h5.bold != oldViewProps.htmlStyle.h5.bold) {
    [newConfig setH5Bold:newViewProps.htmlStyle.h5.bold];

    // Update style blocks and conflicts for bold
    if (newViewProps.htmlStyle.h5.bold) {
      [StyleUtils addStyleBlock:H5 to:Bold forHost:self];
      [StyleUtils addStyleConflict:Bold to:H5 forHost:self];
    } else {
      [StyleUtils removeStyleBlock:H5 from:Bold forHost:self];
      [StyleUtils removeStyleConflict:Bold from:H5 forHost:self];
    }

    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h6.fontSize !=
      oldViewProps.htmlStyle.h6.fontSize) {
    [newConfig setH6FontSize:newViewProps.htmlStyle.h6.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h6.bold != oldViewProps.htmlStyle.h6.bold) {
    [newConfig setH6Bold:newViewProps.htmlStyle.h6.bold];

    // Update style blocks and conflicts for bold
    if (newViewProps.htmlStyle.h6.bold) {
      [StyleUtils addStyleBlock:H6 to:Bold forHost:self];
      [StyleUtils addStyleConflict:Bold to:H6 forHost:self];
    } else {
      [StyleUtils removeStyleBlock:H6 from:Bold forHost:self];
      [StyleUtils removeStyleConflict:Bold from:H6 forHost:self];
    }

    stylePropChanged = YES;
  }

  // blockquote
  if (newViewProps.htmlStyle.blockquote.borderColor !=
      oldViewProps.htmlStyle.blockquote.borderColor) {
    if (isColorMeaningful(newViewProps.htmlStyle.blockquote.borderColor)) {
      [newConfig setBlockquoteBorderColor:RCTUIColorFromSharedColor(
                                              newViewProps.htmlStyle.blockquote
                                                  .borderColor)];
      stylePropChanged = YES;
    }
  }
  if (newViewProps.htmlStyle.blockquote.borderWidth !=
      oldViewProps.htmlStyle.blockquote.borderWidth) {
    [newConfig
        setBlockquoteBorderWidth:newViewProps.htmlStyle.blockquote.borderWidth];
    stylePropChanged = YES;
  }
  if (newViewProps.htmlStyle.blockquote.gapWidth !=
      oldViewProps.htmlStyle.blockquote.gapWidth) {
    [newConfig
        setBlockquoteGapWidth:newViewProps.htmlStyle.blockquote.gapWidth];
    stylePropChanged = YES;
  }
  if (newViewProps.htmlStyle.blockquote.color !=
          oldViewProps.htmlStyle.blockquote.color ||
      isFirstMount) {
    if (isColorMeaningful(newViewProps.htmlStyle.blockquote.color)) {
      [newConfig
          setBlockquoteColor:RCTUIColorFromSharedColor(
                                 newViewProps.htmlStyle.blockquote.color)];
    } else {
      [newConfig setBlockquoteColor:[newConfig primaryColor]];
    }
    stylePropChanged = YES;
  }

  // inline code
  if (newViewProps.htmlStyle.code.color != oldViewProps.htmlStyle.code.color) {
    if (isColorMeaningful(newViewProps.htmlStyle.code.color)) {
      [newConfig setInlineCodeFgColor:RCTUIColorFromSharedColor(
                                          newViewProps.htmlStyle.code.color)];
      stylePropChanged = YES;
    }
  }
  if (newViewProps.htmlStyle.code.backgroundColor !=
      oldViewProps.htmlStyle.code.backgroundColor) {
    if (isColorMeaningful(newViewProps.htmlStyle.code.backgroundColor)) {
      [newConfig setInlineCodeBgColor:RCTUIColorFromSharedColor(
                                          newViewProps.htmlStyle.code
                                              .backgroundColor)];
      stylePropChanged = YES;
    }
  }

  // codeblock
  if (newViewProps.htmlStyle.codeblock.color !=
      oldViewProps.htmlStyle.codeblock.color) {
    if (isColorMeaningful(newViewProps.htmlStyle.codeblock.color)) {
      [newConfig
          setCodeBlockFgColor:RCTUIColorFromSharedColor(
                                  newViewProps.htmlStyle.codeblock.color)];
      stylePropChanged = YES;
    }
  }
  if (newViewProps.htmlStyle.codeblock.backgroundColor !=
      oldViewProps.htmlStyle.codeblock.backgroundColor) {
    if (isColorMeaningful(newViewProps.htmlStyle.codeblock.backgroundColor)) {
      [newConfig setCodeBlockBgColor:RCTUIColorFromSharedColor(
                                         newViewProps.htmlStyle.codeblock
                                             .backgroundColor)];
      stylePropChanged = YES;
    }
  }
  if (newViewProps.htmlStyle.codeblock.borderRadius !=
      oldViewProps.htmlStyle.codeblock.borderRadius) {
    [newConfig
        setCodeBlockBorderRadius:newViewProps.htmlStyle.codeblock.borderRadius];
    stylePropChanged = YES;
  }

  // ordered list
  if (newViewProps.htmlStyle.ol.gapWidth !=
      oldViewProps.htmlStyle.ol.gapWidth) {
    [newConfig setOrderedListGapWidth:newViewProps.htmlStyle.ol.gapWidth];
    stylePropChanged = YES;
  }
  if (newViewProps.htmlStyle.ol.marginLeft !=
      oldViewProps.htmlStyle.ol.marginLeft) {
    [newConfig setOrderedListMarginLeft:newViewProps.htmlStyle.ol.marginLeft];
    stylePropChanged = YES;
  }
  if (newViewProps.htmlStyle.ol.markerFontWeight !=
          oldViewProps.htmlStyle.ol.markerFontWeight ||
      isFirstMount) {
    if (!newViewProps.htmlStyle.ol.markerFontWeight.empty()) {
      [newConfig
          setOrderedListMarkerFontWeight:
              [NSString
                  fromCppString:newViewProps.htmlStyle.ol.markerFontWeight]];
    } else {
      [newConfig setOrderedListMarkerFontWeight:[newConfig primaryFontWeight]];
    }
    stylePropChanged = YES;
  }
  if (newViewProps.htmlStyle.ol.markerColor !=
          oldViewProps.htmlStyle.ol.markerColor ||
      isFirstMount) {
    if (isColorMeaningful(newViewProps.htmlStyle.ol.markerColor)) {
      [newConfig
          setOrderedListMarkerColor:RCTUIColorFromSharedColor(
                                        newViewProps.htmlStyle.ol.markerColor)];
    } else {
      [newConfig setOrderedListMarkerColor:[newConfig primaryColor]];
    }
    stylePropChanged = YES;
  }

  // unordered list
  if (newViewProps.htmlStyle.ul.bulletColor !=
      oldViewProps.htmlStyle.ul.bulletColor) {
    if (isColorMeaningful(newViewProps.htmlStyle.ul.bulletColor)) {
      [newConfig setUnorderedListBulletColor:RCTUIColorFromSharedColor(
                                                 newViewProps.htmlStyle.ul
                                                     .bulletColor)];
      stylePropChanged = YES;
    }
  }
  if (newViewProps.htmlStyle.ul.bulletSize !=
      oldViewProps.htmlStyle.ul.bulletSize) {
    [newConfig setUnorderedListBulletSize:newViewProps.htmlStyle.ul.bulletSize];
    stylePropChanged = YES;
  }
  if (newViewProps.htmlStyle.ul.gapWidth !=
      oldViewProps.htmlStyle.ul.gapWidth) {
    [newConfig setUnorderedListGapWidth:newViewProps.htmlStyle.ul.gapWidth];
    stylePropChanged = YES;
  }
  if (newViewProps.htmlStyle.ul.marginLeft !=
      oldViewProps.htmlStyle.ul.marginLeft) {
    [newConfig setUnorderedListMarginLeft:newViewProps.htmlStyle.ul.marginLeft];
    stylePropChanged = YES;
  }

  // link
  if (newViewProps.htmlStyle.a.color != oldViewProps.htmlStyle.a.color) {
    if (isColorMeaningful(newViewProps.htmlStyle.a.color)) {
      [newConfig setLinkColor:RCTUIColorFromSharedColor(
                                  newViewProps.htmlStyle.a.color)];
      stylePropChanged = YES;
    }
  }
  if (newViewProps.htmlStyle.a.pressColor !=
      oldViewProps.htmlStyle.a.pressColor) {
    if (isColorMeaningful(newViewProps.htmlStyle.a.pressColor)) {
      [newConfig setLinkPressColor:RCTUIColorFromSharedColor(
                                       newViewProps.htmlStyle.a.pressColor)];
      stylePropChanged = YES;
    }
  }
  if (newViewProps.htmlStyle.a.textDecorationLine !=
      oldViewProps.htmlStyle.a.textDecorationLine) {
    NSString *objcString =
        [NSString fromCppString:newViewProps.htmlStyle.a.textDecorationLine];
    if ([objcString isEqualToString:DecorationUnderline]) {
      [newConfig setLinkDecorationLine:DecorationUnderline];
    } else {
      [newConfig setLinkDecorationLine:DecorationNone];
    }
    stylePropChanged = YES;
  }

  // checkbox list
  if (newViewProps.htmlStyle.ulCheckbox.boxSize !=
      oldViewProps.htmlStyle.ulCheckbox.boxSize) {
    [newConfig
        setCheckboxListBoxSize:newViewProps.htmlStyle.ulCheckbox.boxSize];
    stylePropChanged = YES;
  }
  if (newViewProps.htmlStyle.ulCheckbox.gapWidth !=
      oldViewProps.htmlStyle.ulCheckbox.gapWidth) {
    [newConfig
        setCheckboxListGapWidth:newViewProps.htmlStyle.ulCheckbox.gapWidth];
    stylePropChanged = YES;
  }
  if (newViewProps.htmlStyle.ulCheckbox.marginLeft !=
      oldViewProps.htmlStyle.ulCheckbox.marginLeft) {
    [newConfig
        setCheckboxListMarginLeft:newViewProps.htmlStyle.ulCheckbox.marginLeft];
    stylePropChanged = YES;
  }
  if (newViewProps.htmlStyle.ulCheckbox.boxColor !=
      oldViewProps.htmlStyle.ulCheckbox.boxColor) {
    if (isColorMeaningful(newViewProps.htmlStyle.ulCheckbox.boxColor)) {
      [newConfig setCheckboxListBoxColor:RCTUIColorFromSharedColor(
                                             newViewProps.htmlStyle.ulCheckbox
                                                 .boxColor)];
      stylePropChanged = YES;
    }
  }

  // mention
  folly::dynamic oldMentionStyle = oldViewProps.htmlStyle.mention;
  folly::dynamic newMentionStyle = newViewProps.htmlStyle.mention;
  if (oldMentionStyle != newMentionStyle) {
    bool newSingleProps = NO;

    for (const auto &obj : newMentionStyle.items()) {
      if (obj.second.isInt() || obj.second.isString()) {
        newSingleProps = YES;
        break;
      } else if (obj.second.isObject()) {
        newSingleProps = NO;
        break;
      }
    }

    if (newSingleProps) {
      [newConfig setMentionStyleProps:
                     [MentionStyleProps
                         getSinglePropsFromFollyDynamic:newMentionStyle]];
    } else {
      [newConfig setMentionStyleProps:
                     [MentionStyleProps
                         getComplexPropsFromFollyDynamic:newMentionStyle]];
    }

    stylePropChanged = YES;
  }

  // text prop
  if (newViewProps.text != oldViewProps.text || isFirstMount) {
    textChanged = YES;
  }

  // ellipsizeMode
  if (newViewProps.ellipsizeMode != oldViewProps.ellipsizeMode ||
      isFirstMount) {
    NSString *mode = [NSString fromCppString:newViewProps.ellipsizeMode];
    if ([mode isEqualToString:@"head"]) {
      textView.textContainer.lineBreakMode = NSLineBreakByTruncatingHead;
    } else if ([mode isEqualToString:@"middle"]) {
      textView.textContainer.lineBreakMode = NSLineBreakByTruncatingMiddle;
    } else if ([mode isEqualToString:@"clip"]) {
      textView.textContainer.lineBreakMode = NSLineBreakByClipping;
    } else {
      textView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
    }
  }

  // numberOfLines
  if (newViewProps.numberOfLines != oldViewProps.numberOfLines ||
      isFirstMount) {
    textView.textContainer.maximumNumberOfLines = newViewProps.numberOfLines;
  }

  // selectable
  if (newViewProps.selectable != oldViewProps.selectable || isFirstMount) {
    textView.selectable = newViewProps.selectable;
  }

  // selectionColor
  if (newViewProps.selectionColor != oldViewProps.selectionColor) {
    if (isColorMeaningful(newViewProps.selectionColor)) {
      textView.tintColor =
          RCTUIColorFromSharedColor(newViewProps.selectionColor);
    }
  }

  if (stylePropChanged) {
    config = newConfig;
  }

  [self syncDefaultTypingAttributesFromConfig];

  if (textChanged || stylePropChanged) {
    [self renderText:[NSString fromCppString:newViewProps.text]];
  }

  [super updateProps:props oldProps:oldProps];
  [self tryUpdatingHeight];
}

- (void)syncDefaultTypingAttributesFromConfig {
  defaultTypingAttributes[NSForegroundColorAttributeName] =
      [config primaryColor];
  defaultTypingAttributes[NSFontAttributeName] = [config primaryFont];
  defaultTypingAttributes[NSUnderlineColorAttributeName] =
      [config primaryColor];
  defaultTypingAttributes[NSStrikethroughColorAttributeName] =
      [config primaryColor];
  NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];
  pStyle.minimumLineHeight = [config scaledPrimaryLineHeight];
  defaultTypingAttributes[NSParagraphStyleAttributeName] = pStyle;
  textView.typingAttributes = defaultTypingAttributes;
}

// MARK: - Rendering

- (void)renderText:(NSString *)html {
  if (html.length == 0) {
    [textView.textStorage
        setAttributedString:[[NSAttributedString alloc] initWithString:@""]];
    return;
  }

  NSString *normalized = [HtmlParser initiallyProcessHtml:html
                                        useHtmlNormalizer:YES];
  if (normalized == nil) {
    [textView.textStorage
        setAttributedString:[[NSAttributedString alloc]
                                initWithString:html
                                    attributes:defaultTypingAttributes]];
    return;
  }

  NSArray *result = [HtmlParser getTextAndStylesFromHtml:normalized];
  NSString *plainText = result[0];
  NSArray *processedStyles = result[1];

  NSMutableAttributedString *body = [[NSMutableAttributedString alloc]
      initWithString:plainText
          attributes:defaultTypingAttributes];
  [textView.textStorage setAttributedString:body];
  [self applyProcessedStyles:processedStyles];
  [self layoutAttachments];
}

- (void)applyProcessedStyles:(NSArray *)processedStyles {
  // Some paragraph styles (codeblock, blockquote, etc.) insert \u200B
  // into empty lines, mutating NSTextStorage length. We need to
  // shift subsequent ranges by this offset.
  NSInteger zeroWidthSpaceOffset = 0;

  // Inline styles collected during the first pass so their applyStyling: can
  // be re-run after all paragraph styles have applied their visual attributes.
  // Each entry is @[style, adjustedRange].
  NSMutableArray *pendingInlineApply = [NSMutableArray array];

  // Paragraph styles call applyStyling: immediately; inline styles
  // defer it so that paragraph visual attributes are already in
  // place when inline styles override them.
  for (NSArray *arr in processedStyles) {
    NSNumber *styleType = (NSNumber *)arr[0];
    StylePair *stylePair = (StylePair *)arr[1];
    StyleBase *style = stylesDict[styleType];
    if (style == nullptr)
      continue;

    NSRange parsedRange = [stylePair.rangeValue rangeValue];
    NSUInteger textLengthBeforeStyleApplied =
        textView.textStorage.string.length;

    // Range must be taking zeroWidthSpaceOffset into consideration
    // because processed styles ranges are relative to only the new text while
    // we need absolute ranges relative to the whole existing text
    NSRange styleRange = NSMakeRange(
        zeroWidthSpaceOffset + parsedRange.location, parsedRange.length);

    if (![StyleUtils handleStyleBlocksAndConflicts:[[style class] getType]
                                             range:styleRange
                                           forHost:self]) {
      continue;
    }

    if ([styleType isEqualToNumber:@([LinkStyle getType])]) {
      LinkData *linkData = (LinkData *)stylePair.styleValue;
      [((LinkStyle *)style) applyLinkMetaWithData:linkData range:styleRange];
    } else if ([styleType isEqualToNumber:@([MentionStyle getType])]) {
      MentionParams *params = (MentionParams *)stylePair.styleValue;
      [((MentionStyle *)style) applyMentionMeta:params range:styleRange];
    } else if ([styleType isEqualToNumber:@([ImageStyle getType])]) {
      ImageData *imgData = (ImageData *)stylePair.styleValue;
      [((ImageStyle *)style) addImageAtRange:styleRange
                                   imageData:imgData
                               withSelection:NO
                              withDirtyRange:NO];
    } else if ([styleType isEqualToNumber:@([CheckboxListStyle getType])]) {
      NSDictionary *checkboxStates = (NSDictionary *)stylePair.styleValue;
      CheckboxListStyle *cbStyle = (CheckboxListStyle *)style;

      [cbStyle addWithChecked:NO
                        range:styleRange
                   withTyping:YES
               withDirtyRange:NO];

      if (checkboxStates && checkboxStates.count > 0) {
        for (NSNumber *key in checkboxStates) {
          NSUInteger checkboxPosition =
              zeroWidthSpaceOffset + [key unsignedIntegerValue];
          BOOL isChecked = [checkboxStates[key] boolValue];

          if (isChecked) {
            [cbStyle toggleCheckedAt:checkboxPosition withDirtyRange:NO];
          }
        }
      }
    } else {
      [style add:styleRange withTyping:YES withDirtyRange:NO];
    }

    [ZeroWidthSpaceUtils handleZeroWidthSpacesInInput:self];

    NSInteger delta =
        textView.textStorage.string.length - textLengthBeforeStyleApplied;

    // Use an adjusted range so that applyStyling covers any ZWS characters that
    // were just inserted by handleZeroWidthSpacesInInput. Without this, a style
    // applied to an empty range {0,0} would call applyStyling on {0,0} even
    // after a ZWS was inserted.
    NSRange adjustedStyleRange = NSMakeRange(
        styleRange.location, styleRange.length + (NSUInteger)MAX(0LL, delta));

    if ([style isParagraph]) {
      [style applyStyling:adjustedStyleRange];
    } else {
      [pendingInlineApply
          addObject:@[ style, [NSValue valueWithRange:adjustedStyleRange] ]];
    }

    // Image shifts are already handled by _precedingImageCount during tag
    // finalization.
    if (delta != 0 && ![styleType isEqualToNumber:@([ImageStyle getType])]) {
      zeroWidthSpaceOffset += delta;
    }
  }

  // Apply visual styling for inline styles
  for (NSArray *entry in pendingInlineApply) {
    StyleBase *style = entry[0];
    NSRange adjustedStyleRange = [((NSValue *)entry[1]) rangeValue];
    [style applyStyling:adjustedStyleRange];
  }
}

// MARK: - Measuring and state

- (CGSize)measureSize:(CGFloat)maxWidth {
  if (textView.textStorage.length == 0) {
    return CGSizeMake(maxWidth, 0);
  }

  NSMutableAttributedString *currentStr = [[NSMutableAttributedString alloc]
      initWithAttributedString:textView.textStorage];

  // edge case: input with only a zero width space should still be of a height
  // of a single line, so we add a mock "I" character
  if ([currentStr length] == 1 &&
      [[currentStr.string substringWithRange:NSMakeRange(0, 1)]
          isEqualToString:@"\u200B"]) {
    [currentStr
        appendAttributedString:[[NSAttributedString alloc]
                                   initWithString:@"I"
                                       attributes:defaultTypingAttributes]];
  }

  // edge case: trailing newlines aren't counted towards height calculations, so
  // we add a mock "I" character
  if (currentStr.length > 0) {
    unichar lastChar =
        [currentStr.string characterAtIndex:currentStr.length - 1];
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:lastChar]) {
      [currentStr
          appendAttributedString:[[NSAttributedString alloc]
                                     initWithString:@"I"
                                         attributes:defaultTypingAttributes]];
    }
  }

  CGRect boundingBox =
      [currentStr boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                               options:NSStringDrawingUsesLineFragmentOrigin |
                                       NSStringDrawingUsesFontLeading
                               context:nullptr];

  return CGSizeMake(maxWidth, ceil(boundingBox.size.height));
}

- (void)updateState:(State::Shared const &)state
           oldState:(State::Shared const &)oldState {
  _state =
      std::static_pointer_cast<const EnrichedTextViewShadowNode::ConcreteState>(
          state);

  if (oldState == nullptr) {
    [self tryUpdatingHeight];
  }
}

- (void)tryUpdatingHeight {
  if (_state == nullptr) {
    return;
  }
  auto selfRef = wrapManagedObjectWeakly(self);
  _state->updateState(EnrichedTextViewState(selfRef));
}

- (std::shared_ptr<EnrichedTextViewEventEmitter>)getEventEmitter {
  if (_eventEmitter != nullptr) {
    auto emitter =
        static_cast<const EnrichedTextViewEventEmitter &>(*_eventEmitter);
    return std::make_shared<EnrichedTextViewEventEmitter>(emitter);
  }
  return nullptr;
}

- (void)emitOnLinkPressEvent:(NSString *)url {
  if (!url)
    return;
  auto emitter = [self getEventEmitter];
  if (emitter != nullptr) {
    emitter->onLinkPress({.url = [url toCppString]});
  }
}

- (void)emitOnMentionPressEvent:(MentionParams *)mention {
  auto emitter = [self getEventEmitter];
  if (emitter != nullptr) {
    folly::dynamic attrsObj = folly::dynamic::object;
    if (mention.attributes != nil) {
      NSData *data =
          [mention.attributes dataUsingEncoding:NSUTF8StringEncoding];
      NSError *error = nil;
      NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
                                                           options:0
                                                             error:&error];
      if (error != nil) {
        NSLog(@"[EnrichedTextView] Failed to parse mention attributes JSON: %@",
              error);
        return;
      }

      for (NSString *key in dict) {
        id val = dict[key];
        if ([val isKindOfClass:[NSString class]]) {
          attrsObj[[key toCppString]] = [val toCppString];
        }
      }
    }

    emitter->onMentionPress({
        .text = mention.text ? [mention.text toCppString] : std::string{},
        .indicator =
            mention.indicator ? [mention.indicator toCppString] : std::string{},
        .attributes = attrsObj,
    });
  }
}

// MARK: - Media attachments delegate

- (void)mediaAttachmentDidUpdate:(MediaAttachment *)attachment {
  [AttachmentLayoutUtils handleAttachmentUpdate:attachment
                                       textView:textView
                                  onLayoutBlock:^{
                                    [self layoutAttachments];
                                    [self tryUpdatingHeight];
                                  }];
}

- (void)layoutAttachments {
  _attachmentViews =
      [AttachmentLayoutUtils layoutAttachmentsInTextView:textView
                                                  config:config
                                           existingViews:_attachmentViews];
}

@end
