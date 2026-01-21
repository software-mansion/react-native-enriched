import {
  type Component,
  type RefObject,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
} from 'react';
import EnrichedTextInputNativeComponent, {
  Commands,
  type NativeProps,
  type OnChangeSelectionNativeEvent,
  type OnLinkDetectedNativeEvent,
  type OnMentionEvent,
  type OnMentionDetectedInternal,
  type OnRequestHtmlResultEvent,
  type MentionStyleProperties,
  type OnChangeStateDeprecatedEvent,
  type OnKeyPressEvent,
} from '../spec/EnrichedTextInputNativeComponent';
import type {
  ColorValue,
  HostInstance,
  MeasureInWindowOnSuccessCallback,
  MeasureLayoutOnSuccessCallback,
  MeasureOnSuccessCallback,
  NativeMethods,
  NativeSyntheticEvent,
  TextStyle,
  ViewProps,
  ViewStyle,
} from 'react-native';
import { normalizeHtmlStyle } from '../utils/normalizeHtmlStyle';
import { toNativeRegexConfig } from '../utils/regexParser';
import type {
  OnChangeTextEvent,
  OnChangeHtmlEvent,
  OnChangeStateEvent,
  OnMentionDetected,
  OnLinkDetected,
  OnChangeSelectionEvent,
  OnChangeMentionEvent,
  EnrichedTextInputInstanceBase,
} from '../common/types';
import { ENRICHED_TEXT_INPUT_DEFAULTS } from '../common/defaultProps';

export interface EnrichedTextInputInstance
  extends EnrichedTextInputInstanceBase,
    NativeMethods {}

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
    borderColor?: ColorValue;
    borderWidth?: number;
    gapWidth?: number;
    color?: ColorValue;
  };
  codeblock?: {
    color?: ColorValue;
    borderRadius?: number;
    backgroundColor?: ColorValue;
  };
  code?: {
    color?: ColorValue;
    backgroundColor?: ColorValue;
  };
  a?: {
    color?: ColorValue;
    textDecorationLine?: 'underline' | 'none';
  };
  mention?: Record<string, MentionStyleProperties> | MentionStyleProperties;
  ol?: {
    gapWidth?: number;
    marginLeft?: number;
    markerFontWeight?: TextStyle['fontWeight'];
    markerColor?: ColorValue;
  };
  ul?: {
    bulletColor?: ColorValue;
    bulletSize?: number;
    marginLeft?: number;
    gapWidth?: number;
  };
}

export interface EnrichedTextInputProps extends Omit<ViewProps, 'children'> {
  ref?: RefObject<EnrichedTextInputInstance | null>;
  autoFocus?: boolean;
  editable?: boolean;
  mentionIndicators?: string[];
  defaultValue?: string;
  placeholder?: string;
  placeholderTextColor?: ColorValue;
  cursorColor?: ColorValue;
  selectionColor?: ColorValue;
  autoCapitalize?: 'none' | 'sentences' | 'words' | 'characters';
  htmlStyle?: HtmlStyle;
  style?: ViewStyle | TextStyle;
  scrollEnabled?: boolean;
  linkRegex?: RegExp | null;
  onFocus?: () => void;
  onBlur?: () => void;
  onChangeText?: (e: OnChangeTextEvent) => void;
  onChangeHtml?: (e: OnChangeHtmlEvent) => void;
  onChangeState?: (e: OnChangeStateEvent) => void;
  /**
   * @deprecated Use onChangeState prop instead.
   */
  onChangeStateDeprecated?: (e: OnChangeStateDeprecatedEvent) => void;
  onLinkDetected?: (e: OnLinkDetected) => void;
  onMentionDetected?: (e: OnMentionDetected) => void;
  onStartMention?: (indicator: string) => void;
  onChangeMention?: (e: OnChangeMentionEvent) => void;
  onEndMention?: (indicator: string) => void;
  onChangeSelection?: (e: OnChangeSelectionEvent) => void;
  onKeyPress?: (e: OnKeyPressEvent) => void;
  /**
   * If true, Android will use experimental synchronous events.
   * This will prevent from input flickering when updating component size.
   * However, this is an experimental feature, which has not been thoroughly tested.
   * We may decide to enable it by default in a future release.
   * Disabled by default.
   */
  androidExperimentalSynchronousEvents?: boolean;
}

const nullthrows = <T,>(value: T | null | undefined): T => {
  if (value == null) {
    throw new Error('Unexpected null or undefined value');
  }

  return value;
};

const warnAboutMisconfiguredMentions = (indicator: string) => {
  console.warn(
    `Looks like you are trying to set a "${indicator}" but it's not in the mentionIndicators prop`
  );
};

type ComponentType = (Component<NativeProps, {}, any> & NativeMethods) | null;

type HtmlRequest = {
  resolve: (html: string) => void;
  reject: (error: Error) => void;
};

