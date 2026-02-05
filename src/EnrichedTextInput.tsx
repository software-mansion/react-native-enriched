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
  type OnChangeHtmlEvent,
  type OnChangeSelectionEvent,
  type OnChangeStateEvent,
  type OnChangeTextEvent,
  type OnLinkDetected,
  type OnMentionEvent,
  type OnMentionDetected,
  type OnMentionDetectedInternal,
  type OnRequestHtmlResultEvent,
  type OnChangeStateDeprecatedEvent,
  type OnKeyPressEvent,
} from './spec/EnrichedTextInputNativeComponent';
import type {
  ColorValue,
  HostInstance,
  MeasureInWindowOnSuccessCallback,
  MeasureLayoutOnSuccessCallback,
  MeasureOnSuccessCallback,
  NativeMethods,
  NativeSyntheticEvent,
  TargetedEvent,
  TextStyle,
  ViewProps,
  ViewStyle,
} from 'react-native';
import { normalizeHtmlStyle } from './utils/normalizeHtmlStyle';
import { toNativeRegexConfig } from './utils/regexParser';
import { nullthrows } from './utils/nullthrows';
import type { HtmlStyle } from './types';

export type FocusEvent = NativeSyntheticEvent<TargetedEvent>;
export type BlurEvent = NativeSyntheticEvent<TargetedEvent>;

export interface EnrichedTextInputInstance extends NativeMethods {
  // General commands
  focus: () => void;
  blur: () => void;
  setValue: (value: string) => void;
  setSelection: (start: number, end: number) => void;
  getHTML: () => Promise<string>;

  // Text formatting commands
  toggleBold: () => void;
  toggleItalic: () => void;
  toggleUnderline: () => void;
  toggleStrikeThrough: () => void;
  toggleInlineCode: () => void;
  toggleH1: () => void;
  toggleH2: () => void;
  toggleH3: () => void;
  toggleH4: () => void;
  toggleH5: () => void;
  toggleH6: () => void;
  toggleCodeBlock: () => void;
  toggleBlockQuote: () => void;
  toggleOrderedList: () => void;
  toggleUnorderedList: () => void;
  toggleCheckboxList: (checked: boolean) => void;
  setLink: (start: number, end: number, text: string, url: string) => void;
  setImage: (src: string, width: number, height: number) => void;
  startMention: (indicator: string) => void;
  setMention: (
    indicator: string,
    text: string,
    attributes?: Record<string, string>
  ) => void;
}

export interface OnChangeMentionEvent {
  indicator: string;
  text: string;
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
  onFocus?: (e: FocusEvent) => void;
  onBlur?: (e: BlurEvent) => void;
  onChangeText?: (e: NativeSyntheticEvent<OnChangeTextEvent>) => void;
  onChangeHtml?: (e: NativeSyntheticEvent<OnChangeHtmlEvent>) => void;
  onChangeState?: (e: NativeSyntheticEvent<OnChangeStateEvent>) => void;
  /**
   * @deprecated Use onChangeState prop instead.
   */
  onChangeStateDeprecated?: (
    e: NativeSyntheticEvent<OnChangeStateDeprecatedEvent>
  ) => void;
  onLinkDetected?: (e: OnLinkDetected) => void;
  onMentionDetected?: (e: OnMentionDetected) => void;
  onStartMention?: (indicator: string) => void;
  onChangeMention?: (e: OnChangeMentionEvent) => void;
  onEndMention?: (indicator: string) => void;
  onChangeSelection?: (e: NativeSyntheticEvent<OnChangeSelectionEvent>) => void;
  onKeyPress?: (e: NativeSyntheticEvent<OnKeyPressEvent>) => void;
  /**
   * If true, Android will use experimental synchronous events.
   * This will prevent from input flickering when updating component size.
   * However, this is an experimental feature, which has not been thoroughly tested.
   * We may decide to enable it by default in a future release.
   * Disabled by default.
   */
  androidExperimentalSynchronousEvents?: boolean;
}

const warnMentionIndicators = (indicator: string) => {
  console.warn(
    `Looks like you are trying to set a "${indicator}" but it's not in the mentionIndicators prop`
  );
};

