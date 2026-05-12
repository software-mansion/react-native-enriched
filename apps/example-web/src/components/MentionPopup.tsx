import type { FC } from 'react';
import './MentionPopup.css';

export interface MentionItem {
  id: string;
  name: string;
}

export type MentionData = MentionItem[];

interface MentionPopupProps {
  variant: 'user' | 'channel';
  data: MentionData;
  isOpen: boolean;
  onItemPress: (item: MentionItem) => void;
}

export const MentionPopup: FC<MentionPopupProps> = ({
  variant,
  data,
  isOpen,
  onItemPress,
}) => {
  if (!isOpen || data.length === 0) {
    return null;
  }

  const badgeLabel = variant === 'user' ? '@' : '#';

  return (
    <div className="mention-popup">
      <ul className="mention-popup__list">
        {data.map((item) => (
          <li key={item.id} className="mention-popup__item">
            <button
              type="button"
              className="mention-popup__button"
              onMouseDown={(e) => {
                e.preventDefault();
              }}
              onClick={() => {
                onItemPress(item);
              }}
            >
              <span className="mention-popup__badge">{badgeLabel}</span>
              <span className="mention-popup__label">{item.name}</span>
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
};
