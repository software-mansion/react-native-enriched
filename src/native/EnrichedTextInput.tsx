import {
  type Component,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
} from 'react';
import { useCallback } from 'react';
import EnrichedTextInputNativeComponent, {
  Commands,
  type NativeProps,
  type OnContextMenuItemPressEvent,
  type OnMentionEvent,
  type OnMentionDetectedInternal,
  type OnRequestHtmlResultEvent,
} from '../spec/EnrichedTextInputNativeComponent';
import type {
  HostInstance,
  MeasureInWindowOnSuccessCallback,
  MeasureLayoutOnSuccessCallback,
  MeasureOnSuccessCallback,
  NativeMethods,
  NativeSyntheticEvent,
} from 'react-native';
import { normalizeHtmlStyle } from '../utils/normalizeHtmlStyle';
import { toNativeRegexConfig } from '../utils/regexParser';
import { nullthrows } from '../utils/nullthrows';
import { ENRICHED_TEXT_INPUT_DEFAULT_PROPS } from '../utils/EnrichedTextInputDefaultProps';
import type {
  ContextMenuItem,
  EnrichedTextInputProps,
  OnLinkDetected,
  OnMentionDetected,
} from '../types';

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
  autoFocus = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.autoFocus,
  editable = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.editable,
  mentionIndicators = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.mentionIndicators.slice(),
  defaultValue,
  placeholder,
  placeholderTextColor,
  cursorColor,
  selectionColor,
  style,
  autoCapitalize = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.autoCapitalize,
  htmlStyle = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.htmlStyle,
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
  onSubmitEditing,
  returnKeyType,
  returnKeyLabel,
  submitBehavior,
  contextMenuItems,
  androidExperimentalSynchronousEvents = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.androidExperimentalSynchronousEvents,
  useHtmlNormalizer = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.useHtmlNormalizer,
  scrollEnabled = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.scrollEnabled,
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
    onMentionDetected?.({
      text,
      indicator,
      attributes,
    } satisfies OnMentionDetected);
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
      onSubmitEditing={onSubmitEditing}
      returnKeyType={returnKeyType}
      returnKeyLabel={returnKeyLabel}
      submitBehavior={submitBehavior}
      androidExperimentalSynchronousEvents={
        androidExperimentalSynchronousEvents
      }
      useHtmlNormalizer={useHtmlNormalizer}
      scrollEnabled={scrollEnabled}
      {...rest}
    />
  );
};
