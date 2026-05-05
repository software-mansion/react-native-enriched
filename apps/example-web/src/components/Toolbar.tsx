import './Toolbar.css';
import type {
  EnrichedTextInputInstance,
  OnChangeStateEvent,
} from 'react-native-enriched';
import type { RefObject } from 'react';
import { useDragScroll } from '../hooks/useDragScroll';

interface ToolbarProps {
  editorRef: RefObject<EnrichedTextInputInstance | null>;
  state: OnChangeStateEvent | null;
  onOpenLinkModal: () => void;
}

interface ToolbarButtonProps {
  label: string;
  testId: string;
  isActive: boolean;
  isDisabled: boolean;
  variant?: string;
  onPress: () => void;
}

function ToolbarButton({
  label,
  testId,
  isActive,
  isDisabled,
  variant = 'default',
  onPress,
}: ToolbarButtonProps) {
  return (
    <button
      type="button"
      data-testid={testId}
      disabled={isDisabled}
      className={`toolbar-btn toolbar-btn--${variant} ${isActive ? 'toolbar-btn--active' : ''} ${isDisabled ? 'toolbar-btn--disabled' : ''}`}
      onPointerDown={(e) => {
        // Mouse only: keep focus in the editor. Skip touch so the strip can scroll.
        if (e.pointerType === 'mouse') {
          e.preventDefault();
        }
      }}
      onClick={() => {
        if (!isDisabled) {
          onPress();
        }
      }}
    >
      {label}
    </button>
  );
}

export function Toolbar({ editorRef, state, onOpenLinkModal }: ToolbarProps) {
  const s = state;
  const dragScroll = useDragScroll();

  const toolbarItems = [
    {
      key: 'bold',
      label: 'B',
      onPress: (editor) => {
        editor?.toggleBold();
      },
    },
    {
      key: 'italic',
      label: 'I',
      variant: 'italic',
      onPress: (editor) => {
        editor?.toggleItalic();
      },
    },
    {
      key: 'underline',
      label: 'U',
      variant: 'underline',
      onPress: (editor) => {
        editor?.toggleUnderline();
      },
    },
    {
      key: 'strikeThrough',
      label: 'S',
      variant: 'strikethrough',
      onPress: (editor) => {
        editor?.toggleStrikeThrough();
      },
    },
    {
      key: 'inlineCode',
      label: '</>',
      onPress: (editor) => {
        editor?.toggleInlineCode();
      },
    },
    {
      key: 'h1',
      label: 'H1',
      onPress: (editor) => {
        editor?.toggleH1();
      },
    },
    {
      key: 'h2',
      label: 'H2',
      onPress: (editor) => {
        editor?.toggleH2();
      },
    },
    {
      key: 'h3',
      label: 'H3',
      onPress: (editor) => {
        editor?.toggleH3();
      },
    },
    {
      key: 'h4',
      label: 'H4',
      onPress: (editor) => {
        editor?.toggleH4();
      },
    },
    {
      key: 'h5',
      label: 'H5',
      onPress: (editor) => {
        editor?.toggleH5();
      },
    },
    {
      key: 'h6',
      label: 'H6',
      onPress: (editor) => {
        editor?.toggleH6();
      },
    },
    {
      key: 'blockQuote',
      label: '❝',
      onPress: (editor) => {
        editor?.toggleBlockQuote();
      },
    },
    {
      key: 'codeBlock',
      label: '{ }',
      onPress: (editor) => {
        editor?.toggleCodeBlock();
      },
    },
    {
      key: 'link',
      label: '🔗',
      onPress: onOpenLinkModal,
    },
    {
      key: 'mention',
      label: '@',
      onPress: (editor) => {
        editor?.startMention('@');
      },
    },
    {
      key: 'unorderedList',
      label: '•',
      onPress: (editor) => {
        editor?.toggleUnorderedList();
      },
    },
    {
      key: 'orderedList',
      label: '1.',
      onPress: (editor) => {
        editor?.toggleOrderedList();
      },
    },
    {
      key: 'checkboxList',
      label: '☑',
      onPress: (editor) => {
        editor?.toggleCheckboxList(true);
      },
    },
  ] satisfies {
    key: keyof OnChangeStateEvent;
    label: string;
    variant?: string;
    onPress: (editor: EnrichedTextInputInstance | null) => void;
  }[];

  return (
    <div className="toolbar">
      <div className="toolbar-controls" {...dragScroll}>
        {toolbarItems.map((item) => (
          <ToolbarButton
            key={item.key}
            label={item.label}
            testId={`toolbar-button-${item.key}`}
            isActive={s?.[item.key].isActive ?? false}
            isDisabled={s?.[item.key].isBlocking ?? false}
            variant={item.variant}
            onPress={() => {
              item.onPress(editorRef.current);
            }}
          />
        ))}
      </div>
      <div className="toolbar-fill" aria-hidden="true" />
    </div>
  );
}
