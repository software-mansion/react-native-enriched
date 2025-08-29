#import "OccurenceUtils.h"

@implementation OccurenceUtils

+ (BOOL)detect
  :(NSAttributedStringKey _Nonnull)key
  withInput:(EnrichedTextInputView* _Nonnull)input
  inRange:(NSRange)range
  withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition
{
  __block NSInteger totalLength = 0;
  [input->textView.textStorage enumerateAttribute:key inRange:range options:0 usingBlock:
    ^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
      if(condition(value, range)) {
        totalLength += range.length;
      }
    }
  ];
  return totalLength == range.length;
}

+ (BOOL)detectMultiple
  :(NSArray<NSAttributedStringKey> *_Nonnull)keys
  withInput:(EnrichedTextInputView* _Nonnull)input
  inRange:(NSRange)range
  withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition
{
  __block NSInteger totalLength = 0;
  for(NSString* key in keys) {
    [input->textView.textStorage enumerateAttribute:key inRange:range options:0 usingBlock:
      ^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        if(condition(value, range)) {
          totalLength += range.length;
        }
      }
    ];
  }
  return totalLength == range.length;
}

+ (BOOL)any
  :(NSAttributedStringKey _Nonnull)key
  withInput:(EnrichedTextInputView* _Nonnull)input
  inRange:(NSRange)range
  withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition
{
  __block BOOL found = NO;
  [input->textView.textStorage enumerateAttribute:key inRange:range options:0 usingBlock:
    ^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
      if(condition(value, range)) {
        found = YES;
        *stop = YES;
      }
    }
  ];
  return found;
}

+ (BOOL)anyMultiple
  :(NSArray<NSAttributedStringKey> *_Nonnull)keys
  withInput:(EnrichedTextInputView* _Nonnull)input
  inRange:(NSRange)range
  withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition
{
  __block BOOL found = NO;
  for(NSString *key in keys) {
    [input->textView.textStorage enumerateAttribute:key inRange:range options:0 usingBlock:
      ^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        if(condition(value, range)) {
          found = YES;
          *stop = YES;
        }
      }
    ];
    if(found) {
      return YES;
    }
  }
  return NO;
}

+ (NSArray<StylePair *> *_Nullable)all
  :(NSAttributedStringKey _Nonnull)key
  withInput:(EnrichedTextInputView* _Nonnull)input
  inRange:(NSRange)range
  withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition
{
  __block NSMutableArray<StylePair *> *occurences = [[NSMutableArray<StylePair *> alloc] init];
  [input->textView.textStorage enumerateAttribute:key inRange:range options:0 usingBlock:
    ^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
      if(condition(value, range)) {
        StylePair *pair = [[StylePair alloc] init];
        pair.rangeValue = [NSValue valueWithRange:range];
        pair.styleValue = value;
        [occurences addObject:pair];
      }
    }
  ];
  return occurences;
}

+ (NSArray<StylePair *> *_Nullable)allMultiple
  :(NSArray<NSAttributedStringKey> *_Nonnull)keys
  withInput:(EnrichedTextInputView* _Nonnull)input
  inRange:(NSRange)range
  withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition
{
  __block NSMutableArray<StylePair *> *occurences = [[NSMutableArray<StylePair *> alloc] init];
  for(NSString *key in keys) {
    [input->textView.textStorage enumerateAttribute:key inRange:range options:0 usingBlock:
      ^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        if(condition(value, range)) {
          StylePair *pair = [[StylePair alloc] init];
          pair.rangeValue = [NSValue valueWithRange:range];
          pair.styleValue = value;
          [occurences addObject:pair];
        }
      }
    ];
  }
  return occurences;
}

@end
