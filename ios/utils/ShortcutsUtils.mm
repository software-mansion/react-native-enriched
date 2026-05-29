#import "ShortcutsUtils.h"
#import "ParagraphAttributesUtils.h"
#import "StyleBase.h"
#import "StyleUtils.h"
#import "TextInsertionUtils.h"

typedef struct {
  EnrichedTextInputView *input;
  NSString *fullText;
  NSRange paragraphRange;
  NSRange changeRange;
  NSString *replacementText;
} ShortcutsTextContext;

typedef struct {
  ShortcutsTextContext text;
  NSArray<NSDictionary *> *inlineShortcuts;
} ShortcutsInlineContext;

typedef struct {
  NSString *trigger;
  StyleType styleType;
  NSInteger delimStart;
  NSInteger delimPrefixLen;
} ShortcutsTriggerMatch;

typedef struct {
  NSRange finalContentRange;
  NSRange closeDeleteRange;
  NSRange openDeleteRange;
} ShortcutsInlineApplyRanges;

@implementation ShortcutsUtils

+ (NSDictionary<NSString *, NSNumber *> *)shortcutStyleNameMap {
  static NSDictionary<NSString *, NSNumber *> *map = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{
      // Paragraph shortcuts
      @"h1" : @(H1),
      @"h2" : @(H2),
      @"h3" : @(H3),
      @"h4" : @(H4),
      @"h5" : @(H5),
      @"h6" : @(H6),
      @"blockquote" : @(BlockQuote),
      @"codeblock" : @(CodeBlock),
      @"unordered_list" : @(UnorderedList),
      @"ordered_list" : @(OrderedList),
      @"checkbox_list" : @(CheckboxList),
      // Inline shortcuts
      @"bold" : @(Bold),
      @"italic" : @(Italic),
      @"underline" : @(Underline),
      @"strikethrough" : @(Strikethrough),
      @"inline_code" : @(InlineCode),
    };
  });
  return map;
}

+ (StyleType)styleTypeForShortcutName:(NSString *)name {
  NSNumber *styleType = [self shortcutStyleNameMap][name];
  return styleType ? (StyleType)[styleType integerValue] : None;
}

+ (BOOL)isInlineShortcutStyleName:(NSString *)name
                            input:(EnrichedTextInputView *)input {
  StyleType type = [self styleTypeForShortcutName:name];
  if (type == None) {
    return NO;
  }

  StyleBase *style = input->stylesDict[@(type)];
  if (style == nil) {
    return NO;
  }

  return ![style isParagraph];
}

+ (BOOL)anyTextShortcutsInInput:(EnrichedTextInputView *)input {
  return input != nullptr && input->textShortcuts != nil &&
         input->textShortcuts.count > 0;
}

+ (ShortcutsTextContext)textContextWithChangeRange:(NSRange)changeRange
                                   replacementText:(NSString *)replacementText
                                             input:(EnrichedTextInputView *)
                                                       input {
  NSString *fullText = input->textView.textStorage.string;
  return (ShortcutsTextContext){
      .input = input,
      .fullText = fullText,
      .paragraphRange = [fullText paragraphRangeForRange:changeRange],
      .changeRange = changeRange,
      .replacementText = replacementText,
  };
}

+ (ShortcutsInlineContext)
    inlineContextWithChangeRange:(NSRange)changeRange
                 replacementText:(NSString *)replacementText
                           input:(EnrichedTextInputView *)input {
  return (ShortcutsInlineContext){
      .text = [self textContextWithChangeRange:changeRange
                               replacementText:replacementText
                                         input:input],
      .inlineShortcuts = [self inlineShortcutsFrom:input->textShortcuts
                                             input:input],
  };
}

+ (NSArray<NSDictionary *> *)
    inlineShortcutsFrom:(NSArray<NSDictionary *> *)textShortcuts
                  input:(EnrichedTextInputView *)input {
  NSMutableArray<NSDictionary *> *inlineShortcuts = [NSMutableArray array];
  for (NSDictionary *shortcut in textShortcuts) {
    if ([self isInlineShortcutStyleName:shortcut[@"style"] input:input]) {
      [inlineShortcuts addObject:shortcut];
    }
  }
  [inlineShortcuts sortUsingComparator:^NSComparisonResult(NSDictionary *a,
                                                           NSDictionary *b) {
    NSUInteger lenA = [a[@"trigger"] length];
    NSUInteger lenB = [b[@"trigger"] length];
    if (lenA > lenB) {
      return NSOrderedAscending;
    }
    if (lenA < lenB) {
      return NSOrderedDescending;
    }
    return NSOrderedSame;
  }];
  return inlineShortcuts;
}

