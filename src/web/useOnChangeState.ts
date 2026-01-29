import { useEffect, useRef } from 'react';
import { type Editor } from '@tiptap/react';
import type { OnChangeStateEvent } from '../common/types';

export const useOnChangeState = (
  editor: Editor | null,
  onChangeState?: (e: OnChangeStateEvent) => void
) => {
  const lastStateRef = useRef('');
  useEffect(() => {
    if (!editor) return;

    const updateState = (): OnChangeStateEvent => {
      const isAnyHeadingActive = () =>
        [1, 2, 3, 4, 5, 6].some((level) =>
          editor.isActive('heading', { level })
        );

      const state: OnChangeStateEvent = {
        // Marks
        bold: {
          isActive: editor.isActive('bold'),
          isConflicting: false,
          isBlocking: !editor.can().chain().focus().toggleBold().run(),
        },
        italic: {
          isActive: editor.isActive('italic'),
          isConflicting: false,
          isBlocking: !editor.can().chain().focus().toggleItalic().run(),
        },
        underline: {
          isActive: editor.isActive('underline'),
          isConflicting: false,
          isBlocking: !editor.can().chain().focus().toggleUnderline().run(),
        },
        strikeThrough: {
          isActive: editor.isActive('strike'),
          isConflicting: false,
          isBlocking: !editor.can().chain().focus().toggleStrike().run(),
        },
        inlineCode: {
          isActive: editor.isActive('code'),
          isConflicting: false,
          isBlocking: !editor.can().chain().focus().toggleCode().run(),
        },

        // Nodes
        h1: {
          isActive: editor.isActive('heading', { level: 1 }),
          isConflicting:
            (isAnyHeadingActive() || editor.isActive('blockquote')) &&
            !editor.isActive('heading', { level: 1 }),
          isBlocking: false,
        },
        h2: {
          isActive: editor.isActive('heading', { level: 2 }),
          isConflicting:
            (isAnyHeadingActive() || editor.isActive('blockquote')) &&
            !editor.isActive('heading', { level: 2 }),
          isBlocking: false,
        },
        h3: {
          isActive: editor.isActive('heading', { level: 3 }),
          isConflicting:
            (isAnyHeadingActive() || editor.isActive('blockquote')) &&
            !editor.isActive('heading', { level: 3 }),
          isBlocking: false,
        },
        h4: {
          isActive: editor.isActive('heading', { level: 4 }),
          isConflicting:
            (isAnyHeadingActive() || editor.isActive('blockquote')) &&
            !editor.isActive('heading', { level: 4 }),
          isBlocking: false,
        },
        h5: {
          isActive: editor.isActive('heading', { level: 5 }),
          isConflicting:
            (isAnyHeadingActive() || editor.isActive('blockquote')) &&
            !editor.isActive('heading', { level: 5 }),
          isBlocking: false,
        },
        h6: {
          isActive: editor.isActive('heading', { level: 6 }),
          isConflicting:
            (isAnyHeadingActive() || editor.isActive('blockquote')) &&
            !editor.isActive('heading', { level: 6 }),
          isBlocking: false,
        },
        blockQuote: {
          isActive: editor.isActive('blockquote'),
          isConflicting: isAnyHeadingActive(),
          isBlocking: false,
        },
        codeBlock: {
          isActive: editor.isActive('codeBlock'),
          isConflicting: false,
          isBlocking: false,
        },
        orderedList: {
          isActive: editor.isActive('orderedList'),
          isConflicting: editor.isActive('bulletList'),
          isBlocking: false,
        },
        unorderedList: {
          isActive: editor.isActive('bulletList'),
          isConflicting: editor.isActive('orderedList'),
          isBlocking: false,
        },
        link: {
          isActive: false,
          isConflicting: false,
          isBlocking: false,
        },
        image: {
          isActive: false,
          isConflicting: false,
          isBlocking: false,
        },
        mention: {
          isActive: false,
          isConflicting: false,
          isBlocking: false,
        },
      };

      const currentStateString = JSON.stringify(state);
      if (currentStateString !== lastStateRef.current) {
        lastStateRef.current = currentStateString;
        onChangeState?.(state);
      }

      return state;
    };

    // Initial check
    updateState();

    editor.on('transaction', updateState);

    return () => {
      editor.off('transaction', updateState);
    };
  }, [editor, onChangeState]);
};
