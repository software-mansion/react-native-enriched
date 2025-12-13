#pragma once

#import <Foundation/Foundation.h>

static inline void appendC(NSMutableData *buf, const char *c) {
  if (!c)
    return;
  [buf appendBytes:c length:strlen(c)];
}

static inline void appendEscapedRange(NSMutableData *buf, NSString *src,
                                      NSRange r) {
  NSUInteger len = r.length;
  unichar *tmp = (unichar *)alloca(len * sizeof(unichar));
  [src getCharacters:tmp range:r];

  for (NSUInteger i = 0; i < len; i++) {
    unichar c = tmp[i];
    if (c == 0x200B)
      continue;

    switch (c) {
    case '<':
      appendC(buf, "&lt;");
      break;
    case '>':
      appendC(buf, "&gt;");
      break;
    case '&':
      appendC(buf, "&amp;");
      break;

    default: {
      char out[4];
      int n = 0;
      if (c < 0x80) {
        out[0] = (char)c;
        n = 1;
      } else if (c < 0x800) {
        out[0] = 0xC0 | (c >> 6);
        out[1] = 0x80 | (c & 0x3F);
        n = 2;
      } else {
        out[0] = 0xE0 | (c >> 12);
        out[1] = 0x80 | ((c >> 6) & 0x3F);
        out[2] = 0x80 | (c & 0x3F);
        n = 3;
      }
      [buf appendBytes:out length:n];
    }
    }
  }
}

static inline void appendKeyVal(NSMutableData *buf, NSString *key,
                                NSString *val) {
  appendC(buf, " ");
  const char *k = key.UTF8String;
  appendC(buf, k);
  appendC(buf, "=\"");
  appendEscapedRange(buf, val, NSMakeRange(0, val.length));
  appendC(buf, "\"");
}

static inline BOOL isBlockTag(const char *t) {
  if (!t)
    return NO;
  switch (t[0]) {
  case 'p':
    return t[1] == 0;
  case 'h':
    return (t[2] == 0 && (t[1] == '1' || t[1] == '2' || t[1] == '3'));
  case 'u':
    return strcmp(t, "ul") == 0;
  case 'o':
    return strcmp(t, "ol") == 0;
  case 'l':
    return strcmp(t, "li") == 0;
  case 'b':
    return strcmp(t, "br") == 0 || strcmp(t, "blockquote") == 0;
  case 'c':
    return strcmp(t, "codeblock") == 0;
  default:
    return NO;
  }
}

static inline BOOL needsNewLineAfter(const char *t) {
  if (!t)
    return NO;
  return (strcmp(t, "ul") == 0 || strcmp(t, "ol") == 0 ||
          strcmp(t, "blockquote") == 0 || strcmp(t, "codeblock") == 0 ||
          strcmp(t, "html") == 0);
}

static inline void appendOpenTagC(NSMutableData *buf, const char *t,
                                  NSDictionary *attrs, BOOL block) {
  if (block)
    appendC(buf, "\n<");
  else
    appendC(buf, "<");

  appendC(buf, t);
  for (NSString *key in attrs)
    appendKeyVal(buf, key, attrs[key]);

  appendC(buf, ">");
}

static inline void appendSelfClosingTagC(NSMutableData *buf, const char *t,
                                         NSDictionary *attrs, BOOL block) {
  if (block)
    appendC(buf, "\n<");
  else
    appendC(buf, "<");

  appendC(buf, t);
  for (NSString *key in attrs)
    appendKeyVal(buf, key, attrs[key]);

  appendC(buf, "/>");
}

static inline void appendCloseTagC(NSMutableData *buf, const char *t) {
  appendC(buf, "</");
  appendC(buf, t);
  appendC(buf, ">");
}
