import {
  useCallback,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
  type CSSProperties,
} from 'react';
import './EnrichedText.css';
import type { Node } from '@tiptap/pm/model';
import type {
  EnrichedTextInputInstance,
  EnrichedTextInputProps,
} from '../types';
import { adaptWebToNativeEvent } from './nativeMappers/adaptWebToNativeEvent';
import {
  tiptapPosToNativePos,
  nativePosToTiptapPos,
  nativeLeafText,
} from './nativeMappers/positionMapping';
import {
  useEditor,
  EditorContent,
  type ChainedCommands,
  Editor,
} from '@tiptap/react';
import Document from '@tiptap/extension-document';
import Paragraph from '@tiptap/extension-paragraph';
import Text from '@tiptap/extension-text';
import History from '@tiptap/extension-history';
import { Placeholder } from '@tiptap/extensions/placeholder';
import { useOnChangeHtml } from './tiptapWatchers/useOnChangeHtml';
import { useOnChangeText } from './tiptapWatchers/useOnChangeText';
import { useOnChangeState } from './tiptapWatchers/useOnChangeState';
import { useOnLinkDetected } from './tiptapWatchers/useOnLinkDetected';
import type { LinkEmitterState } from './tiptapWatchers/emitLinkDetected';
import {
  prepareHtmlForTiptap,
  normalizeHtmlFromTiptap,
} from './normalization/tiptapHtmlNormalizer';
import { ENRICHED_TEXT_INPUT_DEFAULT_PROPS } from '../utils/EnrichedTextInputDefaultProps';
import { enrichedInputStyleToCSSProperties } from './styleConversion/enrichedInputStyleToCSSProperties';
import { enrichedInputThemingToCSSProperties } from './styleConversion/enrichedThemingToCSSProperties';
import { buildMentionRulesCSS } from './styleConversion/buildMentionRulesCSS';
import {
  htmlStyleToCSSVariables,
  mergeWithDefaultHtmlStyle,
} from './styleConversion/htmlStyleToCSSVariables';
import { EnrichedBold } from './formats/EnrichedBold';
import { EnrichedItalic } from './formats/EnrichedItalic';
import { EnrichedStrike } from './formats/EnrichedStrike';
import { EnrichedUnderline } from './formats/EnrichedUnderline';
import { EnrichedCode } from './formats/EnrichedCode';
import { EnrichedHeading } from './formats/EnrichedHeading';
import { EnrichedBlockquote } from './formats/EnrichedBlockquote';
import { EnrichedCodeBlock } from './formats/EnrichedCodeBlock';
import { EnrichedImage } from './formats/EnrichedImage';
import { EnrichedLink, setLink, removeLink } from './formats/EnrichedLink';
import { EnrichedMention } from './formats/EnrichedMention';
import { EnrichedListItem } from './formats/EnrichedListItem';
import { EnrichedUnorderedList } from './formats/EnrichedUnorderedList';
import { EnrichedOrderedList } from './formats/EnrichedOrderedList';
import { EnrichedCheckboxItem } from './formats/EnrichedCheckboxItem';
import { EnrichedCheckboxList } from './formats/EnrichedCheckboxList';
import { EnrichedTextAlign } from './formats/EnrichedTextAlign';
import { StripBoldInStyledHeadingsPlugin } from './pmPlugins/StripBoldInStyledHeadingsPlugin';
import { StrictMarksPlugin } from './pmPlugins/StrictMarksPlugin';
import { MergeAdjacentSameKindBlocksPlugin } from './pmPlugins/MergeAdjacentSameKindBlocksPlugin';
import { OrderedListMarkerWidthPlugin } from './pmPlugins/OrderedListMarkerWidthPlugin';
import { StripMarksInCodeBlockPlugin } from './pmPlugins/StripMarksInCodeBlockPlugin';
import { handleClipboardPasteImages } from './utils/pasteImages';
import {
  MentionPlugin,
  setMention,
  startMention,
  useMentionEvents,
} from './pmPlugins/MentionPlugin';
import { StripMarksOnImagePlugin } from './pmPlugins/StripMarksOnImagePlugin';
import { ShortcutPlugin } from './pmPlugins/ShortcutPlugin';
import { TextShortcutsPlugin } from './pmPlugins/TextShortcutsPlugin';
import { returnKeyTypeToEnterKeyHint } from './nativeMappers/returnKeyTypeToEnterKeyHint';
import { ENRICHED_TEXT_INPUT_CLASSNAME } from './constants/classNames';
import { AutolinkPlugin } from './pmPlugins/AutolinkPlugin';
import { useStableRef } from './utils/useStableRef';
import {
  checkMentionAttributes,
  sanitizeMentionAttributes,
} from './sanitization/htmlSanitizer';
import { assertBrowserEnvironment } from './utils/assertBrowserEnvironment';
import { runSafelyInEditor } from './utils/runSafelyInEditor';

