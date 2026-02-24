#include "GumboParser.hpp"

// C functions defined in gumbo_normalizer.c (compiled as C)
extern "C" {
char *normalize_html(const char *html, size_t len);
void free_normalized_html(char *result);
}

std::string GumboParser::normalizeHtml(const std::string &html) {
  char *raw = normalize_html(html.c_str(), html.size());
  if (!raw)
    return {};
  std::string result(raw);
  free_normalized_html(raw);
  return result;
}
