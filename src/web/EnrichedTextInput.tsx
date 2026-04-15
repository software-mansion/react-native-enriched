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
  EnrichedTextInputWebProps,
} from '../types';
import { adaptWebToNativeEvent } from './adaptWebToNativeEvent';
import { tiptapPosToNativePos, nativePosToTiptapPos } from './positionMapping';
import { useEditor, EditorContent } from '@tiptap/react';
import Document from '@tiptap/extension-document';
import Paragraph from '@tiptap/extension-paragraph';
import Text from '@tiptap/extension-text';
import { Placeholder } from '@tiptap/extensions/placeholder';
import { useOnChangeHtml } from './useOnChangeHtml';
import { useOnChangeText } from './useOnChangeText';
import { useOnChangeState } from './useOnChangeState';
import {
  prepareHtmlForTiptap,
  normalizeHtmlFromTiptap,
} from './tiptapHtmlNormalizer';
import { ENRICHED_TEXT_INPUT_DEFAULT_PROPS } from '../utils/EnrichedTextInputDefaultProps';
import { enrichedInputStyleToCSSProperties } from './styleConversion/enrichedInputStyleToCSSProperties';
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
import {
  createStripBoldInStyledHeadingsPlugin,
  transactionStripBoldInCssBoldHeadings,
} from './pmPlugins/stripBoldInStyledHeadingsPlugin';
import { StrictMarksPlugin } from './pmPlugins/StrictMarksPlugin';
import { MergeAdjacentSameKindBlocksPlugin } from './pmPlugins/mergeAdjacentSameKindBlocksPlugin';
import { StripMarksInCodeBlockPlugin } from './pmPlugins/stripMarksInCodeBlockPlugin';

export const EnrichedTextInput = ({
  ref,
  defaultValue,
  autoFocus,
  editable = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.editable,
  placeholder = '',
  autoCapitalize = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.autoCapitalize,
  scrollEnabled = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.scrollEnabled,
  onFocus,
  style,
  onBlur,
  onChangeSelection,
  onKeyPress,
  onChangeText,
  onChangeHtml,
  onChangeState,
  htmlStyle,
}: EnrichedTextInputWebProps) => {
  const tiptapContent =
    defaultValue != null ? prepareHtmlForTiptap(defaultValue) : defaultValue;

  const resolvedHtmlStyle = useMemo(
    () => mergeWithDefaultHtmlStyle(htmlStyle),
    [htmlStyle]
  );

  const htmlStyleRef = useRef(resolvedHtmlStyle);
  htmlStyleRef.current = resolvedHtmlStyle;

  const stripBoldInStyledHeadingsPlugin = useMemo(
    () => createStripBoldInStyledHeadingsPlugin(htmlStyleRef),
    []
  );

  const editor = useEditor(
    {
      extensions: [
        Document,
        Paragraph,
        Text,
        EnrichedBold,
        EnrichedItalic,
        EnrichedUnderline,
        EnrichedStrike,
        EnrichedCode,
        EnrichedHeading,
        EnrichedBlockquote,
        EnrichedCodeBlock,
        StripMarksInCodeBlockPlugin,
        stripBoldInStyledHeadingsPlugin,
        MergeAdjacentSameKindBlocksPlugin,
        StrictMarksPlugin,
        Placeholder.configure({
          placeholder,
          showOnlyWhenEditable: true,
        }),
      ],
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
        handleKeyPress: (_, event) => {
          onKeyPress?.(adaptWebToNativeEvent(event, { key: event.key }));
          return false;
        },
        attributes: {
          autoCapitalize,
        },
      },
    },
    [tiptapContent]
  );

  useEffect(() => {
    if (!editor) return;

    const tr = transactionStripBoldInCssBoldHeadings(
      editor.state,
      resolvedHtmlStyle
    );
    if (tr) editor.view.dispatch(tr);
  }, [editor, resolvedHtmlStyle]);

  useOnChangeHtml(editor, onChangeHtml);
  useOnChangeText(editor, onChangeText);

  useOnChangeState(editor, resolvedHtmlStyle, onChangeState);

  useImperativeHandle(
    ref,
    (): EnrichedTextInputInstance => ({
      focus: () => editor.commands.focus(),
      blur: () => editor.commands.blur(),
      setValue: (value: string) =>
        editor.commands.setContent(prepareHtmlForTiptap(value)),
      setSelection: (start, end) => {
        const doc = editor.state.doc;
        editor
          .chain()
          .focus()
          .setTextSelection({
            from: nativePosToTiptapPos(doc, start),
            to: nativePosToTiptapPos(doc, end),
          })
          .run();
      },
      getHTML: () => Promise.resolve(normalizeHtmlFromTiptap(editor.getHTML())),
      toggleBold: () => editor.chain().focus().toggleBold().run(),
      toggleItalic: () => editor.chain().focus().toggleItalic().run(),
      toggleUnderline: () => editor.chain().focus().toggleUnderline().run(),
      toggleStrikeThrough: () => editor.chain().focus().toggleStrike().run(),
      toggleInlineCode: () => editor.chain().focus().toggleCode().run(),
      toggleH1: () => editor.chain().focus().toggleHeading({ level: 1 }).run(),
      toggleH2: () => editor.chain().focus().toggleHeading({ level: 2 }).run(),
      toggleH3: () => editor.chain().focus().toggleHeading({ level: 3 }).run(),
      toggleH4: () => editor.chain().focus().toggleHeading({ level: 4 }).run(),
      toggleH5: () => editor.chain().focus().toggleHeading({ level: 5 }).run(),
      toggleH6: () => editor.chain().focus().toggleHeading({ level: 6 }).run(),
      toggleCodeBlock: () =>
        editor.chain().focus().toggleEnrichedCodeBlock().run(),
      toggleBlockQuote: () => editor.chain().focus().toggleBlockquote().run(),
      toggleOrderedList: () => {},
      toggleUnorderedList: () => {},
      toggleCheckboxList: () => {},
      setLink: () => {},
      removeLink: () => {},
      setImage: () => {},
      startMention: () => {},
      setMention: () => {},
      measure: () => {},
      measureInWindow: () => {},
      measureLayout: () => {},
      setNativeProps: () => {},
    })
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
