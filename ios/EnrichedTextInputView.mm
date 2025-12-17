#import "EnrichedTextInputView.h"
#import "CoreText/CoreText.h"
#import "LayoutManagerExtension.h"
#import "ParagraphAttributesUtils.h"
#import "RCTFabricComponentsPlugins.h"
#import "StringExtension.h"
#import "StyleHeaders.h"
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

using namespace facebook::react;

@interface EnrichedTextInputView () <RCTEnrichedTextInputViewViewProtocol,
                                     UITextViewDelegate, NSObject>

@end

@implementation EnrichedTextInputView {
  EnrichedTextInputViewShadowNode::ConcreteState::Shared _state;
  int _componentViewHeightUpdateCounter;
  NSMutableSet<NSNumber *> *_activeStyles;
  LinkData *_recentlyActiveLinkData;
  NSRange _recentlyActiveLinkRange;
  NSString *_recentlyEmittedString;
  MentionParams *_recentlyActiveMentionParams;
  NSRange _recentlyActiveMentionRange;
  NSString *_recentlyEmittedHtml;
  BOOL _emitHtml;
  UILabel *_placeholderLabel;
  UIColor *_placeholderColor;
  BOOL _emitFocusBlur;
  BOOL _didRunInitialMount;
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
    [self setupPlaceholderLabel];
    self.contentView = textView;
  }
  return self;
}

