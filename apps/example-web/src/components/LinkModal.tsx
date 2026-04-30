import { useEffect, useState } from 'react';
import { BaseModal } from './BaseModal';
import './LinkModal.css';

interface LinkModalProps {
  editedText: string;
  editedUrl: string;
  onClose: () => void;
  onSubmit: (text: string, url: string) => void;
}

export function LinkModal({
  editedText,
  editedUrl,
  onClose,
  onSubmit,
}: LinkModalProps) {
  const [text, setText] = useState(editedText);
  const [url, setUrl] = useState(editedUrl);

  useEffect(() => {
    setText(editedText);
    setUrl(editedUrl);
  }, [editedText, editedUrl]);

  const handleSave = () => {
    onSubmit(text, url);
  };

  return (
    <BaseModal testIdPrefix="link-modal" onClose={onClose}>
      <input
        type="text"
        className="modal-input modal-input--single"
        data-testid="link-modal-text-input"
        placeholder="Text"
        value={text}
        onChange={(e) => {
          setText(e.target.value);
        }}
        autoCapitalize="none"
        autoCorrect="off"
        spellCheck={false}
      />
      <input
        type="text"
        className="modal-input modal-input--single"
        data-testid="link-modal-url-input"
        placeholder="Link"
        value={url}
        onChange={(e) => {
          setUrl(e.target.value);
        }}
        autoCapitalize="none"
        autoCorrect="off"
        spellCheck={false}
      />
      <button
        className="btn modal-submit-btn"
        type="button"
        data-testid="link-modal-submit-button"
        disabled={url.length === 0}
        onClick={handleSave}
      >
        Save
      </button>
    </BaseModal>
  );
}
