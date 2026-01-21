import type { LinkNativeRegex } from '../spec/EnrichedTextInputNativeComponent';

const DISABLED_REGEX: LinkNativeRegex = {
  pattern: '',
  caseInsensitive: false,
  dotAll: false,
  isDisabled: true,
  isDefault: false,
};

const DEFAULT_REGEX: LinkNativeRegex = {
  pattern: '',
  caseInsensitive: false,
  dotAll: false,
  isDisabled: false,
  isDefault: true,
};

export const toNativeRegexConfig = (
  regex: RegExp | undefined | null
): LinkNativeRegex => {
  if (regex === null) {
    return DISABLED_REGEX;
  }

  if (regex === undefined) {
    return DEFAULT_REGEX;
  }

  const source = regex.source;

  // iOS fails on variable-width lookbehinds like (?<=a+)
  const hasLookbehind = source.includes('(?<=') || source.includes('(?<!');

  if (hasLookbehind) {
    // Basic detection for quantifiers inside a group
    const lookbehindContent = source.match(/\(\?<[=!](.*?)\)/)?.[1] || '';
    if (/[*+{]/.test(lookbehindContent)) {
      if (__DEV__) {
        console.error(
          'Variable-width lookbehinds are not supported. Using default link regex.'
        );
      }

      return DEFAULT_REGEX;
    }
  }

  return {
    pattern: source,
    caseInsensitive: regex.ignoreCase,
    dotAll: regex.dotAll,
    isDisabled: false,
    isDefault: false,
  };
};