- (void)setDefaults {
  _componentViewHeightUpdateCounter = 0;
  _activeStyles = [[NSMutableSet alloc] init];
  _recentlyActiveLinkRange = NSMakeRange(0, 0);
  _recentlyActiveMentionRange = NSMakeRange(0, 0);
  recentlyChangedRange = NSMakeRange(0, 0);
  _recentlyEmittedString = @"";
  _recentlyEmittedHtml = @"<html>\n<p></p>\n</html>";
  _emitHtml = NO;
  blockEmitting = NO;
  _emitFocusBlur = YES;

  defaultTypingAttributes =
      [[NSMutableDictionary<NSAttributedStringKey, id> alloc] init];

  stylesDict = @{
    @([BoldStyle getStyleType]) : [[BoldStyle alloc] initWithInput:self],
    @([ItalicStyle getStyleType]) : [[ItalicStyle alloc] initWithInput:self],
    @([UnderlineStyle getStyleType]) :
        [[UnderlineStyle alloc] initWithInput:self],
    @([StrikethroughStyle getStyleType]) :
        [[StrikethroughStyle alloc] initWithInput:self],
    @([InlineCodeStyle getStyleType]) :
        [[InlineCodeStyle alloc] initWithInput:self],
    @([LinkStyle getStyleType]) : [[LinkStyle alloc] initWithInput:self],
    @([MentionStyle getStyleType]) : [[MentionStyle alloc] initWithInput:self],
    @([H1Style getStyleType]) : [[H1Style alloc] initWithInput:self],
    @([H2Style getStyleType]) : [[H2Style alloc] initWithInput:self],
    @([H3Style getStyleType]) : [[H3Style alloc] initWithInput:self],
    @([UnorderedListStyle getStyleType]) :
        [[UnorderedListStyle alloc] initWithInput:self],
    @([OrderedListStyle getStyleType]) :
        [[OrderedListStyle alloc] initWithInput:self],
    @([BlockQuoteStyle getStyleType]) :
        [[BlockQuoteStyle alloc] initWithInput:self],
    @([CodeBlockStyle getStyleType]) :
        [[CodeBlockStyle alloc] initWithInput:self],
    @([ImageStyle getStyleType]) : [[ImageStyle alloc] initWithInput:self]
  };

  conflictingStyles = @{
    @([BoldStyle getStyleType]) : @[],
    @([ItalicStyle getStyleType]) : @[],
    @([UnderlineStyle getStyleType]) : @[],
    @([StrikethroughStyle getStyleType]) : @[],
    @([InlineCodeStyle getStyleType]) :
        @[ @([LinkStyle getStyleType]), @([MentionStyle getStyleType]) ],
    @([LinkStyle getStyleType]) : @[
      @([InlineCodeStyle getStyleType]), @([LinkStyle getStyleType]),
      @([MentionStyle getStyleType])
    ],
    @([MentionStyle getStyleType]) :
        @[ @([InlineCodeStyle getStyleType]), @([LinkStyle getStyleType]) ],
    @([H1Style getStyleType]) : @[
      @([H2Style getStyleType]), @([H3Style getStyleType]),
      @([UnorderedListStyle getStyleType]), @([OrderedListStyle getStyleType]),
      @([BlockQuoteStyle getStyleType]), @([CodeBlockStyle getStyleType])
    ],
    @([H2Style getStyleType]) : @[
      @([H1Style getStyleType]), @([H3Style getStyleType]),
      @([UnorderedListStyle getStyleType]), @([OrderedListStyle getStyleType]),
      @([BlockQuoteStyle getStyleType]), @([CodeBlockStyle getStyleType])
    ],
    @([H3Style getStyleType]) : @[
      @([H1Style getStyleType]), @([H2Style getStyleType]),
      @([UnorderedListStyle getStyleType]), @([OrderedListStyle getStyleType]),
      @([BlockQuoteStyle getStyleType]), @([CodeBlockStyle getStyleType])
    ],
    @([UnorderedListStyle getStyleType]) : @[
      @([H1Style getStyleType]), @([H2Style getStyleType]),
      @([H3Style getStyleType]), @([OrderedListStyle getStyleType]),
      @([BlockQuoteStyle getStyleType]), @([CodeBlockStyle getStyleType])
    ],
    @([OrderedListStyle getStyleType]) : @[
      @([H1Style getStyleType]), @([H2Style getStyleType]),
      @([H3Style getStyleType]), @([UnorderedListStyle getStyleType]),
      @([BlockQuoteStyle getStyleType]), @([CodeBlockStyle getStyleType])
    ],
    @([BlockQuoteStyle getStyleType]) : @[
      @([H1Style getStyleType]), @([H2Style getStyleType]),
      @([H3Style getStyleType]), @([UnorderedListStyle getStyleType]),
      @([OrderedListStyle getStyleType]), @([CodeBlockStyle getStyleType])
    ],
    @([CodeBlockStyle getStyleType]) : @[
      @([H1Style getStyleType]), @([H2Style getStyleType]),
      @([H3Style getStyleType]), @([BoldStyle getStyleType]),
      @([ItalicStyle getStyleType]), @([UnderlineStyle getStyleType]),
      @([StrikethroughStyle getStyleType]),
      @([UnorderedListStyle getStyleType]), @([OrderedListStyle getStyleType]),
      @([BlockQuoteStyle getStyleType]), @([InlineCodeStyle getStyleType]),
      @([MentionStyle getStyleType]), @([LinkStyle getStyleType])
    ],
    @([ImageStyle getStyleType]) :
        @[ @([LinkStyle getStyleType]), @([MentionStyle getStyleType]) ]
  };

  blockingStyles = @{
    @([BoldStyle getStyleType]) : @[ @([CodeBlockStyle getStyleType]) ],
    @([ItalicStyle getStyleType]) : @[ @([CodeBlockStyle getStyleType]) ],
    @([UnderlineStyle getStyleType]) : @[ @([CodeBlockStyle getStyleType]) ],
    @([StrikethroughStyle getStyleType]) :
        @[ @([CodeBlockStyle getStyleType]) ],
    @([InlineCodeStyle getStyleType]) :
        @[ @([CodeBlockStyle getStyleType]), @([ImageStyle getStyleType]) ],
    @([LinkStyle getStyleType]) :
        @[ @([CodeBlockStyle getStyleType]), @([ImageStyle getStyleType]) ],
    @([MentionStyle getStyleType]) :
        @[ @([CodeBlockStyle getStyleType]), @([ImageStyle getStyleType]) ],
    @([H1Style getStyleType]) : @[],
    @([H2Style getStyleType]) : @[],
    @([H3Style getStyleType]) : @[],
    @([UnorderedListStyle getStyleType]) : @[],
    @([OrderedListStyle getStyleType]) : @[],
    @([BlockQuoteStyle getStyleType]) : @[],
    @([CodeBlockStyle getStyleType]) : @[],
    @([ImageStyle getStyleType]) : @[ @([InlineCodeStyle getStyleType]) ]
  };

  parser = [[InputParser alloc] initWithInput:self];
}

- (void)setupTextView {
  textView = [[InputTextView alloc] init];
  textView.backgroundColor = UIColor.clearColor;
  textView.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
  textView.textContainer.lineFragmentPadding = 0;
  textView.delegate = self;
  textView.input = self;
  textView.layoutManager.input = self;
}

