import {
  type Component,
  type RefObject,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
} from 'react';
import { useCallback } from 'react';
import EnrichedTextInputNativeComponent, {
  Commands,
  type NativeProps,
  type OnChangeHtmlEvent,
  type OnChangeSelectionEvent,
  type OnChangeStateEvent,
  type OnChangeTextEvent,
  type OnContextMenuItemPressEvent,
  type OnLinkDetected,
  type OnMentionEvent,
  type OnMentionDetected,
  type OnMentionDetectedInternal,
  type OnRequestHtmlResultEvent,
  type OnKeyPressEvent,
  type OnPasteImagesEvent,
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
  insertValue: (text: string, start: number, end: number) => void;

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
  removeLink: (start: number, end: number) => void;
  setImage: (src: string, width: number, height: number) => void;
  startMention: (indicator: string) => void;
  setMention: (
    indicator: string,
    text: string,
    attributes?: Record<string, string>
  ) => void;
}

export interface ContextMenuItem {
  text: string;
  onPress: ({
    text,
    selection,
    styleState,
  }: {
    text: string;
    selection: { start: number; end: number };
    styleState: OnChangeStateEvent;
  }) => void;
  visible?: boolean;
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
  onLinkDetected?: (e: OnLinkDetected) => void;
  onMentionDetected?: (e: OnMentionDetected) => void;
  onStartMention?: (indicator: string) => void;
  onChangeMention?: (e: OnChangeMentionEvent) => void;
  onEndMention?: (indicator: string) => void;
  onChangeSelection?: (e: NativeSyntheticEvent<OnChangeSelectionEvent>) => void;
  onKeyPress?: (e: NativeSyntheticEvent<OnKeyPressEvent>) => void;
  onPasteImages?: (e: NativeSyntheticEvent<OnPasteImagesEvent>) => void;
  contextMenuItems?: ContextMenuItem[];
  /**
   * If true, Android will use experimental synchronous events.
   * This will prevent from input flickering when updating component size.
   * However, this is an experimental feature, which has not been thoroughly tested.
   * We may decide to enable it by default in a future release.
   * Disabled by default.
   */
  androidExperimentalSynchronousEvents?: boolean;
  /**
   * If true, external HTML (e.g. from Google Docs, Word, web pages) will be
   * normalized through the HTML normalizer before being applied.
   * This converts arbitrary HTML into the canonical tag subset that the enriched
   * parser understands.
   * Disabled by default.
   */
  useHtmlNormalizer?: boolean;
}

const warnMentionIndicators = (indicator: string) => {
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
  onLinkDetected,
  onMentionDetected,
  onStartMention,
  onChangeMention,
  onEndMention,
  onChangeSelection,
  onKeyPress,
  contextMenuItems,
  androidExperimentalSynchronousEvents = false,
  useHtmlNormalizer = false,
  scrollEnabled = true,
  ...rest
}: EnrichedTextInputProps) => {
  const nativeRef = useRef<ComponentType | null>(null);

  const nextHtmlRequestId = useRef(1);
  const pendingHtmlRequests = useRef(new Map<number, HtmlRequest>());

  // Store onPress callbacks in a ref so native only receives serializable data
  const contextMenuCallbacksRef = useRef<
    Map<string, ContextMenuItem['onPress']>
  >(new Map());

  useEffect(() => {
    const callbacksMap = new Map<string, ContextMenuItem['onPress']>();
    if (contextMenuItems) {
      for (const item of contextMenuItems) {
        callbacksMap.set(item.text, item.onPress);
      }
    }
    contextMenuCallbacksRef.current = callbacksMap;
  }, [contextMenuItems]);

  const nativeContextMenuItems = useMemo(
    () =>
      contextMenuItems
        ?.filter((item) => item.visible !== false)
        .map((item) => ({
          text: item.text,
        })),
    [contextMenuItems]
  );

  const handleContextMenuItemPress = useCallback(
    (e: NativeSyntheticEvent<OnContextMenuItemPressEvent>) => {
      const {
        itemText,
        selectedText,
        selectionStart,
        selectionEnd,
        styleState,
      } = e.nativeEvent;
      const callback = contextMenuCallbacksRef.current.get(itemText);
      callback?.({
        text: selectedText,
        selection: { start: selectionStart, end: selectionEnd },
        styleState,
      });
    },
    []
  );

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
    toggleCheckboxList: (checked: boolean) => {
      Commands.toggleCheckboxList(nullthrows(nativeRef.current), checked);
    },
    setLink: (start: number, end: number, text: string, url: string) => {
      Commands.addLink(nullthrows(nativeRef.current), start, end, text, url);
    },
    removeLink: (start: number, end: number) => {
      Commands.removeLink(nullthrows(nativeRef.current), start, end);
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
    insertValue: (text, start, end) => {
      Commands.insertValue(nullthrows(nativeRef.current), text, start, end);
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
      onChangeState={onChangeState}
      onLinkDetected={handleLinkDetected}
      onMentionDetected={handleMentionDetected}
      onMention={handleMentionEvent}
      onChangeSelection={onChangeSelection}
      onRequestHtmlResult={handleRequestHtmlResult}
      onInputKeyPress={onKeyPress}
      contextMenuItems={nativeContextMenuItems}
      onContextMenuItemPress={handleContextMenuItemPress}
      androidExperimentalSynchronousEvents={
        androidExperimentalSynchronousEvents
      }
      useHtmlNormalizer={useHtmlNormalizer}
      scrollEnabled={scrollEnabled}
      {...rest}
    />
  );
};
