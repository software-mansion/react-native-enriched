import { useRef, useState, type ChangeEvent } from 'react';
import {
  EnrichedTextInput,
  type EnrichedInputStyle,
  type EnrichedTextInputInstance,
  type HtmlStyle,
  type OnChangeStateEvent,
} from 'react-native-enriched';
import { Toolbar } from '../components/Toolbar';

export function VisualRegressionScreen() {
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
    <div style={{ padding: '16px' }}>
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

      <div style={{ marginTop: '12px' }}>
        <textarea
          data-testid="visual-regression-html-input"
          value={htmlInput}
          onChange={(e: ChangeEvent<HTMLTextAreaElement>) => {
            setHtmlInput(e.target.value);
          }}
          placeholder="Paste HTML here..."
          rows={4}
          style={{ width: '100%' }}
        />
        <div style={{ display: 'flex', gap: '8px' }}>
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
