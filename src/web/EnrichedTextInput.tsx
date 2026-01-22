import {
  useImperativeHandle,
  useEffect,
  type CSSProperties,
  type RefObject,
} from 'react';
import { useEditor, EditorContent } from '@tiptap/react';
import { Placeholder } from '@tiptap/extensions';
import Document from '@tiptap/extension-document';
import HardBreak from '@tiptap/extension-hard-break';
import Text from '@tiptap/extension-text';
import Paragraph from '@tiptap/extension-paragraph';
import Heading from '@tiptap/extension-heading';
import Bold from '@tiptap/extension-bold';
import Italic from '@tiptap/extension-italic';
import Strike from '@tiptap/extension-strike';
import Underline from '@tiptap/extension-underline';
import Blockquote from '@tiptap/extension-blockquote';

import './EnrichedTextInput.css';

import type {
  EnrichedTextInputInstanceBase,
  OnChangeHtmlEvent,
  OnChangeMentionEvent,
  OnChangeStateDeprecatedEvent,
  OnChangeStateEvent,
  OnChangeTextEvent,
  OnLinkDetected,
  OnMentionDetected,
  OnChangeSelectionEvent,
  OnKeyPressEvent,
} from '../common/types';
import { ENRICHED_TEXT_INPUT_DEFAULTS } from '../common/defaultProps';
import { useOnChangeState } from './hooks/useOnChangeState';
import { useOnChangeHtml } from './hooks/useOnChangeHtml';

export type EnrichedTextInputInstance = EnrichedTextInputInstanceBase;

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
  placeholderTextColor,
  selectionColor,
  cursorColor,
  style,
  onFocus,
  onBlur,
  onChangeSelection,
  onKeyPress,
  onChangeState,
  onChangeHtml,
}: EnrichedTextInputProps) => {
  const editor = useEditor({
    extensions: [
      Document,
      HardBreak,
      Text,
      Paragraph,
      Heading.extend({
        marks: '',
        addCommands() {
          return {
            ...this.parent?.(),
            toggleHeading:
              (attributes) =>
              ({ chain, editor: _editor }) => {
                const newChain = chain();
                // Remove blockquote if active
                if (_editor.isActive('blockquote')) {
                  newChain.lift('blockquote');
                }

                return newChain
                  .toggleNode(this.name, 'paragraph', attributes)
                  .run();
              },
          };
        },
      }),
      Bold.extend({
        renderHTML({ HTMLAttributes }) {
          return ['b', HTMLAttributes, 0];
        },
      }),
      Italic.extend({
        renderHTML({ HTMLAttributes }) {
          return ['i', HTMLAttributes, 0];
        },
      }),
      Strike,
      Underline,
      Placeholder.configure({
        placeholder: placeholder || '',
      }),
      Blockquote.extend({
        addCommands() {
          return {
            ...this.parent?.(),
            toggleBlockquote:
              () =>
              ({ chain, editor: _editor }) => {
                const newChain = chain();
                // If we are toggling blockquote ON, first disable any active heading
                if (!_editor.isActive('blockquote')) {
                  for (let level = 1; level <= 6; level++) {
                    if (_editor.isActive('heading', { level })) {
                      newChain.toggleNode('heading', 'paragraph', { level });
                      break;
                    }
                  }
                }
                return newChain.toggleWrap('blockquote').run();
              },
          };
        },
      }),
    ],
    content: defaultValue,
    editable: editable,
    autofocus: autoFocus,
    onFocus: onFocus,
    onBlur: onBlur,
    onSelectionUpdate: ({ editor: _editor }) => {
      if (onChangeSelection) {
        const { from, to } = _editor.state.selection;
        // TipTap's positions are 1-based, adjust to 0-based
        onChangeSelection({
          start: from - 1,
          end: to - 1,
          text: _editor.state.doc.textBetween(from, to),
        });
      }
    },
    editorProps: {
      attributes: {
        style: 'outline: none;',
      },
      handleKeyDown: (_, event) => {
        if (onKeyPress) {
          onKeyPress({
            key: event.key,
          });
        }
        // returning false allows the event to be processed further by TipTap
        return false;
      },
    },
  });

  useOnChangeState(editor, onChangeState);
  useOnChangeHtml(editor, onChangeHtml);

  useEffect(() => {
    if (editor && editable !== undefined) {
      editor.setEditable(editable);
    }
  }, [editable, editor]);

  useImperativeHandle(
    ref,
    () => ({
      // General commands
      focus: () => {
        editor?.commands.focus();
      },
      blur: () => {
        editor?.commands.blur();
      },
      setValue: (value: string) => {
        editor?.commands.setContent(value);
      },
      setSelection: (start: number, end: number) => {
        // Convert from 0-based (React Native) to 1-based (TipTap)
        editor
          ?.chain()
          .focus()
          .setTextSelection({ from: start + 1, to: end + 1 })
          .run();
      },
      getHTML: () => {
        return Promise.resolve(editor?.getHTML() || '');
      },

      // Text formatting commands
      toggleBold: () => {
        editor?.chain().focus().toggleBold().run();
      },
      toggleItalic: () => {
        editor?.chain().focus().toggleItalic().run();
      },
      toggleUnderline: () => {
        editor?.chain().focus().toggleUnderline().run();
      },
      toggleStrikeThrough: () => {
        editor?.chain().focus().toggleStrike().run();
      },
      toggleInlineCode: () => {},
      toggleH1: () => {
        editor?.chain().focus().toggleHeading({ level: 1 }).run();
      },
      toggleH2: () => {
        editor?.chain().focus().toggleHeading({ level: 2 }).run();
      },
      toggleH3: () => {
        editor?.chain().focus().toggleHeading({ level: 3 }).run();
      },
      toggleH4: () => {
        editor?.chain().focus().toggleHeading({ level: 4 }).run();
      },
      toggleH5: () => {
        editor?.chain().focus().toggleHeading({ level: 5 }).run();
      },
      toggleH6: () => {
        editor?.chain().focus().toggleHeading({ level: 6 }).run();
      },
      toggleCodeBlock: () => {},
      toggleBlockQuote: () => {
        editor?.chain().focus().toggleBlockquote().run();
      },
      toggleOrderedList: () => {},
      toggleUnorderedList: () => {},
      setLink: () => {},
      setImage: () => {},
      startMention: () => {},
      setMention: () => {},
    }),
    [editor]
  );

  return (
    <EditorContent
      editor={editor}
      style={
        {
          ...style,
          '--placeholder-color': placeholderTextColor,
          '--selection-color': selectionColor,
          '--cursor-color': cursorColor,
        } as CSSProperties
      }
    />
  );
};
