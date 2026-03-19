import { useState } from 'react';
import './SetHtmlValueControl.css';

interface SetHtmlValueControlProps {
  onSetValue: (value: string) => void;
}

export function SetHtmlValueControl({ onSetValue }: SetHtmlValueControlProps) {
  const [value, setValue] = useState('');

  return (
    <div className="set-value-row">
      <input
        className="set-value-input"
        type="text"
        placeholder="HTML value…"
        value={value}
        onChange={(e) => {
          setValue(e.target.value);
        }}
      />
      <button
        className="set-value-btn"
        onClick={() => {
          onSetValue(value);
        }}
      >
        Set Value
      </button>
    </div>
  );
}
