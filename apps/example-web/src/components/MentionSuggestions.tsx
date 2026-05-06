import './MentionSuggestions.css';
import type { EnrichedTextInputInstance } from 'react-native-enriched';
import type { RefObject } from 'react';

export interface MentionSuggestionsProps<T> {
  editorRef: RefObject<EnrichedTextInputInstance | null>;
  items: T[];
  visible: boolean;
  onPicked: () => void;
  indicator: string;
  getItemKey: (item: T) => string;
  getInsertText: (item: T) => string;
  getAttributes: (item: T) => Record<string, string>;
  getLabel: (item: T) => string;
}

export function MentionSuggestions<T>({
  editorRef,
  items,
  visible,
  onPicked,
  indicator,
  getItemKey,
  getInsertText,
  getAttributes,
  getLabel,
}: MentionSuggestionsProps<T>) {
  if (!visible || items.length === 0) {
    return null;
  }

  return (
    <div className="mention-suggestions">
      <ul className="mention-suggestions__list">
        {items.map((item) => (
          <li key={getItemKey(item)} className="mention-suggestions__item">
            <button
              type="button"
              className="mention-suggestions__button"
              onMouseDown={(e) => {
                e.preventDefault();
              }}
              onClick={() => {
                editorRef.current?.setMention(
                  indicator,
                  getInsertText(item),
                  getAttributes(item)
                );
                onPicked();
              }}
            >
              <span className="mention-suggestions__badge">{indicator}</span>
              <span className="mention-suggestions__label">
                {getLabel(item)}
              </span>
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}
