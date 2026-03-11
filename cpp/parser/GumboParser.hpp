/**
 * Cross-platform HTML normalizer powered by Gumbo.
 * Converts arbitrary external HTML (Google Docs, Word, etc.) into a canonical
 * subset that our enriched parser understands.
 */

#pragma once

#include <string>

/**
 * C++ wrapper around the Gumbo-based HTML normalizer.
 */
class GumboParser {
public:
  /**
   * Normalize an HTML string into the canonical subset.
   *
   * @param html  UTF-8 encoded HTML fragment or full document.
   * @return      Canonical HTML string, or empty string on failure.
   */
  static std::string normalizeHtml(const std::string &html);
};
