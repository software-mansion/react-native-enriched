import './Toolbar.css';
import type {
  EnrichedTextInputInstance,
  OnChangeStateEvent,
} from 'react-native-enriched';
import type { RefObject } from 'react';

interface ToolbarProps {
  editorRef: RefObject<EnrichedTextInputInstance | null>;
  state: OnChangeStateEvent | null;
}

interface ToolbarButtonProps {
  label: string;
  isActive: boolean;
  isDisabled: boolean;
  variant?: string;
  onPress: () => void;
}

function ToolbarButton({
  label,
  isActive,
  isDisabled,
  variant = 'default',
  onPress,
}: ToolbarButtonProps) {
  return (
    <button
      disabled={isDisabled}
      className={`toolbar-btn toolbar-btn--${variant} ${isActive ? 'toolbar-btn--active' : ''} ${isDisabled ? 'toolbar-btn--disabled' : ''}`}
      onPointerDown={(e) => {
        e.preventDefault();
        if (!isDisabled) {
          onPress();
        }
      }}
    >
      {label}
    </button>
  );
}

export function Toolbar({ editorRef, state }: ToolbarProps) {
  const s = state;

  const toolbarItems = [
    {
      key: 'bold',
      label: 'B',
      onPress: (editor: EnrichedTextInputInstance) => {
        editor.toggleBold();
      },
    },
    {
      key: 'italic',
      label: 'I',
      variant: 'italic',
      onPress: (editor: EnrichedTextInputInstance) => {
        editor.toggleItalic();
      },
    },
    {
      key: 'underline',
      label: 'U',
      variant: 'underline',
      onPress: (editor: EnrichedTextInputInstance) => {
        editor.toggleUnderline();
      },
    },
    {
      key: 'strikeThrough',
      label: 'S',
      variant: 'strikethrough',
      onPress: (editor: EnrichedTextInputInstance) => {
        editor.toggleStrikeThrough();
      },
    },
    {
      key: 'inlineCode',
      label: '</>',
      onPress: (editor: EnrichedTextInputInstance) => {
        editor.toggleInlineCode();
      },
    },
  ] satisfies {
    key: keyof OnChangeStateEvent;
    label: string;
    variant?: string;
    onPress: (editor: EnrichedTextInputInstance) => void;
  }[];

  return (
    <div className="toolbar">
      <div className="toolbar-controls">
        {toolbarItems.map((item) => (
          <ToolbarButton
            key={item.key}
            label={item.label}
            isActive={s?.[item.key].isActive ?? false}
            isDisabled={s?.[item.key].isBlocking ?? false}
            variant={item.variant}
            onPress={() => {
              const editor = editorRef.current;
              if (editor) item.onPress(editor);
            }}
          />
        ))}
      </div>
      <div className="toolbar-fill" aria-hidden="true" />
    </div>
  );
}
