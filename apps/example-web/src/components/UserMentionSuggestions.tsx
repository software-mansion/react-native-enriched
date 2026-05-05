import './UserMentionSuggestions.css';
import type { EnrichedTextInputInstance } from 'react-native-enriched';
import type { RefObject } from 'react';
import type { MockUserMention } from '../constants/mockUserMentions';

interface UserMentionSuggestionsProps {
  editorRef: RefObject<EnrichedTextInputInstance | null>;
  items: MockUserMention[];
  visible: boolean;
  onPicked: () => void;
}

export function UserMentionSuggestions({
  editorRef,
  items,
  visible,
  onPicked,
}: UserMentionSuggestionsProps) {
  if (!visible || items.length === 0) {
    return null;
  }

  return (
    <div
      className="user-mention-suggestions"
      role="listbox"
      aria-label="User mentions"
    >
      <ul className="user-mention-suggestions__list">
        {items.map((item) => (
          <li key={item.id} className="user-mention-suggestions__item">
            <button
              type="button"
              className="user-mention-suggestions__button"
              role="option"
              onMouseDown={(e) => {
                e.preventDefault();
              }}
              onClick={() => {
                editorRef.current?.setMention('@', `@${item.name}`, {
                  id: item.id,
                  type: 'user',
                });
                onPicked();
              }}
            >
              <span className="user-mention-suggestions__avatar" aria-hidden>
                @
              </span>
              <span className="user-mention-suggestions__label">
                {item.name}
              </span>
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}