/// When [requiredDelimStart] is NSNotFound, the trigger may appear anywhere in
/// the text. Otherwise the matched delimiter must start at that index
/// (paragraph shortcuts at paragraph start).
+ (BOOL)isCompletingTrigger:(NSString *)trigger
                    context:(const ShortcutsTextContext *)context
         requiredDelimStart:(NSInteger)requiredDelimStart
                      match:(ShortcutsTriggerMatch *)outMatch {
  if (trigger.length == 0) {
    return NO;
  }

  NSString *lastTriggerChar = [trigger substringFromIndex:trigger.length - 1];
  if (![context->replacementText isEqualToString:lastTriggerChar]) {
    return NO;
  }

  NSInteger delimPrefixLen = (NSInteger)trigger.length - 1;
  if (delimPrefixLen > 0) {
    if (context->changeRange.location < delimPrefixLen) {
      return NO;
    }
    NSString *prefix = [trigger substringToIndex:delimPrefixLen];
    NSString *beforeCursor = [context->fullText
        substringWithRange:NSMakeRange(context->changeRange.location -
                                           delimPrefixLen,
                                       delimPrefixLen)];
    if (![beforeCursor isEqualToString:prefix]) {
      return NO;
    }
  }

  NSInteger delimStart = context->changeRange.location - delimPrefixLen;
  if (requiredDelimStart != NSNotFound && delimStart != requiredDelimStart) {
    return NO;
  }

  if (outMatch != nullptr) {
    outMatch->trigger = trigger;
    outMatch->delimStart = delimStart;
    outMatch->delimPrefixLen = delimPrefixLen;
  }
  return YES;
}

/// Delimiter at [delimStart] is part of a longer inline trigger (e.g. `*`
/// inside `**`).
+ (BOOL)isDelimiterPartOfLongerInlineTrigger:(NSString *)trigger
                                  delimStart:(NSInteger)delimStart
                                     context:(const ShortcutsInlineContext *)
                                                 context {
  NSInteger delimEnd = delimStart + trigger.length;
  NSString *fullText = context->text.fullText;

  for (NSDictionary *shortcut in context->inlineShortcuts) {
    NSString *longerTrigger = shortcut[@"trigger"];
    if (longerTrigger.length <= trigger.length) {
      continue;
    }
    if (![longerTrigger hasSuffix:trigger]) {
      continue;
    }

    NSInteger longerStart = delimEnd - longerTrigger.length;
    if (longerStart < 0 ||
        longerStart + longerTrigger.length > fullText.length) {
      continue;
    }

    NSRange longerRange = NSMakeRange(longerStart, longerTrigger.length);
    if ([[fullText substringWithRange:longerRange]
            isEqualToString:longerTrigger]) {
      return YES;
    }
  }
  return NO;
}

/// Removes delimiters (close first, then open), then applies [style] on
/// [contentRange].
+ (void)applyInlineShortcutWithMatch:(const ShortcutsTriggerMatch *)match
                             context:(const ShortcutsInlineContext *)context
                              ranges:
                                  (const ShortcutsInlineApplyRanges *)ranges {
  EnrichedTextInputView *input = context->text.input;
  input->blockEmitting = YES;

  if (ranges->closeDeleteRange.length > 0) {
    [TextInsertionUtils replaceText:@""
                                 at:ranges->closeDeleteRange
               additionalAttributes:nullptr
                               host:input
                      withSelection:NO];
  }

  if (ranges->openDeleteRange.length > 0) {
    [TextInsertionUtils replaceText:@""
                                 at:ranges->openDeleteRange
               additionalAttributes:nullptr
                               host:input
                      withSelection:NO];
  }

  input->blockEmitting = NO;

  StyleBase *style = input->stylesDict[@(match->styleType)];
  if (style == nil) {
    return;
  }

  [style add:ranges->finalContentRange withTyping:NO withDirtyRange:YES];
  input->textView.selectedRange =
      NSMakeRange(NSMaxRange(ranges->finalContentRange), 0);
  [style removeTyping];
}