export const EnrichedTextInput = ({
  ref,
  autoFocus,
  editable = ENRICHED_TEXT_INPUT_DEFAULTS.editable,
  mentionIndicators = ENRICHED_TEXT_INPUT_DEFAULTS.mentionIndicators,
  defaultValue,
  placeholder,
  placeholderTextColor,
  cursorColor,
  selectionColor,
  style,
  autoCapitalize = ENRICHED_TEXT_INPUT_DEFAULTS.autoCapitalize,
  htmlStyle = ENRICHED_TEXT_INPUT_DEFAULTS.htmlStyle,
  linkRegex: _linkRegex,
  onFocus,
  onBlur,
  onChangeText,
  onChangeHtml,
  onChangeState,
  onChangeStateDeprecated,
  onLinkDetected,
  onMentionDetected,
  onStartMention,
  onChangeMention,
  onEndMention,
  onChangeSelection,
  onKeyPress,
  androidExperimentalSynchronousEvents = ENRICHED_TEXT_INPUT_DEFAULTS.androidExperimentalSynchronousEvents,
  scrollEnabled = ENRICHED_TEXT_INPUT_DEFAULTS.scrollEnabled,
  ...rest
}: EnrichedTextInputProps) => {
  const nativeRef = useRef<ComponentType | null>(null);

  const nextHtmlRequestId = useRef(1);
  const pendingHtmlRequests = useRef(new Map<number, HtmlRequest>());

  useEffect(() => {
    const pendingRequests = pendingHtmlRequests.current;
    return () => {
      pendingRequests.forEach(({ reject }) => {
        reject(new Error('Component unmounted'));
      });
      pendingRequests.clear();
    };
  }, []);

  const normalizedHtmlStyle = useMemo(
    () => normalizeHtmlStyle(htmlStyle, mentionIndicators),
    [htmlStyle, mentionIndicators]
  );

  const linkRegex = useMemo(
    () => toNativeRegexConfig(_linkRegex),
    [_linkRegex]
  );

  useImperativeHandle(ref, () => ({
    measureInWindow: (callback: MeasureInWindowOnSuccessCallback) => {
      nullthrows(nativeRef.current).measureInWindow(callback);
    },
    measure: (callback: MeasureOnSuccessCallback) => {
      nullthrows(nativeRef.current).measure(callback);
    },
    measureLayout: (
      relativeToNativeComponentRef: HostInstance | number,
      onSuccess: MeasureLayoutOnSuccessCallback,
      onFail?: () => void
    ) => {
      nullthrows(nativeRef.current).measureLayout(
        relativeToNativeComponentRef,
        onSuccess,
        onFail
      );
    },
    setNativeProps: (nativeProps: object) => {
      nullthrows(nativeRef.current).setNativeProps(nativeProps);
    },
    focus: () => {
      Commands.focus(nullthrows(nativeRef.current));
    },
    blur: () => {
      Commands.blur(nullthrows(nativeRef.current));
    },
    setValue: (value: string) => {
      Commands.setValue(nullthrows(nativeRef.current), value);
    },
    getHTML: () => {
      return new Promise<string>((resolve, reject) => {
        const requestId = nextHtmlRequestId.current++;
        pendingHtmlRequests.current.set(requestId, { resolve, reject });
        Commands.requestHTML(nullthrows(nativeRef.current), requestId);
      });
    },
    toggleBold: () => {
      Commands.toggleBold(nullthrows(nativeRef.current));
    },
    toggleItalic: () => {
      Commands.toggleItalic(nullthrows(nativeRef.current));
    },
    toggleUnderline: () => {
      Commands.toggleUnderline(nullthrows(nativeRef.current));
    },
    toggleStrikeThrough: () => {
      Commands.toggleStrikeThrough(nullthrows(nativeRef.current));
    },
    toggleInlineCode: () => {
      Commands.toggleInlineCode(nullthrows(nativeRef.current));
    },
    toggleH1: () => {
      Commands.toggleH1(nullthrows(nativeRef.current));
    },
    toggleH2: () => {
      Commands.toggleH2(nullthrows(nativeRef.current));
    },
    toggleH3: () => {
      Commands.toggleH3(nullthrows(nativeRef.current));
    },
    toggleH4: () => {
      Commands.toggleH4(nullthrows(nativeRef.current));
    },
    toggleH5: () => {
      Commands.toggleH5(nullthrows(nativeRef.current));
    },
    toggleH6: () => {
      Commands.toggleH6(nullthrows(nativeRef.current));
    },
    toggleCodeBlock: () => {
      Commands.toggleCodeBlock(nullthrows(nativeRef.current));
    },
    toggleBlockQuote: () => {
      Commands.toggleBlockQuote(nullthrows(nativeRef.current));
    },
    toggleOrderedList: () => {
      Commands.toggleOrderedList(nullthrows(nativeRef.current));
    },
    toggleUnorderedList: () => {
      Commands.toggleUnorderedList(nullthrows(nativeRef.current));
    },
    setLink: (start: number, end: number, text: string, url: string) => {
      Commands.addLink(nullthrows(nativeRef.current), start, end, text, url);
    },
    setImage: (uri: string, width: number, height: number) => {
      Commands.addImage(nullthrows(nativeRef.current), uri, width, height);
    },
    setMention: (
      indicator: string,
      text: string,
      attributes?: Record<string, string>
    ) => {
      // Codegen does not support objects as Commands parameters, so we stringify attributes
      const parsedAttributes = JSON.stringify(attributes ?? {});

      Commands.addMention(
        nullthrows(nativeRef.current),
        indicator,
        text,
        parsedAttributes
      );
    },
    startMention: (indicator: string) => {
      if (!mentionIndicators?.includes(indicator)) {
        warnAboutMisconfiguredMentions(indicator);
      }

      Commands.startMention(nullthrows(nativeRef.current), indicator);
    },
    setSelection: (start: number, end: number) => {
      Commands.setSelection(nullthrows(nativeRef.current), start, end);
    },
  }));

  const handleMentionEvent = (e: NativeSyntheticEvent<OnMentionEvent>) => {
    const mentionText = e.nativeEvent.text;
    const mentionIndicator = e.nativeEvent.indicator;

    if (typeof mentionText === 'string') {
      if (mentionText === '') {
        onStartMention?.(mentionIndicator);
      } else {
        onChangeMention?.({ indicator: mentionIndicator, text: mentionText });
      }
    } else if (mentionText === null) {
      onEndMention?.(mentionIndicator);
    }
  };

  const handleLinkDetected = (
    e: NativeSyntheticEvent<OnLinkDetectedNativeEvent>
  ) => {
    const { text, url, start, end } = e.nativeEvent;
    onLinkDetected?.({ text, url, start, end });
  };

  const handleChangeText = (e: NativeSyntheticEvent<OnChangeTextEvent>) => {
    onChangeText?.(e.nativeEvent);
  };

  const handleChangeHtml = (e: NativeSyntheticEvent<OnChangeHtmlEvent>) => {
    onChangeHtml?.(e.nativeEvent);
  };

  const handleChangeState = (e: NativeSyntheticEvent<OnChangeStateEvent>) => {
    onChangeState?.(e.nativeEvent);
  };

  const handleChangeStateDeprecated = (
    e: NativeSyntheticEvent<OnChangeStateDeprecatedEvent>
  ) => {
    onChangeStateDeprecated?.(e.nativeEvent);
  };

  const handleKeyPress = (e: NativeSyntheticEvent<OnKeyPressEvent>) => {
    onKeyPress?.(e.nativeEvent);
  };

  const handleChangeSelection = (
    e: NativeSyntheticEvent<OnChangeSelectionNativeEvent>
  ) => {
    onChangeSelection?.(e.nativeEvent);
  };

  const handleMentionDetected = (
    e: NativeSyntheticEvent<OnMentionDetectedInternal>
  ) => {
    const { text, indicator, payload } = e.nativeEvent;
    const attributes = JSON.parse(payload) as Record<string, string>;
    onMentionDetected?.({ text, indicator, attributes });
  };

  const handleRequestHtmlResult = (
    e: NativeSyntheticEvent<OnRequestHtmlResultEvent>
  ) => {
    const { requestId, html } = e.nativeEvent;
    const pending = pendingHtmlRequests.current.get(requestId);
    if (!pending) return;

    if (html === null || typeof html !== 'string') {
      pending.reject(new Error('Failed to parse HTML'));
    } else {
      pending.resolve(html);
    }

    pendingHtmlRequests.current.delete(requestId);
  };

  return (
    <EnrichedTextInputNativeComponent
      ref={nativeRef}
      mentionIndicators={mentionIndicators}
      editable={editable}
      autoFocus={autoFocus}
      defaultValue={defaultValue}
      placeholder={placeholder}
      placeholderTextColor={placeholderTextColor}
      cursorColor={cursorColor}
      selectionColor={selectionColor}
      style={style}
      autoCapitalize={autoCapitalize}
      htmlStyle={normalizedHtmlStyle}
      linkRegex={linkRegex}
      onInputFocus={onFocus}
      onInputBlur={onBlur}
      onChangeText={handleChangeText}
      onChangeHtml={handleChangeHtml}
      isOnChangeHtmlSet={onChangeHtml !== undefined}
      isOnChangeTextSet={onChangeText !== undefined}
      onChangeState={handleChangeState}
      onChangeStateDeprecated={handleChangeStateDeprecated}
      onLinkDetected={handleLinkDetected}
      onMentionDetected={handleMentionDetected}
      onMention={handleMentionEvent}
      onChangeSelection={handleChangeSelection}
      onRequestHtmlResult={handleRequestHtmlResult}
      onInputKeyPress={handleKeyPress}
      androidExperimentalSynchronousEvents={
        androidExperimentalSynchronousEvents
      }
      scrollEnabled={scrollEnabled}
      {...rest}
    />
  );
};
