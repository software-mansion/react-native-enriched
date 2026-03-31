import { useRef, useState, type ChangeEvent } from 'react';
import {
  EnrichedTextInput,
  type EnrichedTextInputInstance,
  type OnChangeSelectionEvent,
} from 'react-native-enriched';

const SAMPLE_HTML = '<p>AAAA</p><br><br><p>BBBB</p><p>CCCC</p>';

function toInteger(value: string): number {
  const parsed = parseInt(value, 10);
  return isNaN(parsed) ? 0 : parsed;
}

export function TestSetSelection() {
  const ref = useRef<EnrichedTextInputInstance>(null);
  const [startInput, setStartInput] = useState('0');
  const [endInput, setEndInput] = useState('0');
  const [lastSelection, setLastSelection] =
    useState<OnChangeSelectionEvent | null>(null);

  const selectedTextJson = JSON.stringify(lastSelection?.text ?? '');

  const handleStartChange = (e: ChangeEvent<HTMLInputElement>) => {
    setStartInput(e.target.value);
  };

  const handleEndChange = (e: ChangeEvent<HTMLInputElement>) => {
    setEndInput(e.target.value);
  };

  const applySelection = () => {
    ref.current?.setSelection(toInteger(startInput), toInteger(endInput));
  };

  const editorContainerStyle = {
    backgroundColor: '#ddd',
    padding: '16px',
    borderRadius: '8px',
  } as const;

  return (
    <div>
      <div
        className="editor-wrapper"
        style={editorContainerStyle}
        data-testid="editor-container"
        onClick={() => ref.current?.focus()}
      >
        <div className="editor-content">
          <EnrichedTextInput
            ref={ref}
            defaultValue={SAMPLE_HTML}
            placeholder="Test editor"
            autoFocus
            editable
            scrollEnabled
            onChangeSelection={(e) => {
              setLastSelection({
                start: e.nativeEvent.start,
                end: e.nativeEvent.end,
                text: e.nativeEvent.text,
              });
            }}
          />
        </div>
      </div>

      <div>
        <label htmlFor="selection-start-input">Start</label>
        <input
          id="selection-start-input"
          data-testid="selection-start-input"
          type="number"
          value={startInput}
          onChange={handleStartChange}
        />

        <label htmlFor="selection-end-input">End</label>
        <input
          id="selection-end-input"
          data-testid="selection-end-input"
          type="number"
          value={endInput}
          onChange={handleEndChange}
        />

        <button data-testid="apply-selection-button" onClick={applySelection}>
          Apply selection
        </button>
      </div>

      <div data-testid="selection-result">
        <div>
          Start:{' '}
          <span data-testid="result-start">
            {lastSelection?.start ?? 'N/A'}
          </span>
        </div>
        <div>
          End:{' '}
          <span data-testid="result-end">{lastSelection?.end ?? 'N/A'}</span>
        </div>
        <div>
          <label htmlFor="selected-text-json">Selected text JSON</label>
        </div>
        <input
          id="selected-text-json"
          data-testid="selected-text-json"
          readOnly
          value={selectedTextJson}
        />
      </div>
    </div>
  );
}