+ (BOOL)applyInlineShortcutWithMatch:(const ShortcutsTriggerMatch *)match
                             context:(const ShortcutsInlineContext *)context
                        contentRange:(NSRange)contentRange
                              ranges:
                                  (const ShortcutsInlineApplyRanges *)ranges {
  if (![StyleUtils handleStyleBlocksAndConflicts:match->styleType
                                           range:contentRange
                                         forHost:context->text.input]) {
    return NO;
  }

  [self applyInlineShortcutWithMatch:match context:context ranges:ranges];
  return YES;
}

/// Closing delimiter just completed: find opening trigger before content.
+ (BOOL)tryInlineShortcutClosingFirst:(const ShortcutsTriggerMatch *)match
                              context:(const ShortcutsInlineContext *)context {
  const ShortcutsTextContext *text = &context->text;
  NSInteger searchStart = text->paragraphRange.location;
  NSInteger searchLength = match->delimStart - searchStart;
  if (searchLength <= 0) {
    return NO;
  }

  NSRange openRange =
      [text->fullText rangeOfString:match->trigger
                            options:NSBackwardsSearch
                              range:NSMakeRange(searchStart, searchLength)];
  if (openRange.location == NSNotFound) {
    return NO;
  }

  if ([self isDelimiterPartOfLongerInlineTrigger:match->trigger
                                      delimStart:openRange.location
                                         context:context]) {
    return NO;
  }

  NSInteger contentStart = openRange.location + match->trigger.length;
  NSInteger contentEnd = match->delimStart;
  if (contentEnd <= contentStart) {
    return NO;
  }

  NSInteger finalContentEnd = match->delimStart - match->trigger.length;
  ShortcutsInlineApplyRanges ranges = {
      .finalContentRange =
          NSMakeRange(openRange.location, finalContentEnd - openRange.location),
      .closeDeleteRange = NSMakeRange(match->delimStart, match->delimPrefixLen),
      .openDeleteRange = NSMakeRange(openRange.location, match->trigger.length),
  };

  return
      [self applyInlineShortcutWithMatch:match
                                 context:context
                            contentRange:NSMakeRange(contentStart,
                                                     contentEnd - contentStart)
                                  ranges:&ranges];
}

/// Paragraph already has a paragraph-level style (list, quote, heading, …).
/// Alignment is ignored.
+ (BOOL)paragraphHasActiveParagraphStyleInRange:(NSRange)paragraphRange
                                          input:(EnrichedTextInputView *)input {
  for (NSNumber *typeKey in input->stylesDict) {
    StyleBase *style = input->stylesDict[typeKey];
    if (![style isParagraph] || [[style class] getType] == Alignment) {
      continue;
    }
    if ([style detect:paragraphRange]) {
      return YES;
    }
  }
  return NO;
}