const warnConflictingFontSize = () => {
  console.warn(
    'Using the same fontSize for the editor and for heading styles may lead to unexpected behavior. Please consider using different font sizes.'
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
  editable = true,
  mentionIndicators = ['@'],
  defaultValue,
  placeholder,
  placeholderTextColor,
  cursorColor,
  selectionColor,
  style,
  autoCapitalize = 'sentences',
  htmlStyle = {},
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
  androidExperimentalSynchronousEvents = false,
  scrollEnabled = true,
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

  if (__DEV__) {
    const fontSize = (style as TextStyle | undefined)?.fontSize;
    // That's not breaking the rules of hooks because it's conditional on __DEV__ which is a compile time constant
    // eslint-disable-next-line react-hooks/rules-of-hooks
    useEffect(() => {
      if (!fontSize) return;

      const fontSizes = [
        normalizedHtmlStyle.h1?.fontSize,
        normalizedHtmlStyle.h2?.fontSize,
        normalizedHtmlStyle.h3?.fontSize,
        normalizedHtmlStyle.h4?.fontSize,
        normalizedHtmlStyle.h5?.fontSize,
        normalizedHtmlStyle.h6?.fontSize,
      ];

      if (fontSizes.includes(fontSize)) {
        warnConflictingFontSize();
      }
    }, [normalizedHtmlStyle, fontSize]);
  }

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
    toggleCheckboxList: (checked: boolean) => {
      Commands.toggleCheckboxList(nullthrows(nativeRef.current), checked);
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
        warnMentionIndicators(indicator);
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

  const handleLinkDetected = (e: NativeSyntheticEvent<OnLinkDetected>) => {
    const { text, url, start, end } = e.nativeEvent;
    onLinkDetected?.({ text, url, start, end });
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

  const onChangeStateWithDeprecated = (
    e: NativeSyntheticEvent<OnChangeStateEvent>
  ) => {
    onChangeState?.(e);
    // TODO: remove in 0.5.0 release
    onChangeStateDeprecated?.({
      ...e,
      nativeEvent: {
        isBold: e.nativeEvent.bold.isActive,
        isItalic: e.nativeEvent.italic.isActive,
        isUnderline: e.nativeEvent.underline.isActive,
        isStrikeThrough: e.nativeEvent.strikeThrough.isActive,
        isInlineCode: e.nativeEvent.inlineCode.isActive,
        isH1: e.nativeEvent.h1.isActive,
        isH2: e.nativeEvent.h2.isActive,
        isH3: e.nativeEvent.h3.isActive,
        isH4: e.nativeEvent.h4.isActive,
        isH5: e.nativeEvent.h5.isActive,
        isH6: e.nativeEvent.h6.isActive,
        isCodeBlock: e.nativeEvent.codeBlock.isActive,
        isBlockQuote: e.nativeEvent.blockQuote.isActive,
        isOrderedList: e.nativeEvent.orderedList.isActive,
        isUnorderedList: e.nativeEvent.unorderedList.isActive,
        isCheckboxList: e.nativeEvent.checkboxList.isActive,
        isLink: e.nativeEvent.link.isActive,
        isImage: e.nativeEvent.image.isActive,
        isMention: e.nativeEvent.mention.isActive,
      },
    });
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
      onChangeText={onChangeText}
      onChangeHtml={onChangeHtml}
      isOnChangeHtmlSet={onChangeHtml !== undefined}
      isOnChangeTextSet={onChangeText !== undefined}
      onChangeState={onChangeStateWithDeprecated}
      onLinkDetected={handleLinkDetected}
      onMentionDetected={handleMentionDetected}
      onMention={handleMentionEvent}
      onChangeSelection={onChangeSelection}
      onRequestHtmlResult={handleRequestHtmlResult}
      onInputKeyPress={onKeyPress}
      androidExperimentalSynchronousEvents={
        androidExperimentalSynchronousEvents
      }
      scrollEnabled={scrollEnabled}
      {...rest}
    />
  );
};
