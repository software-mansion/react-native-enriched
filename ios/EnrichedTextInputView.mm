#import "EnrichedTextInputView.h"
#import "CoreText/CoreText.h"
#import "DotReplacementUtils.h"
#import "LayoutManagerExtension.h"
#import "ParagraphAttributesUtils.h"
#import "RCTFabricComponentsPlugins.h"
#import "StringExtension.h"
#import "StyleHeaders.h"
#import "TextBlockTapGestureRecognizer.h"
#import "UIView+React.h"
#import "WordsUtils.h"
#import "ZeroWidthSpaceUtils.h"
#import <React/RCTConversions.h>
#import <ReactNativeEnriched/EnrichedTextInputViewComponentDescriptor.h>
#import <ReactNativeEnriched/EventEmitters.h>
#import <ReactNativeEnriched/Props.h>
#import <ReactNativeEnriched/RCTComponentViewHelpers.h>
#import <folly/dynamic.h>
#import <react/utils/ManagedObjectWrapper.h>

#define GET_STYLE_STATE(TYPE_ENUM)                                             \
  {                                                                            \
    .isActive = [self isStyleActive:TYPE_ENUM],                                \
    .isBlocking = [self isStyle:TYPE_ENUM activeInMap:blockingStyles],         \
    .isConflicting = [self isStyle:TYPE_ENUM activeInMap:conflictingStyles]    \
  }

using namespace facebook::react;

@interface EnrichedTextInputView () <
    RCTEnrichedTextInputViewViewProtocol, UITextViewDelegate,
    UIGestureRecognizerDelegate, NSTextStorageDelegate, NSObject>

@end

@implementation EnrichedTextInputView {
  EnrichedTextInputViewShadowNode::ConcreteState::Shared _state;
  int _componentViewHeightUpdateCounter;
  NSMutableSet<NSNumber *> *_activeStyles;
  NSMutableSet<NSNumber *> *_blockedStyles;
  LinkData *_recentlyActiveLinkData;
  NSRange _recentlyActiveLinkRange;
  NSString *_recentInputString;
  MentionParams *_recentlyActiveMentionParams;
  NSRange _recentlyActiveMentionRange;
  NSString *_recentlyEmittedHtml;
  BOOL _emitHtml;
  UILabel *_placeholderLabel;
  UIColor *_placeholderColor;
  BOOL _emitFocusBlur;
  BOOL _emitTextChange;
}

// MARK: - Component utils

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<
      EnrichedTextInputViewComponentDescriptor>();
}

Class<RCTComponentViewProtocol> EnrichedTextInputViewCls(void) {
  return EnrichedTextInputView.class;
}

+ (BOOL)shouldBeRecycled {
  return NO;
}

// MARK: - Init

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps =
        std::make_shared<const EnrichedTextInputViewProps>();
    _props = defaultProps;
    [self setDefaults];
    [self setupTextView];
    [self addSubview:textView];
  }
  return self;
}

- (void)setDefaults {
  _componentViewHeightUpdateCounter = 0;
  _activeStyles = [[NSMutableSet alloc] init];
  _blockedStyles = [[NSMutableSet alloc] init];
  _recentlyActiveLinkRange = NSMakeRange(0, 0);
  _recentlyActiveMentionRange = NSMakeRange(0, 0);
  recentlyChangedRange = NSMakeRange(0, 0);
  _recentInputString = @"";
  _recentlyEmittedHtml = @"<html>\n<p></p>\n</html>";
  _emitHtml = NO;
  blockEmitting = NO;
  _emitFocusBlur = YES;
  _emitTextChange = NO;
  dotReplacementRange = nullptr;

  defaultTypingAttributes =
      [[NSMutableDictionary<NSAttributedStringKey, id> alloc] init];

  stylesDict = @{
    @([BoldStyle getType]) : [[BoldStyle alloc] initWithInput:self],
    @([ItalicStyle getType]) : [[ItalicStyle alloc] initWithInput:self],
    @([UnderlineStyle getType]) : [[UnderlineStyle alloc] initWithInput:self],
    @([StrikethroughStyle getType]) :
        [[StrikethroughStyle alloc] initWithInput:self],
    @([InlineCodeStyle getType]) : [[InlineCodeStyle alloc] initWithInput:self],
    @([LinkStyle getType]) : [[LinkStyle alloc] initWithInput:self],
    @([MentionStyle getType]) : [[MentionStyle alloc] initWithInput:self],
    @([H1Style getType]) : [[H1Style alloc] initWithInput:self],
    @([H2Style getType]) : [[H2Style alloc] initWithInput:self],
    @([H3Style getType]) : [[H3Style alloc] initWithInput:self],
    @([H4Style getType]) : [[H4Style alloc] initWithInput:self],
    @([H5Style getType]) : [[H5Style alloc] initWithInput:self],
    @([H6Style getType]) : [[H6Style alloc] initWithInput:self],
    @([UnorderedListStyle getType]) :
        [[UnorderedListStyle alloc] initWithInput:self],
    @([OrderedListStyle getType]) :
        [[OrderedListStyle alloc] initWithInput:self],
    @([CheckboxListStyle getType]) :
        [[CheckboxListStyle alloc] initWithInput:self],
    @([BlockQuoteStyle getType]) : [[BlockQuoteStyle alloc] initWithInput:self],
    @([CodeBlockStyle getType]) : [[CodeBlockStyle alloc] initWithInput:self],
    @([ImageStyle getType]) : [[ImageStyle alloc] initWithInput:self]
  };

  conflictingStyles = @{
    @([BoldStyle getType]) : @[],
    @([ItalicStyle getType]) : @[],
    @([UnderlineStyle getType]) : @[],
    @([StrikethroughStyle getType]) : @[],
    @([InlineCodeStyle getType]) :
        @[ @([LinkStyle getType]), @([MentionStyle getType]) ],
    @([LinkStyle getType]) : @[
      @([InlineCodeStyle getType]), @([LinkStyle getType]),
      @([MentionStyle getType])
    ],
    @([MentionStyle getType]) :
        @[ @([InlineCodeStyle getType]), @([LinkStyle getType]) ],
    @([H1Style getType]) : @[
      @([H2Style getType]), @([H3Style getType]), @([H4Style getType]),
      @([H5Style getType]), @([H6Style getType]),
      @([UnorderedListStyle getType]), @([OrderedListStyle getType]),
      @([BlockQuoteStyle getType]), @([CodeBlockStyle getType]),
      @([CheckboxListStyle getType])
    ],
    @([H2Style getType]) : @[
      @([H1Style getType]), @([H3Style getType]), @([H4Style getType]),
      @([H5Style getType]), @([H6Style getType]),
      @([UnorderedListStyle getType]), @([OrderedListStyle getType]),
      @([BlockQuoteStyle getType]), @([CodeBlockStyle getType]),
      @([CheckboxListStyle getType])
    ],
    @([H3Style getType]) : @[
      @([H1Style getType]), @([H2Style getType]), @([H4Style getType]),
      @([H5Style getType]), @([H6Style getType]),
      @([UnorderedListStyle getType]), @([OrderedListStyle getType]),
      @([BlockQuoteStyle getType]), @([CodeBlockStyle getType]),
      @([CheckboxListStyle getType])
    ],
    @([H4Style getType]) : @[
      @([H1Style getType]), @([H2Style getType]), @([H3Style getType]),
      @([H5Style getType]), @([H6Style getType]),
      @([UnorderedListStyle getType]), @([OrderedListStyle getType]),
      @([BlockQuoteStyle getType]), @([CodeBlockStyle getType]),
      @([CheckboxListStyle getType])
    ],
    @([H5Style getType]) : @[
      @([H1Style getType]), @([H2Style getType]), @([H3Style getType]),
      @([H4Style getType]), @([H6Style getType]),
      @([UnorderedListStyle getType]), @([OrderedListStyle getType]),
      @([BlockQuoteStyle getType]), @([CodeBlockStyle getType]),
      @([CheckboxListStyle getType])
    ],
    @([H6Style getType]) : @[
      @([H1Style getType]), @([H2Style getType]), @([H3Style getType]),
      @([H4Style getType]), @([H5Style getType]),
      @([UnorderedListStyle getType]), @([OrderedListStyle getType]),
      @([BlockQuoteStyle getType]), @([CodeBlockStyle getType]),
      @([CheckboxListStyle getType])
    ],
    @([UnorderedListStyle getType]) : @[
      @([H1Style getType]), @([H2Style getType]), @([H3Style getType]),
      @([H4Style getType]), @([H5Style getType]), @([H6Style getType]),
      @([OrderedListStyle getType]), @([BlockQuoteStyle getType]),
      @([CodeBlockStyle getType]), @([CheckboxListStyle getType])
    ],
    @([OrderedListStyle getType]) : @[
      @([H1Style getType]), @([H2Style getType]), @([H3Style getType]),
      @([H4Style getType]), @([H5Style getType]), @([H6Style getType]),
      @([UnorderedListStyle getType]), @([BlockQuoteStyle getType]),
      @([CodeBlockStyle getType]), @([CheckboxListStyle getType])
    ],
    @([CheckboxListStyle getType]) : @[
      @([H1Style getType]), @([H2Style getType]), @([H3Style getType]),
      @([H4Style getType]), @([H5Style getType]), @([H6Style getType]),
      @([UnorderedListStyle getType]), @([OrderedListStyle getType]),
      @([BlockQuoteStyle getType]), @([CodeBlockStyle getType])
    ],
    @([BlockQuoteStyle getType]) : @[
      @([H1Style getType]), @([H2Style getType]), @([H3Style getType]),
      @([H4Style getType]), @([H5Style getType]), @([H6Style getType]),
      @([UnorderedListStyle getType]), @([OrderedListStyle getType]),
      @([CodeBlockStyle getType]), @([CheckboxListStyle getType])
    ],
    @([CodeBlockStyle getType]) : @[
      @([H1Style getType]), @([H2Style getType]), @([H3Style getType]),
      @([H4Style getType]), @([H5Style getType]), @([H6Style getType]),
      @([BoldStyle getType]), @([UnderlineStyle getType]),
      @([ItalicStyle getType]), @([StrikethroughStyle getType]),
      @([UnorderedListStyle getType]), @([OrderedListStyle getType]),
      @([BlockQuoteStyle getType]), @([InlineCodeStyle getType]),
      @([MentionStyle getType]), @([LinkStyle getType]),
      @([CheckboxListStyle getType])
    ],
    @([ImageStyle getType]) :
        @[ @([LinkStyle getType]), @([MentionStyle getType]) ]
  };

  blockingStyles = [@{
    @([BoldStyle getType]) : @[ @([CodeBlockStyle getType]) ],
    @([ItalicStyle getType]) : @[ @([CodeBlockStyle getType]) ],
    @([UnderlineStyle getType]) : @[ @([CodeBlockStyle getType]) ],
    @([StrikethroughStyle getType]) : @[ @([CodeBlockStyle getType]) ],
    @([InlineCodeStyle getType]) :
        @[ @([CodeBlockStyle getType]), @([ImageStyle getType]) ],
    @([LinkStyle getType]) :
        @[ @([CodeBlockStyle getType]), @([ImageStyle getType]) ],
    @([MentionStyle getType]) :
        @[ @([CodeBlockStyle getType]), @([ImageStyle getType]) ],
    @([H1Style getType]) : @[],
    @([H2Style getType]) : @[],
    @([H3Style getType]) : @[],
    @([H4Style getType]) : @[],
    @([H5Style getType]) : @[],
    @([H6Style getType]) : @[],
    @([UnorderedListStyle getType]) : @[],
    @([OrderedListStyle getType]) : @[],
    @([CheckboxListStyle getType]) : @[],
    @([BlockQuoteStyle getType]) : @[],
    @([CodeBlockStyle getType]) : @[],
    @([ImageStyle getType]) : @[ @([InlineCodeStyle getType]) ]
  } mutableCopy];

  parser = [[InputParser alloc] initWithInput:self];
  attributesManager = [[AttributesManager alloc] initWithInput:self];
}

