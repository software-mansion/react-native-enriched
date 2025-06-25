#pragma once
#import <UIKit/UIKit.h>

// the order is aligned with the order of tags in parser
typedef NS_ENUM(NSInteger, StyleType) {
  BlockQuote,
  CodeBlock,
  UnorderedList,
  OrderedList,
  H1,
  H2,
  H3,
  Link,
  Mention,
  Image,
  InlineCode,
  Bold,
  Italic,
  Underline,
  Strikethrough,
  None,
};
