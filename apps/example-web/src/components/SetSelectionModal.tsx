import { useState } from 'react';
import { BaseModal } from './BaseModal';
import './SetValueModal.css';

interface SetSelectionModalProps {
  initialStart: number;
  initialEnd: number;
  onSetSelection: (start: number, end: number) => void;
  onClose: () => void;
}

export function SetSelectionModal({
  initialStart,
  initialEnd,
  onSetSelection,
  onClose,
}: SetSelectionModalProps) {
  const [start, setStart] = useState(String(initialStart));
  const [end, setEnd] = useState(String(initialEnd));

  const parsedStart = Number.parseInt(start, 10);
  const parsedEnd = Number.parseInt(end, 10);
  const isValid =
    Number.isFinite(parsedStart) &&
    Number.isFinite(parsedEnd) &&
    parsedStart >= 0 &&
    parsedEnd >= parsedStart;

  const handleSubmit = () => {
    if (!isValid) {
      return;
    }
    onSetSelection(parsedStart, parsedEnd);
    onClose();
  };

  return (
    <BaseModal testIdPrefix="set-selection-modal" onClose={onClose}>
      <input
        type="number"
        className="modal-number-input"
        data-testid="set-selection-modal-start-input"
        placeholder="Selection start"
        value={start}
        min={0}
        onChange={(e) => {
          setStart(e.target.value);
        }}
      />
      <input
        type="number"
        className="modal-number-input"
        data-testid="set-selection-modal-end-input"
        placeholder="Selection end"
        value={end}
        min={0}
        onChange={(e) => {
          setEnd(e.target.value);
        }}
      />
      <button
        className="btn modal-submit-btn"
        data-testid="set-selection-modal-submit"
        onClick={handleSubmit}
        disabled={!isValid}
      >
        Set Selection
      </button>
    </BaseModal>
  );
}
