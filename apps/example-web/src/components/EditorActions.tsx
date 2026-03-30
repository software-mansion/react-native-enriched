import { useState } from 'react';
import './EditorActions.css';

interface EditorActionsProps {
  showHtmlOutput: boolean;
  onFocus: () => void;
  onBlur: () => void;
  onClear: () => void;
  onToggleHtml: () => void;
  onOpenSetValue: () => void;
  onSetSelection: (start: number, end: number) => void;
}

export function EditorActions({
  showHtmlOutput,
  onFocus,
  onBlur,
  onClear,
  onToggleHtml,
  onOpenSetValue,
  onSetSelection,
}: EditorActionsProps) {
  const [selStart, setSelStart] = useState('0');
  const [selEnd, setSelEnd] = useState('0');

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
      <div className="btn-row">
        <input
          className="sel-input"
          type="number"
          value={selStart}
          onChange={(e) => {
            setSelStart(e.target.value);
          }}
          placeholder="start"
        />
        <input
          className="sel-input"
          type="number"
          value={selEnd}
          onChange={(e) => {
            setSelEnd(e.target.value);
          }}
          placeholder="end"
        />
        <button
          className="btn"
          onClick={() => {
            onSetSelection(
              parseInt(selStart, 10) || 0,
              parseInt(selEnd, 10) || 0
            );
          }}
        >
          Set Selection
        </button>
      </div>
      <button className="btn btn-full" onClick={onToggleHtml}>
        {showHtmlOutput ? 'Hide' : 'Show'} HTML
      </button>
    </div>
  );
}
