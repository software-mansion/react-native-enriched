import { useRef, useState, type ChangeEvent } from 'react';
import {
  EnrichedTextInput,
  type EnrichedInputStyle,
  type EnrichedTextInputInstance,
  type HtmlStyle,
  type OnChangeStateEvent,
} from 'react-native-enriched';
import { Toolbar } from '../components/Toolbar';

export function VisualRegression() {
  const ref = useRef<EnrichedTextInputInstance>(null);
  const [htmlInput, setHtmlInput] = useState('');
  const [editorState, setEditorState] = useState<OnChangeStateEvent | null>(
    null
  );

  const handleSetValue = () => {
    ref.current?.setValue(htmlInput);
  };

  const handleClear = () => {
    ref.current?.setValue('');
    setHtmlInput('');
  };

  return (
    <div style={styles.container}>
      <div
        data-testid="visual-regression-editor"
        onClick={() => ref.current?.focus()}
      >
        <EnrichedTextInput
          ref={ref}
          editable
          scrollEnabled
          style={enrichedInputStyle}
          htmlStyle={htmlStyle}
          onChangeState={(e) => {
            setEditorState(e.nativeEvent);
          }}
        />
      </div>

      <Toolbar editorRef={ref} state={editorState} />

      <div style={styles.controlsContainer}>
        <textarea
          data-testid="visual-regression-html-input"
          value={htmlInput}
          onChange={(e: ChangeEvent<HTMLTextAreaElement>) => {
            setHtmlInput(e.target.value);
          }}
          placeholder="Paste HTML here..."
          rows={4}
          style={styles.htmlInput}
        />
        <div style={styles.actionButtons}>
          <button
            data-testid="visual-regression-set-value-button"
            onClick={handleSetValue}
          >
            Set Value
          </button>
          <button
            data-testid="visual-regression-clear-button"
            onClick={handleClear}
          >
            Clear
          </button>
        </div>
      </div>
    </div>
  );
}

const styles = {
  container: {
    padding: '16px',
  },
  controlsContainer: {
    marginTop: '12px',
  },
  htmlInput: {
    width: '100%',
  },
  actionButtons: {
    display: 'flex',
    gap: '8px',
  },
} as const;

const enrichedInputStyle: EnrichedInputStyle = {
  width: '100%',
  minHeight: 150,
  maxWidth: 350,
  paddingVertical: 10,
  paddingHorizontal: 12,
  backgroundColor: 'gainsboro',
  fontSize: 16,
  lineHeight: 22,
  fontFamily: 'Helvetica Neue',
};

const htmlStyle: HtmlStyle = {
  code: {
    color: 'purple',
    backgroundColor: 'yellow',
  },
};