- (void)setupTextView {
  textView = [[InputTextView alloc] init];
  textView.backgroundColor = UIColor.clearColor;
  textView.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
  textView.textContainer.lineFragmentPadding = 0;
  textView.delegate = self;
  textView.input = self;
  textView.layoutManager.input = self;
  textView.textStorage.delegate = self;

  textView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  textView.adjustsFontForContentSizeCategory = YES;
  [textView addGestureRecognizer:[[TextBlockTapGestureRecognizer alloc]
                                     initWithInput:self
                                            action:@selector(onTextBlockTap:)]];
}

// MARK: - Props

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps {
  const auto &oldViewProps =
      *std::static_pointer_cast<EnrichedTextInputViewProps const>(_props);
  const auto &newViewProps =
      *std::static_pointer_cast<EnrichedTextInputViewProps const>(props);
  BOOL isFirstMount = NO;
  BOOL stylePropChanged = NO;

  // initial config
  if (config == nullptr) {
    isFirstMount = YES;
    config = [[InputConfig alloc] init];
  }

  // any style prop changes:
  // firstly we create the new config for the changes

  InputConfig *newConfig = [config copy];

  if (newViewProps.color != oldViewProps.color) {
    if (isColorMeaningful(newViewProps.color)) {
      UIColor *uiColor = RCTUIColorFromSharedColor(newViewProps.color);
      [newConfig setPrimaryColor:uiColor];
    } else {
      [newConfig setPrimaryColor:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.fontSize != oldViewProps.fontSize) {
    if (newViewProps.fontSize) {
      NSNumber *fontSize = @(newViewProps.fontSize);
      [newConfig setPrimaryFontSize:fontSize];
    } else {
      [newConfig setPrimaryFontSize:nullptr];
    }
    stylePropChanged = YES;
  }

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

  // rich text style

  if (newViewProps.htmlStyle.h1.fontSize !=
      oldViewProps.htmlStyle.h1.fontSize) {
    [newConfig setH1FontSize:newViewProps.htmlStyle.h1.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h1.bold != oldViewProps.htmlStyle.h1.bold) {
    [newConfig setH1Bold:newViewProps.htmlStyle.h1.bold];

    // Update style blocks for bold
    newViewProps.htmlStyle.h1.bold ? [self addStyleBlock:H1 to:Bold]
                                   : [self removeStyleBlock:H1 from:Bold];

    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h2.fontSize !=
      oldViewProps.htmlStyle.h2.fontSize) {
    [newConfig setH2FontSize:newViewProps.htmlStyle.h2.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h2.bold != oldViewProps.htmlStyle.h2.bold) {
    [newConfig setH2Bold:newViewProps.htmlStyle.h2.bold];

    // Update style blocks for bold
    newViewProps.htmlStyle.h2.bold ? [self addStyleBlock:H2 to:Bold]
                                   : [self removeStyleBlock:H2 from:Bold];

    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h3.fontSize !=
      oldViewProps.htmlStyle.h3.fontSize) {
    [newConfig setH3FontSize:newViewProps.htmlStyle.h3.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h3.bold != oldViewProps.htmlStyle.h3.bold) {
    [newConfig setH3Bold:newViewProps.htmlStyle.h3.bold];

    // Update style blocks for bold
    newViewProps.htmlStyle.h3.bold ? [self addStyleBlock:H3 to:Bold]
                                   : [self removeStyleBlock:H3 from:Bold];

    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h4.fontSize !=
      oldViewProps.htmlStyle.h4.fontSize) {
    [newConfig setH4FontSize:newViewProps.htmlStyle.h4.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h4.bold != oldViewProps.htmlStyle.h4.bold) {
    [newConfig setH4Bold:newViewProps.htmlStyle.h4.bold];

    // Update style blocks for bold
    newViewProps.htmlStyle.h4.bold ? [self addStyleBlock:H4 to:Bold]
                                   : [self removeStyleBlock:H4 from:Bold];

    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h5.fontSize !=
      oldViewProps.htmlStyle.h5.fontSize) {
    [newConfig setH5FontSize:newViewProps.htmlStyle.h5.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h5.bold != oldViewProps.htmlStyle.h5.bold) {
    [newConfig setH5Bold:newViewProps.htmlStyle.h5.bold];

    // Update style blocks for bold
    newViewProps.htmlStyle.h5.bold ? [self addStyleBlock:H5 to:Bold]
                                   : [self removeStyleBlock:H5 from:Bold];

    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h6.fontSize !=
      oldViewProps.htmlStyle.h6.fontSize) {
    [newConfig setH6FontSize:newViewProps.htmlStyle.h6.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h6.bold != oldViewProps.htmlStyle.h6.bold) {
    [newConfig setH6Bold:newViewProps.htmlStyle.h6.bold];

    // Update style blocks for bold
    newViewProps.htmlStyle.h6.bold ? [self addStyleBlock:H6 to:Bold]
                                   : [self removeStyleBlock:H6 from:Bold];

    stylePropChanged = YES;
  }

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

  // since this prop defaults to undefined on JS side, we need to force set the
  // value on first mount
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

  // since this prop defaults to undefined on JS side, we need to force set the
  // value on first mount
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

  // since this prop defaults to undefined on JS side, we need to force set the
  // value on first mount
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

  if (newViewProps.htmlStyle.a.color != oldViewProps.htmlStyle.a.color) {
    if (isColorMeaningful(newViewProps.htmlStyle.a.color)) {
      [newConfig setLinkColor:RCTUIColorFromSharedColor(
                                  newViewProps.htmlStyle.a.color)];
      stylePropChanged = YES;
    }
  }

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

  if (newViewProps.htmlStyle.a.textDecorationLine !=
      oldViewProps.htmlStyle.a.textDecorationLine) {
    NSString *objcString =
        [NSString fromCppString:newViewProps.htmlStyle.a.textDecorationLine];
    if ([objcString isEqualToString:DecorationUnderline]) {
      [newConfig setLinkDecorationLine:DecorationUnderline];
    } else {
      // both DecorationNone and a different, wrong value gets a DecorationNone
      // here
      [newConfig setLinkDecorationLine:DecorationNone];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.scrollEnabled != oldViewProps.scrollEnabled ||
      textView.scrollEnabled != newViewProps.scrollEnabled) {
    [textView setScrollEnabled:newViewProps.scrollEnabled];
  }

  folly::dynamic oldMentionStyle = oldViewProps.htmlStyle.mention;
  folly::dynamic newMentionStyle = newViewProps.htmlStyle.mention;
  if (oldMentionStyle != newMentionStyle) {
    bool newSingleProps = NO;

    for (const auto &obj : newMentionStyle.items()) {
      if (obj.second.isInt() || obj.second.isString()) {
        // we are in just a single MentionStyleProps object
        newSingleProps = YES;
        break;
      } else if (obj.second.isObject()) {
        // we are in map of indicators to MentionStyleProps
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

  if (stylePropChanged) {
    // all the text needs to be rebuilt
    // we get the current html using old config, then switch to new config and
    // replace text using the html this way, the newest config attributes are
    // being used!

    // the html needs to be generated using the old config
    NSString *currentHtml = [parser
        parseToHtmlFromRange:NSMakeRange(0,
                                         textView.textStorage.string.length)];
    // we want to preserve the selection between props changes
    NSRange prevSelectedRange = textView.selectedRange;

    // now set the new config
    config = newConfig;

    // no emitting during styles reload
    blockEmitting = YES;

    // make sure everything is sound in the html
    NSString *initiallyProcessedHtml =
        [parser initiallyProcessHtml:currentHtml];
    if (initiallyProcessedHtml != nullptr) {
      [parser replaceWholeFromHtml:initiallyProcessedHtml];
    }

    blockEmitting = NO;

    // fill the typing attributes with style props
    defaultTypingAttributes[NSForegroundColorAttributeName] =
        [config primaryColor];
    defaultTypingAttributes[NSFontAttributeName] = [config primaryFont];
    defaultTypingAttributes[NSUnderlineColorAttributeName] =
        [config primaryColor];
    defaultTypingAttributes[NSStrikethroughColorAttributeName] =
        [config primaryColor];
    defaultTypingAttributes[NSParagraphStyleAttributeName] =
        [[NSParagraphStyle alloc] init];
    textView.typingAttributes = defaultTypingAttributes;
    textView.selectedRange = prevSelectedRange;
  }

  // editable
  if (newViewProps.editable != textView.editable) {
    textView.editable = newViewProps.editable;
  }

  // default value - must be set before placeholder to make sure it correctly
  // shows on first mount
  if (newViewProps.defaultValue != oldViewProps.defaultValue) {
    NSString *newDefaultValue =
        [NSString fromCppString:newViewProps.defaultValue];

    NSString *initiallyProcessedHtml =
        [parser initiallyProcessHtml:newDefaultValue];
    if (initiallyProcessedHtml == nullptr) {
      // just plain text
      textView.text = newDefaultValue;
    } else {
      // we've got some seemingly proper html
      [parser replaceWholeFromHtml:initiallyProcessedHtml];
    }
    textView.selectedRange = NSRange(textView.textStorage.string.length, 0);
  }

  // placeholderTextColor
  if (newViewProps.placeholderTextColor != oldViewProps.placeholderTextColor) {
    textView.placeholderColor =
        RCTUIColorFromSharedColor(newViewProps.placeholderTextColor);
  }

  // placeholder
  if (newViewProps.placeholder != oldViewProps.placeholder) {
    [textView
        setPlaceholderText:[NSString fromCppString:newViewProps.placeholder]];
  }

  // mention indicators
  auto mismatchPair = std::mismatch(newViewProps.mentionIndicators.begin(),
                                    newViewProps.mentionIndicators.end(),
                                    oldViewProps.mentionIndicators.begin(),
                                    oldViewProps.mentionIndicators.end());
  if (mismatchPair.first != newViewProps.mentionIndicators.end() ||
      mismatchPair.second != oldViewProps.mentionIndicators.end()) {
    NSMutableSet<NSNumber *> *newIndicators = [[NSMutableSet alloc] init];
    for (const std::string &item : newViewProps.mentionIndicators) {
      if (item.length() == 1) {
        [newIndicators addObject:@(item[0])];
      }
    }
    [config setMentionIndicators:newIndicators];
  }

  // linkRegex
  LinkRegexConfig *oldRegexConfig =
      [[LinkRegexConfig alloc] initWithLinkRegexProp:oldViewProps.linkRegex];
  LinkRegexConfig *newRegexConfig =
      [[LinkRegexConfig alloc] initWithLinkRegexProp:newViewProps.linkRegex];
  if (![newRegexConfig isEqualToConfig:oldRegexConfig]) {
    [config setLinkRegexConfig:newRegexConfig];
  }

  // selection color sets both selection and cursor on iOS (just as in RN)
  if (newViewProps.selectionColor != oldViewProps.selectionColor) {
    if (isColorMeaningful(newViewProps.selectionColor)) {
      textView.tintColor =
          RCTUIColorFromSharedColor(newViewProps.selectionColor);
    } else {
      textView.tintColor = nullptr;
    }
  }

  // autoCapitalize
  if (newViewProps.autoCapitalize != oldViewProps.autoCapitalize) {
    NSString *str = [NSString fromCppString:newViewProps.autoCapitalize];
    if ([str isEqualToString:@"none"]) {
      textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    } else if ([str isEqualToString:@"sentences"]) {
      textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    } else if ([str isEqualToString:@"words"]) {
      textView.autocapitalizationType = UITextAutocapitalizationTypeWords;
    } else if ([str isEqualToString:@"characters"]) {
      textView.autocapitalizationType =
          UITextAutocapitalizationTypeAllCharacters;
    }

    // textView needs to be refocused on autocapitalization type change and we
    // don't want to emit these events
    if ([textView isFirstResponder]) {
      _emitFocusBlur = NO;
      [textView reactBlur];
      [textView reactFocus];
      _emitFocusBlur = YES;
    }
  }

  // isOnChangeHtmlSet
  _emitHtml = newViewProps.isOnChangeHtmlSet;

  // isOnChangeTextSet
  _emitTextChange = newViewProps.isOnChangeTextSet;

  [super updateProps:props oldProps:oldProps];
  // run the changes callback
  [self anyTextMayHaveBeenModified];

  // autofocus - needs to be done at the very end
  if (isFirstMount && newViewProps.autoFocus) {
    [textView reactFocus];
  }
  [textView updatePlaceholderVisibility];
}

- (void)updateLayoutMetrics:(const LayoutMetrics &)layoutMetrics
           oldLayoutMetrics:(const LayoutMetrics &)oldLayoutMetrics {
  [super updateLayoutMetrics:layoutMetrics oldLayoutMetrics:oldLayoutMetrics];

  textView.frame = UIEdgeInsetsInsetRect(
      self.bounds, RCTUIEdgeInsetsFromEdgeInsets(layoutMetrics.borderWidth));
  textView.textContainerInset = RCTUIEdgeInsetsFromEdgeInsets(
      layoutMetrics.contentInsets - layoutMetrics.borderWidth);
}

// make sure the newest state is kept in _state property
- (void)updateState:(State::Shared const &)state
           oldState:(State::Shared const &)oldState {
  _state = std::static_pointer_cast<
      const EnrichedTextInputViewShadowNode::ConcreteState>(state);

  // first render with all the needed stuff already defined (state and
  // componentView) so we need to run a single height calculation for any
  // initial values
  if (oldState == nullptr) {
    [self commitSize:textView.textContainer.size];
  }
}

- (void)commitSize:(CGSize)size {
  if (_state == nullptr) {
    return;
  }

  auto selfRef = wrapManagedObjectWeakly(self);
  facebook::react::Size newSize{.width = size.width, .height = size.height};
  _state->updateState(
      facebook::react::EnrichedTextInputViewState(newSize, selfRef));
}

- (CGSize)measureInitialSizeWithMaxWidth:(CGFloat)maxWidth {
  NSTextContainer *container = textView.textContainer;
  NSLayoutManager *layoutManager = textView.layoutManager;

  container.size = CGSizeMake(maxWidth, CGFLOAT_MAX);

  [layoutManager ensureLayoutForTextContainer:container];

  CGRect used = [layoutManager usedRectForTextContainer:container];
  CGFloat height = ceil(used.size.height);

  // Empty text fallback
  if (textView.textStorage.length == 0) {
    UIFont *font =
        textView.typingAttributes[NSFontAttributeName] ?: textView.font;
    if (font) {
      height = ceil(font.lineHeight);
    }
  }

  return CGSizeMake(maxWidth, height);
}

// MARK: - Active styles

- (void)tryUpdatingActiveStyles {
  // style updates are emitted only if something differs from the previously
  // active styles
  BOOL updateNeeded = NO;

  // active styles are kept in a separate set until we're sure they can be
  // emitted
  NSMutableSet *newActiveStyles = [_activeStyles mutableCopy];

  // currently blocked styles are subject to change (e.g. bold being blocked by
  // headings might change in reaction to prop change) so they also are kept
  // separately
  NSMutableSet *newBlockedStyles = [_blockedStyles mutableCopy];

  //  // data for onLinkDetected event
  LinkData *detectedLinkData;
  NSRange detectedLinkRange = NSMakeRange(0, 0);

  // data for onMentionDetected event
  MentionParams *detectedMentionParams = nullptr;
  NSRange detectedMentionRange = NSMakeRange(0, 0);

  for (NSNumber *type in stylesDict) {
    StyleBase *style = stylesDict[type];

    BOOL wasActive = [newActiveStyles containsObject:type];
    BOOL isActive = [style detect:textView.selectedRange];

    BOOL wasBlocked = [newBlockedStyles containsObject:type];
    BOOL isBlocked = [self isStyle:(StyleType)[type integerValue]
                       activeInMap:blockingStyles];

    if (wasActive != isActive) {
      updateNeeded = YES;
      if (isActive) {
        [newActiveStyles addObject:type];
      } else {
        [newActiveStyles removeObject:type];
      }
    }

    // blocked state change for a style also needs an update
    if (wasBlocked != isBlocked) {
      updateNeeded = YES;
      if (isBlocked) {
        [newBlockedStyles addObject:type];
      } else {
        [newBlockedStyles removeObject:type];
      }
    }

    // onLinkDetected event
    if (isActive && [type intValue] == [LinkStyle getType]) {
      // get the link data
      LinkData *candidateLinkData;
      NSRange candidateLinkRange = NSMakeRange(0, 0);
      LinkStyle *linkStyleClass =
          (LinkStyle *)stylesDict[@([LinkStyle getType])];
      if (linkStyleClass != nullptr) {
        candidateLinkData =
            [linkStyleClass getLinkDataAt:textView.selectedRange.location];
        candidateLinkRange =
            [linkStyleClass getFullLinkRangeAt:textView.selectedRange.location];
      }

      if (wasActive == NO) {
        // we changed selection from non-link to a link
        detectedLinkData = candidateLinkData;
        detectedLinkRange = candidateLinkRange;
      } else if (![_recentlyActiveLinkData.url
                     isEqualToString:candidateLinkData.url] ||
                 ![_recentlyActiveLinkData.text
                     isEqualToString:candidateLinkData.text] ||
                 !NSEqualRanges(_recentlyActiveLinkRange, candidateLinkRange)) {
        // we changed selection from one link to the other or modified
        // current link's text
        detectedLinkData = candidateLinkData;
        detectedLinkRange = candidateLinkRange;
      }
    }

    // onMentionDetected event
    if (isActive && [type intValue] == [MentionStyle getType]) {
      // get mention data
      MentionParams *candidateMentionParams;
      NSRange candidateMentionRange = NSMakeRange(0, 0);
      MentionStyle *mentionStyleClass =
          (MentionStyle *)stylesDict[@([MentionStyle getType])];
      if (mentionStyleClass != nullptr) {
        candidateMentionParams = [mentionStyleClass
            getMentionParamsAt:textView.selectedRange.location];
        candidateMentionRange = [mentionStyleClass
            getFullMentionRangeAt:textView.selectedRange.location];
      }

      if (wasActive == NO) {
        // selection was changed from a non-mention to a mention
        detectedMentionParams = candidateMentionParams;
        detectedMentionRange = candidateMentionRange;
      } else if (![_recentlyActiveMentionParams.text
                     isEqualToString:candidateMentionParams.text] ||
                 ![_recentlyActiveMentionParams.attributes
                     isEqualToString:candidateMentionParams.attributes] ||
                 !NSEqualRanges(_recentlyActiveMentionRange,
                                candidateMentionRange)) {
        // selection changed from one mention to another
        detectedMentionParams = candidateMentionParams;
        detectedMentionRange = candidateMentionRange;
      }
    }
  }

  if (updateNeeded) {
    auto emitter = [self getEventEmitter];
    if (emitter != nullptr) {
      // update activeStyles and blockedStyles only if emitter is available
      _activeStyles = newActiveStyles;
      _blockedStyles = newBlockedStyles;

      emitter->onChangeStateDeprecated(
          {.isBold = [self isStyleActive:[BoldStyle getType]],
           .isItalic = [self isStyleActive:[ItalicStyle getType]],
           .isUnderline = [self isStyleActive:[UnderlineStyle getType]],
           .isStrikeThrough = [self isStyleActive:[StrikethroughStyle getType]],
           .isInlineCode = [self isStyleActive:[InlineCodeStyle getType]],
           .isLink = [self isStyleActive:[LinkStyle getType]],
           .isMention = [self isStyleActive:[MentionStyle getType]],
           .isH1 = [self isStyleActive:[H1Style getType]],
           .isH2 = [self isStyleActive:[H2Style getType]],
           .isH3 = [self isStyleActive:[H3Style getType]],
           .isH4 = [self isStyleActive:[H4Style getType]],
           .isH5 = [self isStyleActive:[H5Style getType]],
           .isH6 = [self isStyleActive:[H6Style getType]],
           .isUnorderedList = [self isStyleActive:[UnorderedListStyle getType]],
           .isOrderedList = [self isStyleActive:[OrderedListStyle getType]],
           .isBlockQuote = [self isStyleActive:[BlockQuoteStyle getType]],
           .isCodeBlock = [self isStyleActive:[CodeBlockStyle getType]],
           .isImage = [self isStyleActive:[ImageStyle getType]],
           .isCheckboxList = [self isStyleActive:[CheckboxListStyle getType]]});
      emitter->onChangeState(
          {.bold = GET_STYLE_STATE([BoldStyle getType]),
           .italic = GET_STYLE_STATE([ItalicStyle getType]),
           .underline = GET_STYLE_STATE([UnderlineStyle getType]),
           .strikeThrough = GET_STYLE_STATE([StrikethroughStyle getType]),
           .inlineCode = GET_STYLE_STATE([InlineCodeStyle getType]),
           .link = GET_STYLE_STATE([LinkStyle getType]),
           .mention = GET_STYLE_STATE([MentionStyle getType]),
           .h1 = GET_STYLE_STATE([H1Style getType]),
           .h2 = GET_STYLE_STATE([H2Style getType]),
           .h3 = GET_STYLE_STATE([H3Style getType]),
           .h4 = GET_STYLE_STATE([H4Style getType]),
           .h5 = GET_STYLE_STATE([H5Style getType]),
           .h6 = GET_STYLE_STATE([H6Style getType]),
           .unorderedList = GET_STYLE_STATE([UnorderedListStyle getType]),
           .orderedList = GET_STYLE_STATE([OrderedListStyle getType]),
           .blockQuote = GET_STYLE_STATE([BlockQuoteStyle getType]),
           .codeBlock = GET_STYLE_STATE([CodeBlockStyle getType]),
           .image = GET_STYLE_STATE([ImageStyle getType]),
           .checkboxList = GET_STYLE_STATE([CheckboxListStyle getType])});
    }
  }

  if (detectedLinkData != nullptr) {
    [self emitOnLinkDetectedEvent:detectedLinkData.text
                              url:detectedLinkData.url
                            range:detectedLinkRange];
  }

  if (detectedMentionParams != nullptr) {
    [self emitOnMentionDetectedEvent:detectedMentionParams.text
                           indicator:detectedMentionParams.indicator
                          attributes:detectedMentionParams.attributes];

    _recentlyActiveMentionParams = detectedMentionParams;
    _recentlyActiveMentionRange = detectedMentionRange;
  }
  // emit onChangeHtml event if needed
  [self tryEmittingOnChangeHtmlEvent];
}

- (bool)isStyleActive:(StyleType)type {
  return [_activeStyles containsObject:@(type)];
}

- (bool)isStyle:(StyleType)type activeInMap:(NSDictionary *)styleMap {
  NSArray *relatedStyles = styleMap[@(type)];

  if (!relatedStyles) {
    return false;
  }

  for (NSNumber *style in relatedStyles) {
    if ([_activeStyles containsObject:style]) {
      return true;
    }
  }

  return false;
}

- (void)addStyleBlock:(StyleType)blocking to:(StyleType)blocked {
  NSMutableArray *blocksArr = [blockingStyles[@(blocked)] mutableCopy];
  if (![blocksArr containsObject:@(blocking)]) {
    [blocksArr addObject:@(blocking)];
    blockingStyles[@(blocked)] = blocksArr;
  }
}

- (void)removeStyleBlock:(StyleType)blocking from:(StyleType)blocked {
  NSMutableArray *blocksArr = [blockingStyles[@(blocked)] mutableCopy];
  if ([blocksArr containsObject:@(blocking)]) {
    [blocksArr removeObject:@(blocking)];
    blockingStyles[@(blocked)] = blocksArr;
  }
}

// MARK: - Native commands and events

- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args {
  if ([commandName isEqualToString:@"focus"]) {
    [self focus];
  } else if ([commandName isEqualToString:@"blur"]) {
    [self blur];
  } else if ([commandName isEqualToString:@"setValue"]) {
    NSString *value = (NSString *)args[0];
    [self setValue:value];
  } else if ([commandName isEqualToString:@"toggleBold"]) {
    [self toggleRegularStyle:[BoldStyle getType]];
  } else if ([commandName isEqualToString:@"toggleItalic"]) {
    [self toggleRegularStyle:[ItalicStyle getType]];
  } else if ([commandName isEqualToString:@"toggleUnderline"]) {
    [self toggleRegularStyle:[UnderlineStyle getType]];
  } else if ([commandName isEqualToString:@"toggleStrikeThrough"]) {
    [self toggleRegularStyle:[StrikethroughStyle getType]];
  } else if ([commandName isEqualToString:@"toggleInlineCode"]) {
    [self toggleRegularStyle:[InlineCodeStyle getType]];
  } else if ([commandName isEqualToString:@"addLink"]) {
    NSInteger start = [((NSNumber *)args[0]) integerValue];
    NSInteger end = [((NSNumber *)args[1]) integerValue];
    NSString *text = (NSString *)args[2];
    NSString *url = (NSString *)args[3];
    [self addLinkAt:start end:end text:text url:url];
  } else if ([commandName isEqualToString:@"addMention"]) {
    NSString *indicator = (NSString *)args[0];
    NSString *text = (NSString *)args[1];
    NSString *attributes = (NSString *)args[2];
    [self addMention:indicator text:text attributes:attributes];
  } else if ([commandName isEqualToString:@"startMention"]) {
    NSString *indicator = (NSString *)args[0];
    [self startMentionWithIndicator:indicator];
  } else if ([commandName isEqualToString:@"toggleH1"]) {
    [self toggleRegularStyle:[H1Style getType]];
  } else if ([commandName isEqualToString:@"toggleH2"]) {
    [self toggleRegularStyle:[H2Style getType]];
  } else if ([commandName isEqualToString:@"toggleH3"]) {
    [self toggleRegularStyle:[H3Style getType]];
  } else if ([commandName isEqualToString:@"toggleH4"]) {
    [self toggleRegularStyle:[H4Style getType]];
  } else if ([commandName isEqualToString:@"toggleH5"]) {
    [self toggleRegularStyle:[H5Style getType]];
  } else if ([commandName isEqualToString:@"toggleH6"]) {
    [self toggleRegularStyle:[H6Style getType]];
  } else if ([commandName isEqualToString:@"toggleUnorderedList"]) {
    [self toggleRegularStyle:[UnorderedListStyle getType]];
  } else if ([commandName isEqualToString:@"toggleOrderedList"]) {
    [self toggleRegularStyle:[OrderedListStyle getType]];
  } else if ([commandName isEqualToString:@"toggleCheckboxList"]) {
    BOOL checked = [args[0] boolValue];
    [self toggleCheckboxList:checked];
  } else if ([commandName isEqualToString:@"toggleBlockQuote"]) {
    [self toggleRegularStyle:[BlockQuoteStyle getType]];
  } else if ([commandName isEqualToString:@"toggleCodeBlock"]) {
    [self toggleRegularStyle:[CodeBlockStyle getType]];
  } else if ([commandName isEqualToString:@"addImage"]) {
    NSString *uri = (NSString *)args[0];
    CGFloat imgWidth = [(NSNumber *)args[1] floatValue];
    CGFloat imgHeight = [(NSNumber *)args[2] floatValue];

    [self addImage:uri width:imgWidth height:imgHeight];
  } else if ([commandName isEqualToString:@"setSelection"]) {
    NSInteger start = [((NSNumber *)args[0]) integerValue];
    NSInteger end = [((NSNumber *)args[1]) integerValue];
    [self setCustomSelection:start end:end];
  } else if ([commandName isEqualToString:@"requestHTML"]) {
    NSInteger requestId = [((NSNumber *)args[0]) integerValue];
    [self requestHTML:requestId];
  }
}

- (std::shared_ptr<EnrichedTextInputViewEventEmitter>)getEventEmitter {
  if (_eventEmitter != nullptr && !blockEmitting) {
    auto emitter =
        static_cast<const EnrichedTextInputViewEventEmitter &>(*_eventEmitter);
    return std::make_shared<EnrichedTextInputViewEventEmitter>(emitter);
  } else {
    return nullptr;
  }
}

- (void)blur {
  [textView reactBlur];
}

- (void)focus {
  [textView reactFocus];
}

- (void)setValue:(NSString *)value {
  NSString *initiallyProcessedHtml = [parser initiallyProcessHtml:value];
  if (initiallyProcessedHtml == nullptr) {
    // just plain text
    textView.text = value;
  } else {
    // we've got some seemingly proper html
    [parser replaceWholeFromHtml:initiallyProcessedHtml];
  }

  // set recentlyChangedRange and check for changes
  recentlyChangedRange = NSMakeRange(0, textView.textStorage.string.length);
  textView.selectedRange = NSRange(textView.textStorage.string.length, 0);
  [self anyTextMayHaveBeenModified];
}

- (void)setCustomSelection:(NSInteger)visibleStart end:(NSInteger)visibleEnd {
  NSString *text = textView.textStorage.string;

  NSUInteger actualStart = [self getActualIndex:visibleStart text:text];
  NSUInteger actualEnd = [self getActualIndex:visibleEnd text:text];

  textView.selectedRange = NSMakeRange(actualStart, actualEnd - actualStart);
}

// Helper: Walks through the string skipping ZWSPs to find the Nth visible
// character
- (NSUInteger)getActualIndex:(NSInteger)visibleIndex text:(NSString *)text {
  NSUInteger currentVisibleCount = 0;
  NSUInteger actualIndex = 0;

  while (actualIndex < text.length) {
    if (currentVisibleCount == visibleIndex) {
      return actualIndex;
    }

    // If the current char is not a hidden space, it counts towards our visible
    // index.
    if ([text characterAtIndex:actualIndex] != 0x200B) {
      currentVisibleCount++;
    }

    actualIndex++;
  }

  return actualIndex;
}

- (void)emitOnLinkDetectedEvent:(NSString *)text
                            url:(NSString *)url
                          range:(NSRange)range {
  auto emitter = [self getEventEmitter];
  if (emitter != nullptr) {
    // update recently active link info
    LinkData *newLinkData = [[LinkData alloc] init];
    newLinkData.text = text;
    newLinkData.url = url;
    _recentlyActiveLinkData = newLinkData;
    _recentlyActiveLinkRange = range;

    emitter->onLinkDetected({
        .text = [text toCppString],
        .url = [url toCppString],
        .start = static_cast<int>(range.location),
        .end = static_cast<int>(range.location + range.length),
    });
  }
}

- (void)emitOnMentionDetectedEvent:(NSString *)text
                         indicator:(NSString *)indicator
                        attributes:(NSString *)attributes {
  auto emitter = [self getEventEmitter];
  if (emitter != nullptr) {
    emitter->onMentionDetected({.text = [text toCppString],
                                .indicator = [indicator toCppString],
                                .payload = [attributes toCppString]});
  }
}

- (void)emitOnMentionEvent:(NSString *)indicator text:(NSString *)text {
  auto emitter = [self getEventEmitter];
  if (emitter != nullptr) {
    if (text != nullptr) {
      folly::dynamic fdStr = [text toCppString];
      emitter->onMention({.indicator = [indicator toCppString], .text = fdStr});
    } else {
      folly::dynamic nul = nullptr;
      emitter->onMention({.indicator = [indicator toCppString], .text = nul});
    }
  }
}

- (void)tryEmittingOnChangeHtmlEvent {
  if (!_emitHtml || textView.markedTextRange != nullptr) {
    return;
  }
  auto emitter = [self getEventEmitter];
  if (emitter != nullptr) {
    NSString *htmlOutput = [parser
        parseToHtmlFromRange:NSMakeRange(0,
                                         textView.textStorage.string.length)];
    // make sure html really changed
    if (![htmlOutput isEqualToString:_recentlyEmittedHtml]) {
      _recentlyEmittedHtml = htmlOutput;
      emitter->onChangeHtml({.value = [htmlOutput toCppString]});
    }
  }
}

- (void)requestHTML:(NSInteger)requestId {
  auto emitter = [self getEventEmitter];
  if (emitter != nullptr) {
    @try {
      NSString *htmlOutput = [parser
          parseToHtmlFromRange:NSMakeRange(0,
                                           textView.textStorage.string.length)];
      emitter->onRequestHtmlResult({.requestId = static_cast<int>(requestId),
                                    .html = [htmlOutput toCppString]});
    } @catch (NSException *exception) {
      emitter->onRequestHtmlResult({.requestId = static_cast<int>(requestId),
                                    .html = folly::dynamic(nullptr)});
    }
  }
}

- (void)emitOnKeyPressEvent:(NSString *)key {
  auto emitter = [self getEventEmitter];
  if (emitter != nullptr) {
    emitter->onInputKeyPress({.key = [key toCppString]});
  }
}

// MARK: - Styles manipulation

- (void)toggleRegularStyle:(StyleType)type {
  StyleBase *style = stylesDict[@(type)];
  NSRange range = textView.selectedRange;
  if ([style isParagraph]) {
    range = [textView.textStorage.string paragraphRangeForRange:range];
  }
  if ([self handleStyleBlocksAndConflicts:type range:range]) {
    [style toggle:range];
    [self anyTextMayHaveBeenModified];
  }
}

- (void)toggleCheckboxList:(BOOL)checked {
  CheckboxListStyle *style =
      (CheckboxListStyle *)stylesDict[@([CheckboxListStyle getType])];
  if (style == nullptr) {
    return;
  }
  NSRange range = [textView.textStorage.string
      paragraphRangeForRange:textView.selectedRange];
  if ([self handleStyleBlocksAndConflicts:[CheckboxListStyle getType]
                                    range:range]) {
    [style toggleWithChecked:checked range:range];
    [self anyTextMayHaveBeenModified];
  }
}

- (void)addLinkAt:(NSInteger)start
              end:(NSInteger)end
             text:(NSString *)text
              url:(NSString *)url {
  LinkStyle *linkStyleClass = (LinkStyle *)stylesDict[@([LinkStyle getType])];
  if (linkStyleClass == nullptr) {
    return;
  }

  // translate the output start-end notation to range
  NSRange linkRange = NSMakeRange(start, end - start);
  if ([self handleStyleBlocksAndConflicts:[LinkStyle getType]
                                    range:linkRange]) {
    [linkStyleClass addLink:text
                        url:url
                      range:linkRange
                     manual:YES
              withSelection:YES];
    [self anyTextMayHaveBeenModified];
  }
}

- (void)addMention:(NSString *)indicator
              text:(NSString *)text
        attributes:(NSString *)attributes {
  MentionStyle *mentionStyleClass =
      (MentionStyle *)stylesDict[@([MentionStyle getType])];
  if (mentionStyleClass == nullptr) {
    return;
  }
  if ([mentionStyleClass getActiveMentionRange] == nullptr) {
    return;
  }

  if ([self handleStyleBlocksAndConflicts:[MentionStyle getType]
                                    range:[[mentionStyleClass
                                              getActiveMentionRange]
                                              rangeValue]]) {
    [mentionStyleClass addMention:indicator text:text attributes:attributes];
    [self anyTextMayHaveBeenModified];
  }
}

- (void)addImage:(NSString *)uri width:(float)width height:(float)height {
  ImageStyle *imageStyleClass =
      (ImageStyle *)stylesDict[@([ImageStyle getType])];
  if (imageStyleClass == nullptr) {
    return;
  }

  if ([self handleStyleBlocksAndConflicts:[ImageStyle getType]
                                    range:textView.selectedRange]) {
    [imageStyleClass addImage:uri width:width height:height];
    [self anyTextMayHaveBeenModified];
  }
}

- (void)startMentionWithIndicator:(NSString *)indicator {
  MentionStyle *mentionStyleClass =
      (MentionStyle *)stylesDict[@([MentionStyle getType])];
  if (mentionStyleClass == nullptr) {
    return;
  }

  if ([self handleStyleBlocksAndConflicts:[MentionStyle getType]
                                    range:textView.selectedRange]) {
    [mentionStyleClass startMentionWithIndicator:indicator];
    [self anyTextMayHaveBeenModified];
  }
}

// returns false when style shouldn't be applied and true when it can be
- (BOOL)handleStyleBlocksAndConflicts:(StyleType)type range:(NSRange)range {
  // handle blocking styles: if any is present we do not apply the toggled style
  NSArray<NSNumber *> *blocking =
      [self getPresentStyleTypesFrom:blockingStyles[@(type)] range:range];
  if (blocking.count != 0) {
    return NO;
  }

  // handle conflicting styles: remove styles within the range
  NSArray<NSNumber *> *conflicting =
      [self getPresentStyleTypesFrom:conflictingStyles[@(type)] range:range];
  if (conflicting.count != 0) {
    for (NSNumber *type in conflicting) {
      StyleBase *style = stylesDict[type];

      if ([style isParagraph]) {
        // for paragraph styles we can just call remove since it will pick up
        // proper paragraph range
        [style remove:range withDirtyRange:YES];
      } else {
        // for inline styles we have to differentiate betweeen normal and typing
        // attributes removal
        range.length >= 1 ? [style remove:range withDirtyRange:YES]
                          : [style removeTyping];
      }
    }
  }
  return YES;
}

- (NSArray<NSNumber *> *)getPresentStyleTypesFrom:(NSArray<NSNumber *> *)types
                                            range:(NSRange)range {
  NSMutableArray<NSNumber *> *resultArray =
      [[NSMutableArray<NSNumber *> alloc] init];
  for (NSNumber *type in types) {
    StyleBase *style = stylesDict[type];

    if (range.length >= 1) {
      if ([style any:range]) {
        [resultArray addObject:type];
      }
    } else {
      if ([style detect:range]) {
        [resultArray addObject:type];
      }
    }
  }
  return resultArray;
}

- (void)manageSelectionBasedChanges {
  NSString *currentString = [textView.textStorage.string copy];

  MentionStyle *mentionStyleClass =
      (MentionStyle *)stylesDict[@([MentionStyle getType])];
  if (mentionStyleClass != nullptr) {
    if ([_recentInputString isEqualToString:currentString]) {
      [mentionStyleClass manageMentionEditing];
    }
  }

  // attributes manager handles proper typingAttributes at all times to properly
  // extend meta-attributes
  BOOL onlySelectionChanged =
      textView.selectedRange.length == 0 &&
      [_recentInputString isEqualToString:currentString];
  // We want to remember which attributes were removed as long as we stay at the
  // same position. This prevents a removed attribute from being re-applied from
  // the preceding character right after we toggled it off
  [attributesManager clearRemovedTypingAttributes];
  [attributesManager
      manageTypingAttributesWithOnlySelection:onlySelectionChanged];

  // always update active styles
  [self tryUpdatingActiveStyles];
}

- (void)handleWordModificationBasedChanges:(NSString *)word
                                   inRange:(NSRange)range {
  // manual links refreshing and automatic links detection handling
  LinkStyle *linkStyle = [stylesDict objectForKey:@([LinkStyle getType])];

  if (linkStyle != nullptr) {
    // manual links need to be handled first because they can block automatic
    // links after being refreshed
    [linkStyle handleManualLinks:word inRange:range];
    [linkStyle handleAutomaticLinks:word inRange:range];
  }
}

- (void)anyTextMayHaveBeenModified {
  // we don't do no text changes when working with iOS marked text
  if (textView.markedTextRange != nullptr) {
    return;
  }

  // zero width space adding or removal
  [ZeroWidthSpaceUtils handleZeroWidthSpacesInInput:self];

  // emptying input typing attributes management
  if (textView.textStorage.string.length == 0 &&
      _recentInputString.length > 0) {
    // reset typing attribtues
    textView.typingAttributes = defaultTypingAttributes;
  }

  MentionStyle *mentionStyleClass =
      (MentionStyle *)stylesDict[@([MentionStyle getType])];
  if (mentionStyleClass != nullptr) {
    [mentionStyleClass handleExistingMentions];
    [mentionStyleClass manageMentionEditing];
  }

  // placholder management
  [textView updatePlaceholderVisibility];

  if (![textView.textStorage.string isEqualToString:_recentInputString]) {
    // modified words handling
    NSArray *modifiedWords =
        [WordsUtils getAffectedWordsFromText:textView.textStorage.string
                           modificationRange:recentlyChangedRange];
    if (modifiedWords != nullptr) {
      for (NSDictionary *wordDict in modifiedWords) {
        NSString *wordText = (NSString *)[wordDict objectForKey:@"word"];
        NSValue *wordRange = (NSValue *)[wordDict objectForKey:@"range"];

        if (wordText == nullptr || wordRange == nullptr) {
          continue;
        }

        [self handleWordModificationBasedChanges:wordText
                                         inRange:[wordRange rangeValue]];
      }
    }

    // emit onChangeText event
    auto emitter = [self getEventEmitter];
    if (emitter != nullptr && _emitTextChange) {
      // set the recent input string only if the emitter is defined
      _recentInputString = [textView.textStorage.string copy];

      // emit string without zero width spaces
      NSString *stringToBeEmitted = [[textView.textStorage.string
          stringByReplacingOccurrencesOfString:@"\u200B"
                                    withString:@""] copy];

      emitter->onChangeText({.value = [stringToBeEmitted toCppString]});
    }
  }
  // all the visible (not meta) attributes handling in the ranges that could
  // have changed
  [attributesManager handleDirtyRangesStyling];
  // update active styles as well
  [self tryUpdatingActiveStyles];
}

// MARK: - Delegate methods

- (void)textViewDidBeginEditing:(UITextView *)textView {
  auto emitter = [self getEventEmitter];
  if (emitter != nullptr) {
    // send onFocus event if allowed
    if (_emitFocusBlur) {
      emitter->onInputFocus({});
    }

    NSString *textAtSelection =
        [[[NSMutableString alloc] initWithString:textView.textStorage.string]
            substringWithRange:textView.selectedRange];
    emitter->onChangeSelection(
        {.start = static_cast<int>(textView.selectedRange.location),
         .end = static_cast<int>(textView.selectedRange.location +
                                 textView.selectedRange.length),
         .text = [textAtSelection toCppString]});
  }
  // manage selection changes since textViewDidChangeSelection sometimes doesn't
  // run on focus
  [self manageSelectionBasedChanges];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
  auto emitter = [self getEventEmitter];
  if (emitter != nullptr && _emitFocusBlur) {
    // send onBlur event
    emitter->onInputBlur({});
  }
}

- (void)handleKeyPressInRange:(NSString *)text range:(NSRange)range {
  NSString *key = nil;

  if (text.length == 0 && range.length > 0) {
    key = @"Backspace";
  } else if ([text isEqualToString:@"\n"]) {
    key = @"Enter";
  } else if ([text isEqualToString:@"\t"]) {
    key = @"Tab";
  } else if (text.length == 1) {
    key = text;
  }

  if (key != nil) {
    [self emitOnKeyPressEvent:key];
  }
}

- (bool)textView:(UITextView *)textView
    shouldChangeTextInRange:(NSRange)range
            replacementText:(NSString *)text {
  recentlyChangedRange = NSMakeRange(range.location, text.length);
  [self handleKeyPressInRange:text range:range];

  UnorderedListStyle *uStyle = stylesDict[@([UnorderedListStyle getType])];
  OrderedListStyle *oStyle = stylesDict[@([OrderedListStyle getType])];
  CheckboxListStyle *cbLStyle =
      (CheckboxListStyle *)stylesDict[@([CheckboxListStyle getType])];
  MentionStyle *mentionStyle =
      (MentionStyle *)stylesDict[@([MentionStyle getType])];
  LinkStyle *linkStyle = (LinkStyle *)stylesDict[@([LinkStyle getType])];
  H1Style *h1Style = stylesDict[@([H1Style getType])];
  H2Style *h2Style = stylesDict[@([H2Style getType])];
  H3Style *h3Style = stylesDict[@([H3Style getType])];
  H4Style *h4Style = stylesDict[@([H4Style getType])];
  H5Style *h5Style = stylesDict[@([H5Style getType])];
  H6Style *h6Style = stylesDict[@([H6Style getType])];

  // some of the changes these checks do could interfere with later checks and
  // cause a crash so here I rely on short circuiting evaluation of the logical
  // expression either way it's not possible to have two of them come off at the
  // same time
  if (
      // ZWS backspace handling for paragraph styles
      [ZeroWidthSpaceUtils handleBackspaceInRange:range
                                  replacementText:text
                                            input:self] ||
      [uStyle tryHandlingListShorcutInRange:range replacementText:text] ||
      [oStyle tryHandlingListShorcutInRange:range replacementText:text] ||
      [cbLStyle handleNewlinesInRange:range replacementText:text] ||
      [linkStyle handleLeadingLinkReplacement:range replacementText:text] ||
      [mentionStyle handleLeadingMentionReplacement:range
                                    replacementText:text] ||
      [h1Style handleNewlinesInRange:range replacementText:text] ||
      [h2Style handleNewlinesInRange:range replacementText:text] ||
      [h3Style handleNewlinesInRange:range replacementText:text] ||
      [h4Style handleNewlinesInRange:range replacementText:text] ||
      [h5Style handleNewlinesInRange:range replacementText:text] ||
      [h6Style handleNewlinesInRange:range replacementText:text] ||
      [ParagraphAttributesUtils handleBackspaceInRange:range
                                       replacementText:text
                                                 input:self] ||
      [ParagraphAttributesUtils handleResetTypingAttributesOnBackspace:range
                                                       replacementText:text
                                                                 input:self]

      //       CRITICAL: This callback HAS TO be always evaluated last.
      //
      //       This function is the "Generic Fallback": if no specific style
      //       claims the backspace action to change its state, only then do we
      //       proceed to physically delete the newline and merge paragraphs.
      ||
      [ParagraphAttributesUtils handleParagraphStylesMergeOnBackspace:range
                                                      replacementText:text
                                                                input:self]) {
    [self anyTextMayHaveBeenModified];
    return NO;
  }

  return YES;
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
  // emit the event
  NSString *textAtSelection =
      [[[NSMutableString alloc] initWithString:textView.textStorage.string]
          substringWithRange:textView.selectedRange];

  auto emitter = [self getEventEmitter];
  if (emitter != nullptr) {
    // iOS range works differently because it specifies location and length
    // here, start is the location, but end is the first index BEHIND the end.
    // So a 0 length range will have equal start and end
    emitter->onChangeSelection(
        {.start = static_cast<int>(textView.selectedRange.location),
         .end = static_cast<int>(textView.selectedRange.location +
                                 textView.selectedRange.length),
         .text = [textAtSelection toCppString]});
  }

  // manage selection changes
  [self manageSelectionBasedChanges];
}

// this function isn't called always when some text changes (for example setting
// link or starting mention with indicator doesn't fire it) so all the logic is
// in anyTextMayHaveBeenModified
- (void)textViewDidChange:(UITextView *)textView {
  [self anyTextMayHaveBeenModified];
}

/**
 * Handles iOS Dynamic Type changes (User changing font size in System
 * Settings).
 *
 * Unlike Android, iOS Views do not automatically rescale existing
 * NSAttributedStrings when the system font size changes. The text attributes
 * are static once drawn.
 *
 * This method detects the change and performs a "Hard Refresh" of the content.
 */
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
  [super traitCollectionDidChange:previousTraitCollection];

  if (previousTraitCollection.preferredContentSizeCategory !=
      self.traitCollection.preferredContentSizeCategory) {
    [config invalidateFonts];

    NSMutableDictionary *newTypingAttrs = [defaultTypingAttributes mutableCopy];
    newTypingAttrs[NSFontAttributeName] = [config primaryFont];

    defaultTypingAttributes = newTypingAttrs;
    textView.typingAttributes = defaultTypingAttributes;

    [textView refreshPlaceholder];

    NSRange prevSelectedRange = textView.selectedRange;

    NSString *currentHtml = [parser
        parseToHtmlFromRange:NSMakeRange(0,
                                         textView.textStorage.string.length)];
    NSString *initiallyProcessedHtml =
        [parser initiallyProcessHtml:currentHtml];
    [parser replaceWholeFromHtml:initiallyProcessedHtml];

    textView.selectedRange = prevSelectedRange;
    [self anyTextMayHaveBeenModified];
  }
}

- (void)onTextBlockTap:(TextBlockTapGestureRecognizer *)gr {
  if (gr.state != UIGestureRecognizerStateEnded)
    return;
  if (![self->textView isFirstResponder]) {
    [self->textView becomeFirstResponder];
  }

  switch (gr.tapKind) {

  case TextBlockTapKindCheckbox: {
    CheckboxListStyle *checkboxStyle =
        (CheckboxListStyle *)stylesDict[@([CheckboxListStyle getType])];

    if (checkboxStyle) {
      NSUInteger charIndex = (NSUInteger)gr.characterIndex;
      [checkboxStyle toggleCheckedAt:charIndex];
      [self anyTextMayHaveBeenModified];

      NSString *fullText = textView.textStorage.string;
      NSRange paragraphRange =
          [fullText paragraphRangeForRange:NSMakeRange(charIndex, 0)];
      NSUInteger endOfLineIndex = NSMaxRange(paragraphRange);

      // If the paragraph ends with a newline, step back by 1 so the cursor
      // stays on the current line instead of jumping to the next one.
      if (endOfLineIndex > 0 && endOfLineIndex <= fullText.length) {
        unichar lastChar = [fullText characterAtIndex:endOfLineIndex - 1];
        if ([[NSCharacterSet newlineCharacterSet] characterIsMember:lastChar]) {
          endOfLineIndex--;
        }
      }

      // Move the cursor to the end of the currently tapped checkbox line.
      // Without this, the cursor may remain at its previous position,
      // potentially inside a different checkbox line.
      textView.selectedRange = NSMakeRange(endOfLineIndex, 0);
    }
    break;
  }

  default:
    break;
  }
}

- (void)textStorage:(NSTextStorage *)textStorage
    didProcessEditing:(NSTextStorageEditActions)editedMask
                range:(NSRange)editedRange
       changeInLength:(NSInteger)delta {
  // iOS replacing quick double space with ". " attributes fix.
  [DotReplacementUtils handleDotReplacement:self
                                textStorage:textStorage
                                 editedMask:editedMask
                                editedRange:editedRange
                                      delta:delta];

  // Needed dirty ranges adjustments happen on every character edition.
  if ((editedMask & NSTextStorageEditedCharacters) != 0) {
    // Always try shifting dirty ranges (happens only with delta != 0).
    [attributesManager shiftDirtyRangesWithEditedRange:editedRange
                                        changeInLength:delta];

    // Always try adding new dirty range (happens only with editedRange.length >
    // 0).
    [attributesManager addDirtyRange:editedRange];
  }
}

// MARK: - Media attachments delegate

- (void)mediaAttachmentDidUpdate:(NSTextAttachment *)attachment {
  NSTextStorage *storage = textView.textStorage;
  NSRange fullRange = NSMakeRange(0, storage.length);

  __block NSRange foundRange = NSMakeRange(NSNotFound, 0);

  [storage enumerateAttribute:NSAttachmentAttributeName
                      inRange:fullRange
                      options:0
                   usingBlock:^(id value, NSRange range, BOOL *stop) {
                     if (value == attachment) {
                       foundRange = range;
                       *stop = YES;
                     }
                   }];

  if (foundRange.location == NSNotFound) {
    return;
  }

  [storage edited:NSTextStorageEditedAttributes
               range:foundRange
      changeInLength:0];
}

@end
