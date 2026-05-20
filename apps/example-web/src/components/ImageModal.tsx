import { useState } from 'react';
import { BaseModal } from './BaseModal';
import './LinkModal.css';

interface ImageModalProps {
  onClose: () => void;
  onSubmit: (url: string, width: number, height: number) => void;
}

const DEFAULT_WIDTH = 80;
const DEFAULT_HEIGHT = 80;

export function ImageModal({ onClose, onSubmit }: ImageModalProps) {
  const [width, setWidth] = useState('');
  const [height, setHeight] = useState('');
  const [url, setUrl] = useState('');

  const reset = () => {
    setWidth('');
    setHeight('');
    setUrl('');
  };

  const handleClose = () => {
    reset();
    onClose();
  };

  const handleSave = () => {
    const trimmedUrl = url.trim();
    if (trimmedUrl.length === 0) {
      return;
    }
    const parsedW = parseFloat(width);
    const parsedH = parseFloat(height);
    const w = Number.isNaN(parsedW) ? DEFAULT_WIDTH : parsedW;
    const h = Number.isNaN(parsedH) ? DEFAULT_HEIGHT : parsedH;
    onSubmit(trimmedUrl, w, h);
    reset();
    onClose();
  };

  return (
    <BaseModal testIdPrefix="image-modal" onClose={handleClose}>
      <input
        type="text"
        className="modal-input modal-input--single"
        data-testid="image-modal-url-input"
        placeholder="Image URL"
        value={url}
        onChange={(e) => {
          setUrl(e.target.value);
        }}
        autoCapitalize="none"
        autoCorrect="off"
        spellCheck={false}
      />
      <input
        type="text"
        className="modal-input modal-input--single"
        data-testid="image-modal-width-input"
        placeholder={`Width (default ${String(DEFAULT_WIDTH)})`}
        value={width}
        onChange={(e) => {
          setWidth(e.target.value);
        }}
        inputMode="decimal"
      />
      <input
        type="text"
        className="modal-input modal-input--single"
        data-testid="image-modal-height-input"
        placeholder={`Height (default ${String(DEFAULT_HEIGHT)})`}
        value={height}
        onChange={(e) => {
          setHeight(e.target.value);
        }}
        inputMode="decimal"
      />
      <button
        className="btn modal-submit-btn"
        type="button"
        data-testid="image-modal-submit-button"
        disabled={url.trim().length === 0}
        onClick={handleSave}
      >
        Insert image
      </button>
    </BaseModal>
  );
}
