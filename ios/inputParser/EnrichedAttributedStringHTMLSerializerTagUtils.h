#pragma once
#import <Foundation/Foundation.h>
static const unichar ZeroWidthSpace = 0x200B;

static const int UTF8_1ByteLimit = 0x80;
static const int UTF8_2ByteLimit = 0x800;

static const char UTF8_2ByteLeadMask = 0xC0;
static const char UTF8_3ByteLeadMask = 0xE0;
static const char UTF8_ContinuationMask = 0x80;
static const char UTF8_ContinuationPayloadMask = 0x3F;

static const unichar HtmlLessThanChar = '<';
static const unichar HtmlGreaterThanChar = '>';
static const unichar HtmlAmpersandChar = '&';

static const char *NewlineOpenTag = "\n<";

static const char *OpenTagStart = "<";
static const char *CloseTagStart = "</";
static const char *SelfCloseTagSuffix = "/>";
static const char *TagEnd = ">";
static const char *Space = " ";
static const char *EqualsSign = "=";
static const char *Quote = "\"";

static const char *EscapeLT = "&lt;";
static const char *EscapeGT = "&gt;";
static const char *EscapeAmp = "&amp;";

static const char *HtmlTagUL = "ul";
static const char *HtmlTagOL = "ol";
static const char *HtmlTagLI = "li";
static const char *HtmlTagBR = "br";
static const char *HtmlTagHTML = "html";
static const char *HtmlTagBlockquote = "blockquote";
static const char *HtmlTagCodeblock = "codeblock";

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
    if (c == ZeroWidthSpace)
      continue;

    switch (c) {
    case HtmlLessThanChar:
      appendC(buf, EscapeLT);
      break;
    case HtmlGreaterThanChar:
      appendC(buf, EscapeGT);
      break;
    case HtmlAmpersandChar:
      appendC(buf, EscapeAmp);
      break;

    default: {
      char out[4];
      int n = 0;

      if (c < UTF8_1ByteLimit) {
        out[0] = (char)c;
        n = 1;

      } else if (c < UTF8_2ByteLimit) {
        out[0] = UTF8_2ByteLeadMask | (c >> 6);
        out[1] = UTF8_ContinuationMask | (c & UTF8_ContinuationPayloadMask);
        n = 2;

      } else {
        out[0] = UTF8_3ByteLeadMask | (c >> 12);
        out[1] =
            UTF8_ContinuationMask | ((c >> 6) & UTF8_ContinuationPayloadMask);
        out[2] = UTF8_ContinuationMask | (c & UTF8_ContinuationPayloadMask);
        n = 3;
      }

      [buf appendBytes:out length:n];
    }
    }
  }
}

static inline void appendKeyVal(NSMutableData *buf, NSString *key,
                                NSString *val) {
  appendC(buf, Space);
  appendC(buf, key.UTF8String);
  appendC(buf, EqualsSign);
  appendC(buf, Quote);
  appendEscapedRange(buf, val, NSMakeRange(0, val.length));
  appendC(buf, Quote);
}

static inline BOOL isBlockTag(const char *t) {
  if (!t)
    return NO;

  switch (t[0]) {
  case 'p':
    return t[1] == '\0';
  case 'h':
    return t[2] == '\0' && (t[1] == '1' || t[1] == '2' || t[1] == '3');
  case 'u':
    return strcmp(t, HtmlTagUL) == 0;
  case 'o':
    return strcmp(t, HtmlTagOL) == 0;
  case 'l':
    return strcmp(t, HtmlTagLI) == 0;
  case 'b':
    return strcmp(t, HtmlTagBR) == 0 || strcmp(t, HtmlTagBlockquote) == 0;
  case 'c':
    return strcmp(t, HtmlTagCodeblock) == 0;
  default:
    return NO;
  }
}

static inline BOOL needsNewLineAfter(const char *t) {
  if (!t)
    return NO;

  return (strcmp(t, HtmlTagUL) == 0 || strcmp(t, HtmlTagOL) == 0 ||
          strcmp(t, HtmlTagBlockquote) == 0 ||
          strcmp(t, HtmlTagCodeblock) == 0 || strcmp(t, HtmlTagHTML) == 0);
}

static inline void appendOpenTag(NSMutableData *buf, const char *t,
                                 NSDictionary *attrs, BOOL block) {
  appendC(buf, block ? NewlineOpenTag : OpenTagStart);
  appendC(buf, t);

  for (NSString *key in attrs)
    appendKeyVal(buf, key, attrs[key]);

  appendC(buf, TagEnd);
}

static inline void appendSelfClosingTag(NSMutableData *buf, const char *t,
                                        NSDictionary *attrs, BOOL block) {
  appendC(buf, block ? NewlineOpenTag : OpenTagStart);
  appendC(buf, t);

  for (NSString *key in attrs)
    appendKeyVal(buf, key, attrs[key]);

  appendC(buf, SelfCloseTagSuffix);
}

static inline void appendCloseTag(NSMutableData *buf, const char *t) {
  appendC(buf, CloseTagStart);
  appendC(buf, t);
  appendC(buf, TagEnd);
}
