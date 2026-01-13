import {
  useImperativeHandle,
  useRef,
  type SyntheticEvent,
  type CSSProperties,
  type RefObject,
} from 'react';

import type {
  EnrichedTextInputInstanceBase,
  OnChangeHtmlEvent,
  OnChangeMentionEvent,
  OnChangeStateDeprecatedEvent,
  OnChangeStateEvent,
  OnChangeTextEvent,
  OnMentionDetected,
} from '../common/types';
import { ENRICHED_TEXT_INPUT_DEFAULTS } from '../common/defaultProps';

export type EnrichedTextInputInstance = EnrichedTextInputInstanceBase;

export interface OnLinkDetected {
  text: string;
  url: string;
  start: number;
  end: number;
}

export interface OnChangeSelectionEvent {
  start: number;
  end: number;
  text: string;
}

export interface MentionStyleProperties {
  color?: string;
  backgroundColor?: string;
  textDecorationLine?: 'underline' | 'none';
}

type HeadingStyle = {
  fontSize?: number;
  bold?: boolean;
};

export interface HtmlStyle {
  h1?: HeadingStyle;
  h2?: HeadingStyle;
  h3?: HeadingStyle;
  h4?: HeadingStyle;
  h5?: HeadingStyle;
  h6?: HeadingStyle;
  blockquote?: {
    borderColor?: string;
    borderWidth?: number;
    gapWidth?: number;
    color?: string;
  };
  codeblock?: {
    color?: string;
    borderRadius?: number;
    backgroundColor?: string;
  };
  code?: {
    color?: string;
    backgroundColor?: string;
  };
  a?: {
    color?: string;
    textDecorationLine?: 'underline' | 'none';
  };
  mention?: Record<string, MentionStyleProperties> | MentionStyleProperties;
  ol?: {
    gapWidth?: number;
    marginLeft?: number;
    markerFontWeight?: string | number;
    markerColor?: string;
  };
  ul?: {
    bulletColor?: string;
    bulletSize?: number;
    marginLeft?: number;
    gapWidth?: number;
  };
}

export interface EnrichedTextInputProps {
  ref?: RefObject<EnrichedTextInputInstance | null>;
  autoFocus?: boolean;
  editable?: boolean;
  mentionIndicators?: string[];
  defaultValue?: string;
  placeholder?: string;
  placeholderTextColor?: string;
  cursorColor?: string;
  selectionColor?: string;
  autoCapitalize?: 'none' | 'sentences' | 'words' | 'characters';
  htmlStyle?: HtmlStyle;
  style?: CSSProperties;
  scrollEnabled?: boolean;
  linkRegex?: RegExp | null;
  onFocus?: () => void;
  onBlur?: () => void;
  onChangeText?: (e: SyntheticEvent<HTMLElement, OnChangeTextEvent>) => void;
  onChangeHtml?: (e: SyntheticEvent<HTMLElement, OnChangeHtmlEvent>) => void;
  onChangeState?: (e: SyntheticEvent<HTMLElement, OnChangeStateEvent>) => void;
  /**
   * @deprecated Use onChangeState prop instead.
   */
  onChangeStateDeprecated?: (
    e: SyntheticEvent<HTMLElement, OnChangeStateDeprecatedEvent>
  ) => void;
  onLinkDetected?: (e: OnLinkDetected) => void;
  onMentionDetected?: (e: OnMentionDetected) => void;
  onStartMention?: (indicator: string) => void;
  onChangeMention?: (e: OnChangeMentionEvent) => void;
  onEndMention?: (indicator: string) => void;
  onChangeSelection?: (
    e: SyntheticEvent<HTMLElement, OnChangeSelectionEvent>
  ) => void;
  /**
   * Unused for web, but kept for parity with native
   */
  androidExperimentalSynchronousEvents?: boolean;
}

export const EnrichedTextInput = ({
  ref,
  autoFocus,
  editable = ENRICHED_TEXT_INPUT_DEFAULTS.editable,
  defaultValue,
  placeholder,
  style,
}: EnrichedTextInputProps) => {
  const inputRef = useRef<HTMLInputElement>(null);

  useImperativeHandle(ref, () => ({
    // General commands
    focus: () => {
      inputRef.current?.focus();
    },
    blur: () => {
      inputRef.current?.blur();
    },
    setValue: (value: string) => {
      if (inputRef.current) {
        inputRef.current.value = value;
      }
    },
    setSelection: (start: number, end: number) => {
      inputRef.current?.setSelectionRange(start, end);
    },
    getHTML: () => {
      return Promise.resolve('');
    },

    // Text formatting commands
    toggleBold: () => {},
    toggleItalic: () => {},
    toggleUnderline: () => {},
    toggleStrikeThrough: () => {},
    toggleInlineCode: () => {},
    toggleH1: () => {},
    toggleH2: () => {},
    toggleH3: () => {},
    toggleH4: () => {},
    toggleH5: () => {},
    toggleH6: () => {},
    toggleCodeBlock: () => {},
    toggleBlockQuote: () => {},
    toggleOrderedList: () => {},
    toggleUnorderedList: () => {},
    setLink: () => {},
    setImage: () => {},
    startMention: () => {},
    setMention: () => {},
  }));

  return (
    <input
      ref={inputRef}
      type="text"
      autoFocus={autoFocus}
      disabled={!editable}
      defaultValue={defaultValue}
      placeholder={placeholder}
      style={style}
    />
  );
};
