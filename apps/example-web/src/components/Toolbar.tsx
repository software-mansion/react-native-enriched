import './Toolbar.css';
import type { OnChangeStateEvent } from 'react-native-enriched';

interface ToolbarProps {
  onToggleBold: () => void;
  onToggleItalic: () => void;
  onToggleUnderline: () => void;
  onToggleStrikeThrough: () => void;
  onToggleInlineCode: () => void;
  state: OnChangeStateEvent | null;
}

interface ToolbarButtonProps {
  label: string;
  isActive: boolean;
  isDisabled: boolean;
  variant?: 'default' | 'italic' | 'underline' | 'strikethrough';
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
    <div
      role="button"
      tabIndex={isDisabled ? -1 : 0}
      aria-disabled={isDisabled}
      className={`toolbar-btn toolbar-btn--${variant} ${isActive ? 'toolbar-btn--active' : ''} ${isDisabled ? 'toolbar-btn--disabled' : ''}`}
      onPointerDown={(e) => {
        e.preventDefault();
        if (!isDisabled) {
          onPress();
        }
      }}
    >
      {label}
    </div>
  );
}

export function Toolbar({
  onToggleBold,
  onToggleItalic,
  onToggleUnderline,
  onToggleStrikeThrough,
  onToggleInlineCode,
  state,
}: ToolbarProps) {
  const s = state;
  return (
    <div className="toolbar">
      <div className="toolbar-controls">
        <ToolbarButton
          label="B"
          isActive={s?.bold.isActive ?? false}
          isDisabled={s?.bold.isBlocking ?? false}
          onPress={onToggleBold}
        />
        <ToolbarButton
          label="I"
          isActive={s?.italic.isActive ?? false}
          isDisabled={s?.italic.isBlocking ?? false}
          variant="italic"
          onPress={onToggleItalic}
        />
        <ToolbarButton
          label="U"
          isActive={s?.underline.isActive ?? false}
          isDisabled={s?.underline.isBlocking ?? false}
          variant="underline"
          onPress={onToggleUnderline}
        />
        <ToolbarButton
          label="S"
          isActive={s?.strikeThrough.isActive ?? false}
          isDisabled={s?.strikeThrough.isBlocking ?? false}
          variant="strikethrough"
          onPress={onToggleStrikeThrough}
        />
        <ToolbarButton
          label="</>"
          isActive={s?.inlineCode.isActive ?? false}
          isDisabled={s?.inlineCode.isBlocking ?? false}
          onPress={onToggleInlineCode}
        />
      </div>
      <div className="toolbar-fill" aria-hidden="true" />
    </div>
  );
}
