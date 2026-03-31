import { useState } from 'react';
import './SetValueModal.css';

interface SetValueModalProps {
  onSetValue: (value: string) => void;
  onClose: () => void;
}

export function SetValueModal({ onSetValue, onClose }: SetValueModalProps) {
  const [value, setValue] = useState('');

  const handleSubmit = () => {
    onSetValue(value);
    onClose();
  };

  const handleBackdropClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget) {
      onClose();
    }
  };

  return (
    <div
      className="modal-backdrop"
      data-testid="set-value-modal-backdrop"
      onClick={handleBackdropClick}
    >
      <div className="modal-card" data-testid="set-value-modal">
        <div className="modal-header">
          <button
            className="modal-close"
            data-testid="set-value-modal-close"
            onClick={onClose}
            aria-label="Close"
          >
            ✕
          </button>
        </div>
        <div className="modal-content">
          <textarea
            className="modal-input"
            data-testid="set-value-modal-input"
            placeholder="New value"
            value={value}
            onChange={(e) => {
              setValue(e.target.value);
            }}
            autoCapitalize="none"
            autoCorrect="off"
            spellCheck={false}
          />
          <button
            className="btn modal-submit-btn"
            data-testid="set-value-modal-submit"
            onClick={handleSubmit}
          >
            Set Value
          </button>
        </div>
      </div>
    </div>
  );
}