- (void)setupPlaceholderLabel {
  _placeholderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  _placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [textView addSubview:_placeholderLabel];
  [NSLayoutConstraint activateConstraints:@[
    [_placeholderLabel.leadingAnchor
        constraintEqualToAnchor:textView.leadingAnchor],
    [_placeholderLabel.widthAnchor
        constraintEqualToAnchor:textView.widthAnchor],
    [_placeholderLabel.topAnchor constraintEqualToAnchor:textView.topAnchor],
    [_placeholderLabel.bottomAnchor
        constraintEqualToAnchor:textView.bottomAnchor]
  ]];
  _placeholderLabel.lineBreakMode = NSLineBreakByTruncatingTail;
  _placeholderLabel.text = @"";
  _placeholderLabel.hidden = YES;
}

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
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h2.fontSize !=
      oldViewProps.htmlStyle.h2.fontSize) {
    [newConfig setH2FontSize:newViewProps.htmlStyle.h2.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h2.bold != oldViewProps.htmlStyle.h2.bold) {
    [newConfig setH2Bold:newViewProps.htmlStyle.h2.bold];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h3.fontSize !=
      oldViewProps.htmlStyle.h3.fontSize) {
    [newConfig setH3FontSize:newViewProps.htmlStyle.h3.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h3.bold != oldViewProps.htmlStyle.h3.bold) {
    [newConfig setH3Bold:newViewProps.htmlStyle.h3.bold];
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

  BOOL defaultValueChanged =
      newViewProps.defaultValue != oldViewProps.defaultValue;

  if (stylePropChanged) {
    // now set the new config
    config = newConfig;

    // we already applied html with styles in default value
    if (!defaultValueChanged) {
      // all the text needs to be rebuilt
      // we get the current html using old config, then switch to new config and
      // replace text using the html this way, the newest config attributes are
      // being used!

      // the html needs to be generated using the old config
      NSString *currentHtml = [parser
          parseToHtmlFromRange:NSMakeRange(0,
                                           textView.textStorage.string.length)];
      // no emitting during styles reload
      blockEmitting = YES;

      // make sure everything is sound in the html
      NSString *initiallyProcessedHtml =
          [parser initiallyProcessHtml:currentHtml];
      if (initiallyProcessedHtml != nullptr) {
        [parser replaceWholeFromHtml:initiallyProcessedHtml
            notifyAnyTextMayHaveBeenModified:!isFirstMount];
      }

      blockEmitting = NO;
    }

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

    // update the placeholder as well
    [self refreshPlaceholderLabelStyles];
  }

  // editable
  if (newViewProps.editable != textView.editable) {
    textView.editable = newViewProps.editable;
  }

  // default value - must be set before placeholder to make sure it correctly
  // shows on first mount
  if (defaultValueChanged) {
    NSString *newDefaultValue =
        [NSString fromCppString:newViewProps.defaultValue];

    NSString *initiallyProcessedHtml =
        [parser initiallyProcessHtml:newDefaultValue];
    if (initiallyProcessedHtml == nullptr) {
      // just plain text
      textView.text = newDefaultValue;
    } else {
      // we've got some seemingly proper html
      [parser replaceWholeFromHtml:initiallyProcessedHtml
          notifyAnyTextMayHaveBeenModified:!isFirstMount];
    }
  }

  // placeholderTextColor
  if (newViewProps.placeholderTextColor != oldViewProps.placeholderTextColor) {
    // some real color
    if (isColorMeaningful(newViewProps.placeholderTextColor)) {
      _placeholderColor =
          RCTUIColorFromSharedColor(newViewProps.placeholderTextColor);
    } else {
      _placeholderColor = nullptr;
    }
    [self refreshPlaceholderLabelStyles];
  }

  // placeholder
  if (newViewProps.placeholder != oldViewProps.placeholder) {
    _placeholderLabel.text = [NSString fromCppString:newViewProps.placeholder];
    [self refreshPlaceholderLabelStyles];
    // additionally show placeholder on first mount if it should be there
    if (isFirstMount && textView.text.length == 0) {
      [self setPlaceholderLabelShown:YES];
    }
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

  [super updateProps:props oldProps:oldProps];

  // if default value changed it will be fired in default value update
  // if this is initial mount it will be called in didMoveToWindow
  if (!defaultValueChanged && !isFirstMount) {
    // run the changes callback
    [self anyTextMayHaveBeenModified];
  }

  // autofocus - needs to be done at the very end
  if (isFirstMount && newViewProps.autoFocus) {
    [textView reactFocus];
  }
}

- (void)setPlaceholderLabelShown:(BOOL)shown {
  if (shown) {
    [self refreshPlaceholderLabelStyles];
    _placeholderLabel.hidden = NO;
  } else {
    _placeholderLabel.hidden = YES;
  }
}

- (void)refreshPlaceholderLabelStyles {
  NSMutableDictionary *newAttrs = [defaultTypingAttributes mutableCopy];
  if (_placeholderColor != nullptr) {
    newAttrs[NSForegroundColorAttributeName] = _placeholderColor;
  }
  NSAttributedString *newAttrStr =
      [[NSAttributedString alloc] initWithString:_placeholderLabel.text
                                      attributes:newAttrs];
  _placeholderLabel.attributedText = newAttrStr;
}

// MARK: - Measuring and states

- (CGSize)measureSize:(CGFloat)maxWidth {
  // copy the the whole attributed string
  NSMutableAttributedString *currentStr = [[NSMutableAttributedString alloc]
      initWithAttributedString:textView.textStorage];

  // edge case: empty input should still be of a height of a single line, so we
  // add a mock "I" character
  if ([currentStr length] == 0) {
    [currentStr
        appendAttributedString:[[NSAttributedString alloc]
                                   initWithString:@"I"
                                       attributes:textView.typingAttributes]];
  }

  // edge case: input with only a zero width space should still be of a height
  // of a single line, so we add a mock "I" character
  if ([currentStr length] == 1 &&
      [[currentStr.string substringWithRange:NSMakeRange(0, 1)]
          isEqualToString:@"\u200B"]) {
    [currentStr
        appendAttributedString:[[NSAttributedString alloc]
                                   initWithString:@"I"
                                       attributes:textView.typingAttributes]];
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

// make sure the newest state is kept in _state property
- (void)updateState:(State::Shared const &)state
           oldState:(State::Shared const &)oldState {
  _state = std::static_pointer_cast<
      const EnrichedTextInputViewShadowNode::ConcreteState>(state);

  // first render with all the needed stuff already defined (state and
  // componentView) so we need to run a single height calculation for any
  // initial values
  if (oldState == nullptr) {
    [self tryUpdatingHeight];
  }
}

- (void)tryUpdatingHeight {
  if (_state == nullptr) {
    return;
  }
  _componentViewHeightUpdateCounter++;
  auto selfRef = wrapManagedObjectWeakly(self);
  _state->updateState(
      EnrichedTextInputViewState(_componentViewHeightUpdateCounter, selfRef));
}

// MARK: - Active styles

- (void)tryUpdatingActiveStyles {
  // style updates are emitted only if something differs from the previously
  // active styles
  BOOL updateNeeded = NO;

  // active styles are kept in a separate set until we're sure they can be
  // emitted
  NSMutableSet *newActiveStyles = [_activeStyles mutableCopy];

  // data for onLinkDetected event
  LinkData *detectedLinkData;
  NSRange detectedLinkRange = NSMakeRange(0, 0);

  // data for onMentionDetected event
  MentionParams *detectedMentionParams;
  NSRange detectedMentionRange = NSMakeRange(0, 0);

  for (NSNumber *type in stylesDict) {
    id<BaseStyleProtocol> style = stylesDict[type];
    BOOL wasActive = [newActiveStyles containsObject:type];
    BOOL isActive = [style detectStyle:textView.selectedRange];
    if (wasActive != isActive) {
      updateNeeded = YES;
      if (isActive) {
        [newActiveStyles addObject:type];
      } else {
        [newActiveStyles removeObject:type];
      }
    }

    // onLinkDetected event
    if (isActive && [type intValue] == [LinkStyle getStyleType]) {
      // get the link data
      LinkData *candidateLinkData;
      NSRange candidateLinkRange = NSMakeRange(0, 0);
      LinkStyle *linkStyleClass =
          (LinkStyle *)stylesDict[@([LinkStyle getStyleType])];
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
        // we changed selection from one link to the other or modified current
        // link's text
        detectedLinkData = candidateLinkData;
        detectedLinkRange = candidateLinkRange;
      }
    }

    // onMentionDetected event
    if (isActive && [type intValue] == [MentionStyle getStyleType]) {
      // get mention data
      MentionParams *candidateMentionParams;
      NSRange candidateMentionRange = NSMakeRange(0, 0);
      MentionStyle *mentionStyleClass =
          (MentionStyle *)stylesDict[@([MentionStyle getStyleType])];
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
      // update activeStyles only if emitter is available
      _activeStyles = newActiveStyles;

      emitter->onChangeState({
        .isBold = [_activeStyles containsObject:@([BoldStyle getStyleType])],
        .isItalic =
            [_activeStyles containsObject:@([ItalicStyle getStyleType])],
        .isUnderline =
            [_activeStyles containsObject:@([UnderlineStyle getStyleType])],
        .isStrikeThrough =
            [_activeStyles containsObject:@([StrikethroughStyle getStyleType])],
        .isInlineCode =
            [_activeStyles containsObject:@([InlineCodeStyle getStyleType])],
        .isLink = [_activeStyles containsObject:@([LinkStyle getStyleType])],
        .isMention =
            [_activeStyles containsObject:@([MentionStyle getStyleType])],
        .isH1 = [_activeStyles containsObject:@([H1Style getStyleType])],
        .isH2 = [_activeStyles containsObject:@([H2Style getStyleType])],
        .isH3 = [_activeStyles containsObject:@([H3Style getStyleType])],
        .isUnorderedList =
            [_activeStyles containsObject:@([UnorderedListStyle getStyleType])],
        .isOrderedList =
            [_activeStyles containsObject:@([OrderedListStyle getStyleType])],
        .isBlockQuote =
            [_activeStyles containsObject:@([BlockQuoteStyle getStyleType])],
        .isCodeBlock =
            [_activeStyles containsObject:@([CodeBlockStyle getStyleType])],
        .isImage = [_activeStyles containsObject:@([ImageStyle getStyleType])],
      });
    }
  }

  if (detectedLinkData != nullptr) {
    // emit onLinkeDetected event
    [self emitOnLinkDetectedEvent:detectedLinkData.text
                              url:detectedLinkData.url
                            range:detectedLinkRange];
  }

  if (detectedMentionParams != nullptr) {
    // emit onMentionDetected event
    [self emitOnMentionDetectedEvent:detectedMentionParams.text
                           indicator:detectedMentionParams.indicator
                          attributes:detectedMentionParams.attributes];

    _recentlyActiveMentionParams = detectedMentionParams;
    _recentlyActiveMentionRange = detectedMentionRange;
  }

  // emit onChangeHtml event if needed
  [self tryEmittingOnChangeHtmlEvent];
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
    [self toggleRegularStyle:[BoldStyle getStyleType]];
  } else if ([commandName isEqualToString:@"toggleItalic"]) {
    [self toggleRegularStyle:[ItalicStyle getStyleType]];
  } else if ([commandName isEqualToString:@"toggleUnderline"]) {
    [self toggleRegularStyle:[UnderlineStyle getStyleType]];
  } else if ([commandName isEqualToString:@"toggleStrikeThrough"]) {
    [self toggleRegularStyle:[StrikethroughStyle getStyleType]];
  } else if ([commandName isEqualToString:@"toggleInlineCode"]) {
    [self toggleRegularStyle:[InlineCodeStyle getStyleType]];
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
    [self toggleParagraphStyle:[H1Style getStyleType]];
  } else if ([commandName isEqualToString:@"toggleH2"]) {
    [self toggleParagraphStyle:[H2Style getStyleType]];
  } else if ([commandName isEqualToString:@"toggleH3"]) {
    [self toggleParagraphStyle:[H3Style getStyleType]];
  } else if ([commandName isEqualToString:@"toggleUnorderedList"]) {
    [self toggleParagraphStyle:[UnorderedListStyle getStyleType]];
  } else if ([commandName isEqualToString:@"toggleOrderedList"]) {
    [self toggleParagraphStyle:[OrderedListStyle getStyleType]];
  } else if ([commandName isEqualToString:@"toggleBlockQuote"]) {
    [self toggleParagraphStyle:[BlockQuoteStyle getStyleType]];
  } else if ([commandName isEqualToString:@"toggleCodeBlock"]) {
    [self toggleParagraphStyle:[CodeBlockStyle getStyleType]];
  } else if ([commandName isEqualToString:@"addImage"]) {
    NSString *uri = (NSString *)args[0];
    CGFloat imgWidth = [(NSNumber *)args[1] floatValue];
    CGFloat imgHeight = [(NSNumber *)args[2] floatValue];

    [self addImage:uri width:imgWidth height:imgHeight];
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
    [parser replaceWholeFromHtml:initiallyProcessedHtml
        notifyAnyTextMayHaveBeenModified:YES];
  }

  // set recentlyChangedRange and check for changes
  recentlyChangedRange = NSMakeRange(0, textView.textStorage.string.length);
  [self anyTextMayHaveBeenModified];
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

// MARK: - Styles manipulation

- (void)toggleRegularStyle:(StyleType)type {
  id<BaseStyleProtocol> styleClass = stylesDict[@(type)];

  if ([self handleStyleBlocksAndConflicts:type range:textView.selectedRange]) {
    [styleClass applyStyle:textView.selectedRange];
    [self anyTextMayHaveBeenModified];
  }
}

- (void)toggleParagraphStyle:(StyleType)type {
  id<BaseStyleProtocol> styleClass = stylesDict[@(type)];
  // we always pass whole paragraph/s range to these styles
  NSRange paragraphRange = [textView.textStorage.string
      paragraphRangeForRange:textView.selectedRange];

  if ([self handleStyleBlocksAndConflicts:type range:paragraphRange]) {
    [styleClass applyStyle:paragraphRange];
    [self anyTextMayHaveBeenModified];
  }
}

- (void)addLinkAt:(NSInteger)start
              end:(NSInteger)end
             text:(NSString *)text
              url:(NSString *)url {
  LinkStyle *linkStyleClass =
      (LinkStyle *)stylesDict[@([LinkStyle getStyleType])];
  if (linkStyleClass == nullptr) {
    return;
  }

  // translate the output start-end notation to range
  NSRange linkRange = NSMakeRange(start, end - start);
  if ([self handleStyleBlocksAndConflicts:[LinkStyle getStyleType]
                                    range:linkRange]) {
    [linkStyleClass addLink:text url:url range:linkRange manual:YES];
    [self anyTextMayHaveBeenModified];
  }
}

- (void)addMention:(NSString *)indicator
              text:(NSString *)text
        attributes:(NSString *)attributes {
  MentionStyle *mentionStyleClass =
      (MentionStyle *)stylesDict[@([MentionStyle getStyleType])];
  if (mentionStyleClass == nullptr) {
    return;
  }
  if ([mentionStyleClass getActiveMentionRange] == nullptr) {
    return;
  }

  if ([self handleStyleBlocksAndConflicts:[MentionStyle getStyleType]
                                    range:[[mentionStyleClass
                                              getActiveMentionRange]
                                              rangeValue]]) {
    [mentionStyleClass addMention:indicator text:text attributes:attributes];
    [self anyTextMayHaveBeenModified];
  }
}

- (void)addImage:(NSString *)uri width:(float)width height:(float)height {
  ImageStyle *imageStyleClass =
      (ImageStyle *)stylesDict[@([ImageStyle getStyleType])];
  if (imageStyleClass == nullptr) {
    return;
  }

  if ([self handleStyleBlocksAndConflicts:[ImageStyle getStyleType]
                                    range:textView.selectedRange]) {
    [imageStyleClass addImage:uri width:width height:height];
    [self anyTextMayHaveBeenModified];
  }
}

- (void)startMentionWithIndicator:(NSString *)indicator {
  MentionStyle *mentionStyleClass =
      (MentionStyle *)stylesDict[@([MentionStyle getStyleType])];
  if (mentionStyleClass == nullptr) {
    return;
  }

  if ([self handleStyleBlocksAndConflicts:[MentionStyle getStyleType]
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

  // handle conflicting styles: all of their occurences have to be removed
  NSArray<NSNumber *> *conflicting =
      [self getPresentStyleTypesFrom:conflictingStyles[@(type)] range:range];
  if (conflicting.count != 0) {
    for (NSNumber *style in conflicting) {
      id<BaseStyleProtocol> styleClass = stylesDict[style];

      if (range.length >= 1) {
        // for ranges, we need to remove each occurence
        NSArray<StylePair *> *allOccurences =
            [styleClass findAllOccurences:range];

        for (StylePair *pair in allOccurences) {
          [styleClass removeAttributes:[pair.rangeValue rangeValue]];
        }
      } else {
        // with in-place selection, we just remove the adequate typing
        // attributes
        [styleClass removeTypingAttributes];
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
    id<BaseStyleProtocol> styleClass = stylesDict[type];

    if (range.length >= 1) {
      if ([styleClass anyOccurence:range]) {
        [resultArray addObject:type];
      }
    } else {
      if ([styleClass detectStyle:range]) {
        [resultArray addObject:type];
      }
    }
  }
  return resultArray;
}

- (void)manageSelectionBasedChanges {
  // link typing attributes fix
  LinkStyle *linkStyleClass =
      (LinkStyle *)stylesDict[@([LinkStyle getStyleType])];
  if (linkStyleClass != nullptr) {
    [linkStyleClass manageLinkTypingAttributes];
  }

  // mention typing attribtues fix and active editing
  MentionStyle *mentionStyleClass =
      (MentionStyle *)stylesDict[@([MentionStyle getStyleType])];
  if (mentionStyleClass != nullptr) {
    [mentionStyleClass manageMentionTypingAttributes];

    // mention editing runs if only a selection was done (no text change)
    // otherwise we would double-emit with a second call in the
    // anyTextMayHaveBeenModified method
    if ([_recentlyEmittedString
            isEqualToString:[textView.textStorage.string copy]]) {
      [mentionStyleClass manageMentionEditing];
    }
  }

  // typing attributes for empty lines selection reset
  NSString *currentString = [textView.textStorage.string copy];
  if (textView.selectedRange.length == 0 &&
      [_recentlyEmittedString isEqualToString:currentString]) {
    // no string change means only a selection changed with no character changes
    NSRange paragraphRange = [textView.textStorage.string
        paragraphRangeForRange:textView.selectedRange];
    if (paragraphRange.length == 0 ||
        (paragraphRange.length == 1 &&
         [[NSCharacterSet newlineCharacterSet]
             characterIsMember:[textView.textStorage.string
                                   characterAtIndex:paragraphRange
                                                        .location]])) {
      // user changed selection to an empty line (or empty line with a newline)
      // typing attributes need to be reset
      textView.typingAttributes = defaultTypingAttributes;
    }
  }

  // update active styles as well
  [self tryUpdatingActiveStyles];
}

- (void)handleWordModificationBasedChanges:(NSString *)word
                                   inRange:(NSRange)range {
  // manual links refreshing and automatic links detection handling
  LinkStyle *linkStyle = [stylesDict objectForKey:@([LinkStyle getStyleType])];

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
      _recentlyEmittedString.length > 0) {
    // reset typing attribtues
    textView.typingAttributes = defaultTypingAttributes;
  }

  // inline code on newlines fix
  InlineCodeStyle *codeStyle = stylesDict[@([InlineCodeStyle getStyleType])];
  if (codeStyle != nullptr) {
    [codeStyle handleNewlines];
  }

  // blockquote colors management
  BlockQuoteStyle *bqStyle = stylesDict[@([BlockQuoteStyle getStyleType])];
  if (bqStyle != nullptr) {
    [bqStyle manageBlockquoteColor];
  }

  // codeblock font and color management
  CodeBlockStyle *codeBlockStyle = stylesDict[@([CodeBlockStyle getStyleType])];
  if (codeBlockStyle != nullptr) {
    [codeBlockStyle manageCodeBlockFontAndColor];
  }

  // improper headings fix
  H1Style *h1Style = stylesDict[@([H1Style getStyleType])];
  H2Style *h2Style = stylesDict[@([H2Style getStyleType])];
  H3Style *h3Style = stylesDict[@([H3Style getStyleType])];
  if (h1Style != nullptr && h2Style != nullptr && h3Style != nullptr) {
    [h1Style handleImproperHeadings];
    [h2Style handleImproperHeadings];
    [h3Style handleImproperHeadings];
  }

  // mentions management: removal and editing
  MentionStyle *mentionStyleClass =
      (MentionStyle *)stylesDict[@([MentionStyle getStyleType])];
  if (mentionStyleClass != nullptr) {
    [mentionStyleClass handleExistingMentions];
    [mentionStyleClass manageMentionEditing];
  }

  // placholder management
  if (!_placeholderLabel.hidden && textView.textStorage.string.length > 0) {
    [self setPlaceholderLabelShown:NO];
  } else if (textView.textStorage.string.length == 0 &&
             _placeholderLabel.hidden) {
    [self setPlaceholderLabelShown:YES];
  }

  if (![textView.textStorage.string isEqualToString:_recentlyEmittedString]) {
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

    // emit string without zero width spaces
    NSString *stringToBeEmitted = [[textView.textStorage.string
        stringByReplacingOccurrencesOfString:@"\u200B"
                                  withString:@""] copy];

    // emit onChangeText event
    auto emitter = [self getEventEmitter];
    if (emitter != nullptr) {
      // set the recently emitted string only if the emitter is defined
      _recentlyEmittedString = stringToBeEmitted;

      emitter->onChangeText({.value = [stringToBeEmitted toCppString]});
    }
  }

  // update height on each character change
  [self tryUpdatingHeight];
  // update active styles as well
  [self tryUpdatingActiveStyles];
  // update drawing - schedule debounced relayout
  [self scheduleRelayoutIfNeeded];
}

// Debounced relayout helper - coalesces multiple requests into one per runloop
// tick
- (void)scheduleRelayoutIfNeeded {
  // Cancel any previously scheduled invocation to debounce
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(_performRelayout)
                                             object:nil];
  // Schedule on next runloop cycle
  [self performSelector:@selector(_performRelayout)
             withObject:nil
             afterDelay:0];
}

- (void)_performRelayout {
  if (!textView) {
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    NSRange wholeRange =
        NSMakeRange(0, self->textView.textStorage.string.length);
    NSRange actualRange = NSMakeRange(0, 0);
    [self->textView.layoutManager
        invalidateLayoutForCharacterRange:wholeRange
                     actualCharacterRange:&actualRange];
    [self->textView.layoutManager ensureLayoutForCharacterRange:actualRange];
    [self->textView.layoutManager
        invalidateDisplayForCharacterRange:wholeRange];

    // We have to explicitly set contentSize
    // That way textView knows if content overflows and if should be scrollable
    // We recall measureSize here because value returned from previous
    // measureSize may not be up-to date at that point
    CGSize measuredSize = [self measureSize:self->textView.frame.size.width];
    self->textView.contentSize = measuredSize;
  });
}

- (void)didMoveToWindow {
  [super didMoveToWindow];

  if (self.window && !_didRunInitialMount) {
    _didRunInitialMount = YES;
    [self layoutIfNeeded];
    // Ideally we should remove this to match RN's uncontrolled inputs behaviour
    [self anyTextMayHaveBeenModified];
  }
}

// MARK: - UITextView delegate methods

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

- (bool)textView:(UITextView *)textView
    shouldChangeTextInRange:(NSRange)range
            replacementText:(NSString *)text {
  recentlyChangedRange = NSMakeRange(range.location, text.length);

  UnorderedListStyle *uStyle = stylesDict[@([UnorderedListStyle getStyleType])];
  OrderedListStyle *oStyle = stylesDict[@([OrderedListStyle getStyleType])];
  BlockQuoteStyle *bqStyle = stylesDict[@([BlockQuoteStyle getStyleType])];
  CodeBlockStyle *cbStyle = stylesDict[@([CodeBlockStyle getStyleType])];
  LinkStyle *linkStyle = stylesDict[@([LinkStyle getStyleType])];
  MentionStyle *mentionStyle = stylesDict[@([MentionStyle getStyleType])];
  H1Style *h1Style = stylesDict[@([H1Style getStyleType])];
  H2Style *h2Style = stylesDict[@([H2Style getStyleType])];
  H3Style *h3Style = stylesDict[@([H3Style getStyleType])];

  // some of the changes these checks do could interfere with later checks and
  // cause a crash so here I rely on short circuiting evaluation of the logical
  // expression either way it's not possible to have two of them come off at the
  // same time
  if ([uStyle handleBackspaceInRange:range replacementText:text] ||
      [uStyle tryHandlingListShorcutInRange:range replacementText:text] ||
      [oStyle handleBackspaceInRange:range replacementText:text] ||
      [oStyle tryHandlingListShorcutInRange:range replacementText:text] ||
      [bqStyle handleBackspaceInRange:range replacementText:text] ||
      [cbStyle handleBackspaceInRange:range replacementText:text] ||
      [linkStyle handleLeadingLinkReplacement:range replacementText:text] ||
      [mentionStyle handleLeadingMentionReplacement:range
                                    replacementText:text] ||
      [h1Style handleNewlinesInRange:range replacementText:text] ||
      [h2Style handleNewlinesInRange:range replacementText:text] ||
      [h3Style handleNewlinesInRange:range replacementText:text] ||
      [ZeroWidthSpaceUtils handleBackspaceInRange:range
                                  replacementText:text
                                            input:self] ||
      [ParagraphAttributesUtils handleBackspaceInRange:range
                                       replacementText:text
                                                 input:self] ||
      // CRITICAL: This callback HAS TO be always evaluated last.
      //
      // This function is the "Generic Fallback": if no specific style claims
      // the backspace action to change its state, only then do we proceed to
      // physically delete the newline and merge paragraphs.
      [ParagraphAttributesUtils handleNewlineBackspaceInRange:range
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

@end
