import {
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
  type CSSProperties,
} from 'react';
import './EnrichedTextInput.css';
import type {
  EnrichedTextInputInstance,
  EnrichedTextInputProps,
} from '../types';
import { adaptWebToNativeEvent } from './adaptWebToNativeEvent';
import { tiptapPosToNativePos, nativePosToTiptapPos } from './positionMapping';
import {
  useEditor,
  EditorContent,
  type ChainedCommands,
  Editor,
} from '@tiptap/react';
import Document from '@tiptap/extension-document';
import Paragraph from '@tiptap/extension-paragraph';
import Text from '@tiptap/extension-text';
import { Placeholder } from '@tiptap/extensions/placeholder';
import { useOnChangeHtml } from './useOnChangeHtml';
import { useOnChangeText } from './useOnChangeText';
import { useOnChangeState } from './useOnChangeState';
import { useOnLinkDetected } from './useOnLinkDetected';
import {
  prepareHtmlForTiptap,
  normalizeHtmlFromTiptap,
} from './tiptapHtmlNormalizer';
import { ENRICHED_TEXT_INPUT_DEFAULT_PROPS } from '../utils/EnrichedTextInputDefaultProps';
import { enrichedInputStyleToCSSProperties } from './styleConversion/enrichedInputStyleToCSSProperties';
import {
  htmlStyleToCSSVariables,
  mergeWithDefaultHtmlStyle,
  mentionIndicatorCssRules,
} from './styleConversion/htmlStyleToCSSVariables';
import { EnrichedBold } from './formats/EnrichedBold';
import { EnrichedItalic } from './formats/EnrichedItalic';
import { EnrichedStrike } from './formats/EnrichedStrike';
import { EnrichedUnderline } from './formats/EnrichedUnderline';
import { EnrichedCode } from './formats/EnrichedCode';
import { EnrichedHeading } from './formats/EnrichedHeading';
import { EnrichedBlockquote } from './formats/EnrichedBlockquote';
import { EnrichedCodeBlock } from './formats/EnrichedCodeBlock';
import { EnrichedLink, setLink, removeLink } from './formats/EnrichedLink';
import { EnrichedMention } from './formats/EnrichedMention';
import { EnrichedListItem } from './formats/EnrichedListItem';
import { EnrichedUnorderedList } from './formats/EnrichedUnorderedList';
import { EnrichedOrderedList } from './formats/EnrichedOrderedList';
import { EnrichedCheckboxItem } from './formats/EnrichedCheckboxItem';
import { EnrichedCheckboxList } from './formats/EnrichedCheckboxList';
import { createStripBoldInStyledHeadingsPlugin } from './pmPlugins/stripBoldInStyledHeadingsPlugin';
import { StrictMarksPlugin } from './pmPlugins/strictMarksPlugin';
import { MergeAdjacentSameKindBlocksPlugin } from './pmPlugins/mergeAdjacentSameKindBlocksPlugin';
import { StripMarksInCodeBlockPlugin } from './pmPlugins/stripMarksInCodeBlockPlugin';
import {
  createMentionPlugin,
  mentionPluginKey,
  setMention,
  startMention,
  subscribeMentionEvents,
} from './pmPlugins/mentionPlugin';

function runFocused(
  editor: Editor,
  apply: (chain: ChainedCommands) => ChainedCommands
) {
  apply(editor.chain().focus()).run();
}

