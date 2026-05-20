import type { MouseEvent, ReactNode } from 'react';
import './BaseModal.css';

interface BaseModalProps {
  testIdPrefix: string;
  onClose: () => void;
  children: ReactNode;
}

export function BaseModal({ testIdPrefix, onClose, children }: BaseModalProps) {
  const handleBackdropClick = (e: MouseEvent<HTMLDivElement>) => {
    if (e.target === e.currentTarget) {
      onClose();
    }
  };

  return (
    <div
      className="modal-backdrop"
      data-testid={`${testIdPrefix}-backdrop`}
      onClick={handleBackdropClick}
    >
      <div className="modal-card" data-testid={testIdPrefix}>
        <div className="modal-header">
          <button
            className="modal-close"
            data-testid={`${testIdPrefix}-close`}
            onClick={onClose}
            aria-label="Close"
          >
            ✕
          </button>
        </div>
        <div className="modal-content">{children}</div>
      </div>
    </div>
  );
}
