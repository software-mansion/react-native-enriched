import { useImperativeHandle, type CSSProperties } from 'react';
import './EnrichedTextInput.css';
import type {
  EnrichedTextInputInstance,
  EnrichedTextInputProps,
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
import {
  prepareHtmlForTiptap,
  normalizeHtmlFromTiptap,
} from './tiptapHtmlNormalizer';
import { ENRICHED_TEXT_INPUT_DEFAULT_PROPS } from '../utils/EnrichedTextInputDefaultProps';

export const EnrichedTextInput = ({
  ref,
  defaultValue,
  autoFocus,
  editable = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.editable,
  placeholder = '',
  autoCapitalize = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.autoCapitalize,
  scrollEnabled = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.scrollEnabled,
  onFocus,
  onBlur,
  onChangeSelection,
  onKeyPress,
  onChangeText,
  onChangeHtml,
}: EnrichedTextInputProps) => {
  const tiptapContent =
    defaultValue != null ? prepareHtmlForTiptap(defaultValue) : defaultValue;

  const editor = useEditor(
    {
      extensions: [
        Document,
        Paragraph,
        Text,
        Placeholder.configure({
          placeholder,
          showOnlyWhenEditable: true,
        }),
      ],
      content: tiptapContent,
      editable,
      autofocus: autoFocus,
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

  useOnChangeHtml(editor, onChangeHtml);
  useOnChangeText(editor, onChangeText);

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
      setTextAlignment: () => {},
    })
  );

  const editorStyle: CSSProperties = {
    overflowY: scrollEnabled ? 'auto' : 'hidden',
  };

  return (
    <div>
      <EditorContent
        editor={editor}
        className="eti-editor"
        style={editorStyle}
        data-placeholder={placeholder}
      />
    </div>
  );
};