/// Handles a paragraph-level shortcut (e.g. `# ` → H1, `- ` → unordered list)
/// on character insertion.
///
///  1. Skip if no shortcuts configured, or the paragraph already has an active
///     paragraph style — triggers only apply to plain paragraphs.
///  2. Find a paragraph shortcut whose trigger is anchored to the paragraph
///     start. Skip if the resolved style is blocked by another active style.
///  3. Save the current text alignment.
///  4. Suppress events, delete the trigger text, unsuppress.
///  5. Remove styles from the range that conflict with the new style (e.g.
///     italic is removed when applying codeblock).
//   6. Reset typing attrs to defaults preserving alignment — without this, the
//   new paragraph
///     style would inherit the alignment of the previous paragraph.
///  7. Apply the paragraph style with withTyping:YES so the next typed
///  character
///     inherits it immediately.
+ (BOOL)tryHandlingParagraphShortcutsInRange:(NSRange)range
                             replacementText:(NSString *)text
                                       input:(EnrichedTextInputView *)input {
  if (![self anyTextShortcutsInInput:input]) {
    return NO;
  }

  ShortcutsTextContext context = [self textContextWithChangeRange:range
                                                  replacementText:text
                                                            input:input];

  if ([self paragraphHasActiveParagraphStyleInRange:context.paragraphRange
                                              input:input]) {
    return NO;
  }

  for (NSDictionary *shortcut in input->textShortcuts) {
    if ([self isInlineShortcutStyleName:shortcut[@"style"] input:input]) {
      continue;
    }

    NSString *trigger = shortcut[@"trigger"];
    NSString *styleName = shortcut[@"style"];
    if (trigger.length == 0 || styleName.length == 0) {
      continue;
    }

    ShortcutsTriggerMatch match = {};
    if (![self isCompletingTrigger:trigger
                           context:&context
                requiredDelimStart:context.paragraphRange.location
                             match:&match]) {
      continue;
    }

    StyleType type = [self styleTypeForShortcutName:styleName];
    if (type == None) {
      continue;
    }

    if ([StyleUtils isStyleBlocked:type
                             range:context.paragraphRange
                           forHost:input]) {
      continue;
    }

    NSParagraphStyle *currentParaStyle =
        input->textView.typingAttributes[NSParagraphStyleAttributeName];
    NSTextAlignment savedAlignment =
        currentParaStyle ? currentParaStyle.alignment : NSTextAlignmentNatural;

    NSRange triggerRange = NSMakeRange(match.delimStart, match.delimPrefixLen);

    input->blockEmitting = YES;
    [TextInsertionUtils replaceText:@""
                                 at:triggerRange
               additionalAttributes:nullptr
                               host:input
                      withSelection:YES];

    input->blockEmitting = NO;

    // Drop conflicting inline typing attrs (e.g. italic) at the cursor before
    // applying the codeblock style.
    [StyleUtils handleStyleBlocksAndConflicts:type
                                        range:input->textView.selectedRange
                                      forHost:input];

    [ParagraphAttributesUtils resetTypingAttributes:input
                                preservingAlignment:savedAlignment];

    StyleBase *style = input->stylesDict[@(type)];
    if (style != nil) {
      [style add:input->textView.selectedRange
              withTyping:YES
          withDirtyRange:YES];
    }
    return YES;
  }

  return NO;
}

/// Handles an inline shortcut (e.g. `**text**` → bold) on character insertion.
/// Inline shortcuts are symmetric delimiter pairs — the same string opens and
/// closes the style (e.g. `**`).
///
///  1. Build the inline context: inline-only shortcuts sorted longest-first so
///     `**` is never pre-empted by its shorter suffix `*`.
///  2. Check if the just-typed character, together with the characters
///     immediately before the cursor, completes a closing delimiter.
///  3. Search backwards for a matching opening delimiter. Reject if it is part
///     of a longer trigger, or if there is no content between the pair.
///  4. Check style blocks/conflicts; skip if the style cannot be applied.
///  5. Suppress events, delete the closing-delimiter prefix then the opening
///     delimiter (close first so the open's earlier index stays valid).
///  6. Apply the style to the content range, move the cursor to its end, and
///     clear the typing style.
+ (BOOL)tryHandlingInlineShortcutsInRange:(NSRange)range
                          replacementText:(NSString *)text
                                    input:(EnrichedTextInputView *)input {
  if (![self anyTextShortcutsInInput:input]) {
    return NO;
  }

  ShortcutsInlineContext context = [self inlineContextWithChangeRange:range
                                                      replacementText:text
                                                                input:input];

  for (NSDictionary *shortcut in context.inlineShortcuts) {
    NSString *trigger = shortcut[@"trigger"];
    NSString *styleName = shortcut[@"style"];
    if (trigger.length == 0 || styleName.length == 0) {
      continue;
    }

    ShortcutsTriggerMatch match = {};
    if (![self isCompletingTrigger:trigger
                           context:&context.text
                requiredDelimStart:NSNotFound
                             match:&match]) {
      continue;
    }

    StyleType type = [self styleTypeForShortcutName:styleName];
    if (type == None) {
      continue;
    }
    match.styleType = type;

    if ([self tryInlineShortcutClosingFirst:&match context:&context]) {
      return YES;
    }
  }

  return NO;
}

@end
