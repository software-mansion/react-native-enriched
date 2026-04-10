import { useState } from 'react';
import { BaseModal } from './BaseModal';
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

  return (
    <BaseModal testIdPrefix="set-value-modal" onClose={onClose}>
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
    </BaseModal>
  );
}