export const EnrichedTextInput = ({
  ref,
  defaultValue,
  autoFocus,
  editable = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.editable,
  placeholder = '',
  autoCapitalize = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.autoCapitalize,
  scrollEnabled = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.scrollEnabled,
  mentionIndicators = ['@'],
  onFocus,
  style,
  onBlur,
  onChangeSelection,
  onKeyPress,
  onChangeText,
  onChangeHtml,
  onChangeState,
  onLinkDetected,
  onMentionDetected,
  onStartMention,
  onChangeMention,
  onEndMention,
  htmlStyle,
}: EnrichedTextInputProps) => {
  const tiptapContent =
    defaultValue != null ? prepareHtmlForTiptap(defaultValue) : defaultValue;

  const resolvedHtmlStyle = useMemo(
    () => mergeWithDefaultHtmlStyle(htmlStyle),
    [htmlStyle]
  );

  const htmlStyleRef = useRef(resolvedHtmlStyle);
  useEffect(() => {
    htmlStyleRef.current = resolvedHtmlStyle;
  }, [resolvedHtmlStyle]);

  const stripBoldInStyledHeadingsPlugin = useMemo(
    () => createStripBoldInStyledHeadingsPlugin(() => htmlStyleRef.current),
    []
  );

  // Mention indicators ref
  const mentionIndicatorsRef = useRef(mentionIndicators);
  useEffect(() => {
    mentionIndicatorsRef.current = mentionIndicators;
  }, [mentionIndicators]);

  // Mention callbacks ref
  const mentionCallbacksRef = useRef({
    onStartMention,
    onChangeMention,
    onEndMention,
    onMentionDetected,
  });
  useEffect(() => {
    mentionCallbacksRef.current = {
      onStartMention,
      onChangeMention,
      onEndMention,
      onMentionDetected,
    };
  }, [onStartMention, onChangeMention, onEndMention, onMentionDetected]);

  const mentionPlugin = useMemo(
    () =>
      createMentionPlugin({
        indicatorsRef: mentionIndicatorsRef,
        callbacksRef: mentionCallbacksRef,
      }),
    []
  );

  const extensions = useMemo(
    () => [
      Document,
      Paragraph,
      Text,
      EnrichedBold,
      EnrichedItalic,
      EnrichedUnderline,
      EnrichedStrike,
      EnrichedCode,
      EnrichedLink,
      EnrichedMention,
      EnrichedHeading,
      EnrichedBlockquote,
      EnrichedCodeBlock,
      EnrichedListItem,
      EnrichedCheckboxItem,
      EnrichedUnorderedList,
      EnrichedOrderedList,
      EnrichedCheckboxList,
      StripMarksInCodeBlockPlugin,
      stripBoldInStyledHeadingsPlugin,
      MergeAdjacentSameKindBlocksPlugin,
      StrictMarksPlugin,
      mentionPlugin,
      Placeholder.configure({
        placeholder,
        showOnlyWhenEditable: true,
      }),
    ],
    [stripBoldInStyledHeadingsPlugin, mentionPlugin, placeholder]
  );

  const editor = useEditor(
    {
      extensions,
      editable,
      autofocus: autoFocus,
      onCreate: ({ editor: _editor }) => {
        // Setting initial content in this way ensures all custom plugins are run and applied
        _editor.commands.setContent(tiptapContent ?? '');
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
        const text = state.doc.textBetween(from, to, '\n');
        onChangeSelection?.(adaptWebToNativeEvent(null, { start, end, text }));
      },
      editorProps: {
        handleKeyDown: (_, event) => {
          onKeyPress?.(adaptWebToNativeEvent(event, { key: event.key }));
          return false;
        },
        attributes: {
          autoCapitalize,
        },
      },
    },
    [tiptapContent, extensions]
  );

  useEffect(() => {
    editor?.commands.normalizeBoldInStyledHeadings();
  }, [editor, resolvedHtmlStyle]);

  // Subscribe to mention lifecycle and detection events
  useEffect(() => {
    if (!editor) return;
    return subscribeMentionEvents(editor, mentionCallbacksRef);
  }, [editor]);

  useOnChangeHtml(editor, onChangeHtml);
  useOnChangeText(editor, onChangeText);
  useOnChangeState(editor, resolvedHtmlStyle, onChangeState);
  useOnLinkDetected(editor, onLinkDetected);

  // Inject per-indicator mention CSS rules (for multi-indicator htmlStyle)
  useEffect(() => {
    const css = mentionIndicatorCssRules(resolvedHtmlStyle.mention);
    if (!css) return;
    const styleEl = document.createElement('style');
    styleEl.setAttribute('data-eti-mention-indicator', '');
    styleEl.textContent = css;
    document.head.appendChild(styleEl);
    return () => {
      document.head.removeChild(styleEl);
    };
  }, [resolvedHtmlStyle.mention]);

  useImperativeHandle(
    ref,
    (): EnrichedTextInputInstance => ({
      focus: () => editor.commands.focus(),
      blur: () => editor.commands.blur(),
      setValue: (value: string) =>
        editor.commands.setContent(prepareHtmlForTiptap(value)),
      setSelection: (start, end) => {
        const doc = editor.state.doc;
        runFocused(editor, (c) =>
          c.setTextSelection({
            from: nativePosToTiptapPos(doc, start),
            to: nativePosToTiptapPos(doc, end),
          })
        );
      },
      getHTML: () => Promise.resolve(normalizeHtmlFromTiptap(editor.getHTML())),
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
        setLink(editor, start, end, text, url),
      removeLink: (start: number, end: number) =>
        removeLink(editor, start, end),
      setImage: () => {},
      startMention: (indicator: string) => {
        startMention(editor, indicator, mentionIndicatorsRef.current);
      },
      setMention: (
        indicator: string,
        text: string,
        attributes?: Record<string, string>
      ) => {
        // Dev ergonomics: warn if indicator doesn't match the active trigger indicator
        const triggerState = mentionPluginKey.getState(editor.state);
        if (triggerState?.active && triggerState.indicator !== indicator) {
          console.warn(
            `[EnrichedMention] setMention called with indicator "${indicator}" but active trigger indicator is "${triggerState.indicator}"`
          );
        }
        setMention(editor, text, attributes);
      },
      measure: () => {},
      measureInWindow: () => {},
      measureLayout: () => {},
      setNativeProps: () => {},
    }),
    [editor]
  );

  const editorStyle: CSSProperties = useMemo(
    () => enrichedInputStyleToCSSProperties(style ?? {}, { scrollEnabled }),
    [scrollEnabled, style]
  );

  const cssVars = useMemo(
    () => htmlStyleToCSSVariables(resolvedHtmlStyle),
    [resolvedHtmlStyle]
  );

  const finalStyle = useMemo(
    () => ({ ...editorStyle, ...cssVars }),
    [editorStyle, cssVars]
  );

  return (
    <EditorContent
      editor={editor}
      className="eti-editor"
      style={finalStyle}
      data-placeholder={placeholder}
    />
  );
};
