import { useEffect, useRef } from 'react';
import { type Editor } from '@tiptap/react';
import type { OnChangeStateEvent } from '../../common/types';

export const useEnrichedTextInputState = (
  editor: Editor | null,
  onChangeState?: (e: OnChangeStateEvent) => void
) => {
  const lastStateRef = useRef('');
  useEffect(() => {
    if (!editor) return;

    const updateState = (): OnChangeStateEvent => {
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
          isBlocking: false,
        },
        strikeThrough: {
          isActive: editor.isActive('strike'),
          isConflicting: false,
          isBlocking: false,
        },
        inlineCode: {
          isActive: editor.isActive('code'),
          isConflicting: false,
          isBlocking: false,
        },

        // Nodes
        h1: {
          isActive: editor.isActive('heading', { level: 1 }),
          isConflicting: false,
          isBlocking: !editor
            .can()
            .chain()
            .focus()
            .toggleHeading({ level: 1 })
            .run(),
        },
        h2: {
          isActive: editor.isActive('heading', { level: 2 }),
          isConflicting: false,
          isBlocking: !editor
            .can()
            .chain()
            .focus()
            .toggleHeading({ level: 2 })
            .run(),
        },
        h3: {
          isActive: editor.isActive('heading', { level: 3 }),
          isConflicting: false,
          isBlocking: false,
        },
        h4: {
          isActive: editor.isActive('heading', { level: 4 }),
          isConflicting: false,
          isBlocking: false,
        },
        h5: {
          isActive: editor.isActive('heading', { level: 5 }),
          isConflicting: false,
          isBlocking: false,
        },
        h6: {
          isActive: editor.isActive('heading', { level: 6 }),
          isConflicting: false,
          isBlocking: false,
        },
        blockQuote: {
          isActive: editor.isActive('blockquote'),
          isConflicting: false,
          isBlocking: false,
        },
        codeBlock: {
          isActive: editor.isActive('codeBlock'),
          isConflicting: false,
          isBlocking: false,
        },
        orderedList: {
          isActive: editor.isActive('orderedList'),
          isConflicting: false,
          isBlocking: false,
        },
        unorderedList: {
          isActive: editor.isActive('bulletList'),
          isConflicting: false,
          isBlocking: false,
        },
        link: {
          isActive: editor.isActive('link'),
          isConflicting: false,
          isBlocking: false,
        },
        image: {
          isActive: editor.isActive('image'),
          isConflicting: false,
          isBlocking: false,
        },
        mention: {
          isActive: false,
          isConflicting: false,
          isBlocking: false,
        },
      };

      // Simple stringify check to see if the UI-relevant state actually changed
      const currentStateString = JSON.stringify(state);
      if (currentStateString !== lastStateRef.current) {
        lastStateRef.current = currentStateString;
        onChangeState?.(state);
      }

      return state;
    };

    // Listen to every editor update
    editor.on('transaction', updateState);

    // Initial check
    updateState();

    return () => {
      editor.off('transaction', updateState);
    };
  }, [editor, onChangeState]);
};
