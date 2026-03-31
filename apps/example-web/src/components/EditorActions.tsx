import './EditorActions.css';

interface EditorActionsProps {
  showHtmlOutput: boolean;
  onFocus: () => void;
  onBlur: () => void;
  onClear: () => void;
  onToggleHtml: () => void;
  onOpenSetValue: () => void;
}

export function EditorActions({
  showHtmlOutput,
  onFocus,
  onBlur,
  onClear,
  onToggleHtml,
  onOpenSetValue,
}: EditorActionsProps) {
  return (
    <div className="actions-container" data-testid="editor-actions">
      <div className="btn-row" data-testid="editor-actions-row">
        <button className="btn" data-testid="focus-button" onClick={onFocus}>
          Focus
        </button>
        <button className="btn" data-testid="blur-button" onClick={onBlur}>
          Blur
        </button>
        <button className="btn" data-testid="clear-button" onClick={onClear}>
          Clear
        </button>
      </div>
      <button
        className="btn btn-full"
        data-testid="open-set-value-modal-button"
        onClick={onOpenSetValue}
      >
        Set input's value
      </button>
      <button
        className="btn btn-full"
        data-testid="toggle-html-button"
        onClick={onToggleHtml}
      >
        {showHtmlOutput ? 'Hide' : 'Show'} HTML
      </button>
    </div>
  );
}