function runFocused(
  editor: Editor,
  apply: (chain: ChainedCommands) => ChainedCommands
) {
  runSafelyInEditor(editor, (e) => apply(e.chain().focus()).run());
}

export const EnrichedTextInput = ({
  ref,
  defaultValue,
  autoFocus = false,
  editable = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.editable,
  placeholder = '',
  placeholderTextColor,
  cursorColor,
  selectionColor,
  autoCapitalize = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.autoCapitalize,
  scrollEnabled = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.scrollEnabled,
  mentionIndicators = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.mentionIndicators.slice(),
  onFocus,
  style,
  onBlur,
  onChangeSelection,
  onKeyPress,
  onChangeText,
  onChangeHtml,
  onChangeState,
  onLinkDetected,
  onSubmitEditing,
  returnKeyType,
  submitBehavior,
  onPasteImages,
  onMentionDetected,
  onStartMention,
  onChangeMention,
  onEndMention,
  linkRegex,
  htmlStyle,
  useHtmlNormalizer = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.useHtmlNormalizer,
  sanitizationConfig,
  textShortcuts = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.textShortcuts,
}: EnrichedTextInputProps) => {
  assertBrowserEnvironment('EnrichedTextInput');

  const tiptapContent =
    defaultValue != null
      ? prepareHtmlForTiptap(
          defaultValue,
          useHtmlNormalizer,
          sanitizationConfig
        )
      : defaultValue;

  const resolvedHtmlStyle = useMemo(
    () => mergeWithDefaultHtmlStyle(htmlStyle),
    [htmlStyle]
  );
  const mentionCallbacks = useMemo(
    () => ({
      onStartMention,
      onChangeMention,
      onEndMention,
      onMentionDetected,
    }),
    [onStartMention, onChangeMention, onEndMention, onMentionDetected]
  );

  const htmlStyleRef = useStableRef(resolvedHtmlStyle);
  const onPasteImagesRef = useStableRef(onPasteImages);
  const mentionIndicatorsRef = useStableRef(mentionIndicators);
  const submitBehaviorRef = useStableRef(submitBehavior);
  const onSubmitEditingRef = useStableRef(onSubmitEditing);
  const onKeyPressRef = useStableRef(onKeyPress);
  const useHtmlNormalizerRef = useStableRef(useHtmlNormalizer);
  const sanitizationConfigRef = useStableRef(sanitizationConfig);
  const mentionCallbacksRef = useStableRef(mentionCallbacks);
  const textShortcutsRef = useStableRef(textShortcuts);

  const editorInstanceRef = useRef<Editor | null>(null);

  const handleKeyDown = (doc: Node, event: KeyboardEvent): boolean => {
    onKeyPressRef.current?.(adaptWebToNativeEvent(event, { key: event.key }));
    if (event.key !== 'Enter') {
      return false;
    }

    const sb = submitBehaviorRef.current;
    if (sb === 'submit' || sb === 'blurAndSubmit') {
      event.preventDefault();
      const text = nativeLeafText(doc, 0, doc.content.size);
      onSubmitEditingRef.current?.(adaptWebToNativeEvent(event, { text }));
      if (sb === 'blurAndSubmit') {
        runSafelyInEditor(editorInstanceRef.current, (e) => e.commands.blur());
      }
      return true;
    }

    return false;
  };

  const linkEmitterRef = useRef<LinkEmitterState>({
    linkRegex,
    onLinkDetected,
    lastEmitted: null,
  });
  useEffect(() => {
    linkEmitterRef.current.linkRegex = linkRegex;
    linkEmitterRef.current.onLinkDetected = onLinkDetected;
  }, [linkRegex, onLinkDetected]);

  const extensions = useMemo(
    () => [
      Document,
      Paragraph,
      Text,
      History,
      EnrichedBold,
      EnrichedItalic,
      EnrichedUnderline,
      EnrichedStrike,
      EnrichedCode,
      EnrichedLink.configure({
        getLinkRegex: () => linkEmitterRef.current.linkRegex,
      }),
      EnrichedImage,
      EnrichedMention,
      EnrichedHeading,
      EnrichedBlockquote,
      EnrichedCodeBlock,
      EnrichedListItem,
      EnrichedCheckboxItem,
      EnrichedUnorderedList,
      EnrichedOrderedList,
      EnrichedCheckboxList,
      EnrichedTextAlign,
      StripMarksInCodeBlockPlugin,
      StripMarksOnImagePlugin,
      StripBoldInStyledHeadingsPlugin.configure({
        getHtmlStyle: () => htmlStyleRef.current,
      }),
      MergeAdjacentSameKindBlocksPlugin,
      OrderedListMarkerWidthPlugin,
      StrictMarksPlugin,
      MentionPlugin.configure({
        getIndicators: () => mentionIndicatorsRef.current,
      }),
      ShortcutPlugin.configure({
        getHtmlStyle: () => htmlStyleRef.current,
      }),
      TextShortcutsPlugin.configure({
        getTextShortcuts: () => textShortcutsRef.current,
        getHtmlStyle: () => htmlStyleRef.current,
      }),
      AutolinkPlugin.configure({
        getLinkEmitter: () => linkEmitterRef.current,
      }),
      Placeholder.configure({
        placeholder,
        showOnlyWhenEditable: true,
      }),
    ],
    [placeholder, htmlStyleRef, mentionIndicatorsRef, textShortcutsRef]
  );

  const editor = useEditor(
    {
      extensions,
      editable,
      autofocus: autoFocus,
      onCreate: ({ editor: _editor }) => {
        // Setting initial content in this way ensures all custom plugins are run and applied
        runSafelyInEditor(_editor, (e) =>
          e.commands.setContent(tiptapContent ?? '')
        );
      },
      onFocus: ({ event }) => {
        onFocus?.(adaptWebToNativeEvent(event, { target: -1 }));
      },
      onBlur: ({ event }) => {
        onBlur?.(adaptWebToNativeEvent(event, { target: -1 }));
      },
      onSelectionUpdate: ({ editor: _editor }) => {
        const { state } = _editor;
        const { from, to } = state.selection;

        const start = tiptapPosToNativePos(state.doc, from);
        const end = tiptapPosToNativePos(state.doc, to);
        const text = nativeLeafText(state.doc, from, to);
        onChangeSelection?.(adaptWebToNativeEvent(null, { start, end, text }));
      },
      editorProps: {
        handleKeyDown: (view, event) => handleKeyDown(view.state.doc, event),
        handlePaste: (_view, event) =>
          handleClipboardPasteImages(
            event,
            () => editorInstanceRef.current,
            () => onPasteImagesRef.current
          ),
        attributes: {
          autoCapitalize,
          enterkeyhint: returnKeyTypeToEnterKeyHint(returnKeyType),
        },
        transformPastedHTML: (html) => {
          return prepareHtmlForTiptap(
            html,
            useHtmlNormalizerRef.current,
            sanitizationConfigRef.current
          );
        },
      },
    },
    [tiptapContent, extensions]
  );

  useEffect(() => {
    editorInstanceRef.current = editor ?? null;
  }, [editor]);

  useEffect(() => {
    if (!editor) return;
    let dom: HTMLElement;
    try {
      dom = editor.view.dom;
    } catch {
      return;
    }
    dom.setAttribute(
      'enterkeyhint',
      returnKeyTypeToEnterKeyHint(returnKeyType)
    );
  }, [editor, returnKeyType]);

  useEffect(() => {
    runSafelyInEditor(editor, (e) =>
      e.commands.normalizeBoldInStyledHeadings()
    );
  }, [editor, resolvedHtmlStyle]);

  const getMentionCallbacks = useCallback(
    () => mentionCallbacksRef.current,
    [mentionCallbacksRef]
  );

  useMentionEvents(editor, getMentionCallbacks);
  useOnChangeHtml(editor, () => sanitizationConfigRef.current, onChangeHtml);
  useOnChangeText(editor, onChangeText);
  useOnChangeState(editor, resolvedHtmlStyle, onChangeState);
  useOnLinkDetected(editor, linkEmitterRef);

  useImperativeHandle(
    ref,
    (): EnrichedTextInputInstance => ({
      focus: () => runSafelyInEditor(editor, (e) => e.commands.focus()),
      blur: () => runSafelyInEditor(editor, (e) => e.commands.blur()),
      setValue: (value: string) =>
        runSafelyInEditor(editor, (e) =>
          e.commands.setContent(
            prepareHtmlForTiptap(
              value,
              useHtmlNormalizerRef.current,
              sanitizationConfigRef.current
            )
          )
        ),
      setSelection: (start, end) => {
        const doc = editor.state.doc;
        runFocused(editor, (c) =>
          c.setTextSelection({
            from: nativePosToTiptapPos(doc, start),
            to: nativePosToTiptapPos(doc, end),
          })
        );
      },
      getHTML: () =>
        Promise.resolve(
          normalizeHtmlFromTiptap(
            editor.getHTML(),
            () => sanitizationConfigRef.current
          )
        ),
      toggleBold: () => runFocused(editor, (c) => c.toggleBold()),
      toggleItalic: () => runFocused(editor, (c) => c.toggleItalic()),
      toggleUnderline: () => runFocused(editor, (c) => c.toggleUnderline()),
      toggleStrikeThrough: () => runFocused(editor, (c) => c.toggleStrike()),
      toggleInlineCode: () => runFocused(editor, (c) => c.toggleCode()),
      toggleH1: () => runFocused(editor, (c) => c.toggleHeading({ level: 1 })),
      toggleH2: () => runFocused(editor, (c) => c.toggleHeading({ level: 2 })),
      toggleH3: () => runFocused(editor, (c) => c.toggleHeading({ level: 3 })),
      toggleH4: () => runFocused(editor, (c) => c.toggleHeading({ level: 4 })),
      toggleH5: () => runFocused(editor, (c) => c.toggleHeading({ level: 5 })),
      toggleH6: () => runFocused(editor, (c) => c.toggleHeading({ level: 6 })),
      toggleCodeBlock: () => runFocused(editor, (c) => c.toggleCodeBlock()),
      toggleBlockQuote: () => runFocused(editor, (c) => c.toggleBlockquote()),
      toggleOrderedList: () => runFocused(editor, (c) => c.toggleOrderedList()),
      toggleUnorderedList: () =>
        runFocused(editor, (c) => c.toggleUnorderedList()),
      toggleCheckboxList: (checked: boolean) =>
        runFocused(editor, (c) => c.toggleCheckboxList(checked)),
      setLink: (start: number, end: number, text: string, url: string) =>
        runSafelyInEditor(editor, (e) => setLink(e, start, end, text, url)),
      removeLink: (start: number, end: number) =>
        runSafelyInEditor(editor, (e) => removeLink(e, start, end)),
      startMention: (indicator: string) => {
        runSafelyInEditor(editor, (e) =>
          startMention(e, indicator, mentionIndicatorsRef.current)
        );
      },
      setMention: (
        indicator: string,
        text: string,
        attributes?: Record<string, string>
      ) => {
        checkMentionAttributes(attributes);
        runSafelyInEditor(editor, (e) =>
          setMention(e, indicator, text, sanitizeMentionAttributes(attributes))
        );
      },
      setImage: (src: string, width: number, height: number) =>
        runFocused(editor, (c) => c.setImage({ src, width, height })),
      measure: () => {},
      measureInWindow: () => {},
      measureLayout: () => {},
      setNativeProps: () => {},
      setTextAlignment: (alignment) => {
        if (alignment === 'auto') {
          runFocused(editor, (c) => c.unsetTextAlign());
        } else {
          runFocused(editor, (c) => c.setTextAlign(alignment));
        }
      },
    }),
    [editor, mentionIndicatorsRef, useHtmlNormalizerRef, sanitizationConfigRef]
  );

  const editorStyle: CSSProperties = useMemo(
    () => enrichedInputStyleToCSSProperties(style ?? {}, { scrollEnabled }),
    [scrollEnabled, style]
  );

  const cssVars = useMemo(
    () => htmlStyleToCSSVariables(resolvedHtmlStyle),
    [resolvedHtmlStyle]
  );

  const themingStyle = useMemo(
    (): CSSProperties =>
      enrichedInputThemingToCSSProperties({
        cursorColor,
        placeholderTextColor,
        selectionColor,
      }),
    [cursorColor, placeholderTextColor, selectionColor]
  );

  const mentionRulesCSS = useMemo(
    () => buildMentionRulesCSS(resolvedHtmlStyle),
    [resolvedHtmlStyle]
  );

  const finalStyle = useMemo(
    () => ({ ...editorStyle, ...cssVars, ...themingStyle }),
    [editorStyle, cssVars, themingStyle]
  );

  return (
    <>
      {mentionRulesCSS ? <style>{mentionRulesCSS}</style> : null}
      <EditorContent
        editor={editor}
        className={ENRICHED_TEXT_INPUT_CLASSNAME}
        style={finalStyle}
        data-placeholder={placeholder}
      />
    </>
  );
};
