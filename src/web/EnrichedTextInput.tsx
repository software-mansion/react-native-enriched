import { useImperativeHandle, type CSSProperties } from 'react';
import './EnrichedTextInput.css';
import type {
  EnrichedTextInputInstance,
  EnrichedTextInputProps,
} from '../types';
import { makeBlurEvent, makeFocusEvent, makeWebEvent } from './makeWebEvent';
import { useEditor, EditorContent } from '@tiptap/react';
import Document from '@tiptap/extension-document';
import Paragraph from '@tiptap/extension-paragraph';
import Text from '@tiptap/extension-text';
import { Placeholder } from '@tiptap/extensions/placeholder';
import { useOnChangeHtml } from './useOnChangeHtml';
import { useOnChangeText } from './useOnChangeText';
import getNormalizedHtml from './getNormalizedHtml';
import { ENRICHED_TEXT_INPUT_DEFAULT_PROPS } from '../utils/EnrichedTextInputDefaultProps';

export const EnrichedTextInput = ({
  ref,
  defaultValue,
  autoFocus = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.autoFocus,
  editable = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.editable,
  placeholder,
  autoCapitalize = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.autoCapitalize,
  scrollEnabled = ENRICHED_TEXT_INPUT_DEFAULT_PROPS.scrollEnabled,
  onFocus,
  onBlur,
  onChangeSelection,
  onKeyPress,
  onChangeText,
  onChangeHtml,
}: EnrichedTextInputProps) => {
  const editor = useEditor({
    extensions: [
      Document,
      Paragraph,
      Text,
      Placeholder.configure({
        placeholder: placeholder ?? '',
        showOnlyWhenEditable: true,
      }),
    ],
    content: defaultValue,
    editable: editable,
    autofocus: autoFocus,
    onFocus: () => {
      onFocus?.(makeFocusEvent());
    },
    onBlur: () => {
      onBlur?.(makeBlurEvent());
    },
    onSelectionUpdate: ({ editor: _editor }) => {
      const { state } = _editor;
      const { from, to } = state.selection;
      // Clamp to valid text positions - AllSelection (Cmd+A) uses from=0, to=doc.content.size
      // which extends beyond paragraph boundaries, unlike iOS/Android behavior.
      const clampedFrom = Math.max(1, from);
      const clampedTo = Math.min(state.doc.content.size - 1, to);

      onChangeSelection?.(
        makeWebEvent({
          start: clampedFrom - 1,
          end: clampedTo - 1,
          text: state.doc.textBetween(clampedFrom, clampedTo),
        })
      );
    },
    editorProps: {
      handleKeyPress: (_, event) => {
        onKeyPress?.(makeWebEvent({ key: event.key }));
        return false;
      },
      attributes: {
        autoCapitalize: autoCapitalize,
      },
    },
  });

  useOnChangeHtml(editor, onChangeHtml);
  useOnChangeText(editor, onChangeText);

  useImperativeHandle(
    ref,
    (): EnrichedTextInputInstance => ({
      focus: () => editor.commands.focus(),
      blur: () => editor.commands.blur(),
      setValue: (value: string) => editor.commands.setContent(value),
      setSelection: (start, end) => {
        editor
          .chain()
          .focus()
          .setTextSelection({ from: start + 1, to: end + 1 })
          .run();
      },
      getHTML: () => Promise.resolve(getNormalizedHtml(editor)),
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
