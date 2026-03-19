interface EditorActionsProps {
  showHtmlOutput: boolean;
  onFocus: () => void;
  onBlur: () => void;
  onClear: () => void;
  onToggleHtml: () => void;
}

export function EditorActions({
  showHtmlOutput,
  onFocus,
  onBlur,
  onClear,
  onToggleHtml,
}: EditorActionsProps) {
  return (
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
      <button className="btn" onClick={onToggleHtml}>
        {showHtmlOutput ? 'Hide' : 'Show'} HTML
      </button>
    </div>
  );
}
