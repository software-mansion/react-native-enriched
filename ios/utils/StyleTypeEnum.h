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
  H4,
  H5,
  H6,
  Link,
  Mention,
  Image,
  InlineCode,
  Bold,
  Italic,
  Underline,
  Strikethrough,
  Colored,
  None,
};
