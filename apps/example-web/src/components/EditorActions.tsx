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
    <div className="actions-container">
      <div className="btn-row">
        <button className="btn" onClick={onFocus}>
          Focus
        </button>
        <button className="btn" onClick={onBlur}>
          Blur
        </button>
        <button className="btn" onClick={onClear}>
          Clear
        </button>
      </div>
      <button className="btn btn-full" onClick={onOpenSetValue}>
        Set input's value
      </button>
      <button className="btn btn-full" onClick={onToggleHtml}>
        {showHtmlOutput ? 'Hide' : 'Show'} HTML
      </button>
    </div>
  );
}
