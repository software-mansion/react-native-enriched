import { useMemo, useRef, useState, type ChangeEvent } from 'react';
import {
  EnrichedTextInput,
  type EnrichedInputStyle,
  type EnrichedTextInputInstance,
  type HtmlStyle,
  type OnChangeStateEvent,
} from 'react-native-enriched';
import { Toolbar } from '../components/Toolbar';
import { defaultHtmlStyle } from '../defaultHtmlStyle';

function mergeHtmlStyle(
  base: HtmlStyle,
  override: Partial<HtmlStyle>
): HtmlStyle {
  const isPlainObject = (val: unknown): val is Record<string, unknown> =>
    typeof val === 'object' && val !== null && !Array.isArray(val);

  const result = { ...base } as Record<string, unknown>;

  for (const [key, val] of Object.entries(override)) {
    const prev = result[key];
    result[key] =
      isPlainObject(prev) && isPlainObject(val) ? { ...prev, ...val } : val;
  }

  return result as HtmlStyle;
}

export function VisualRegression() {
  const ref = useRef<EnrichedTextInputInstance>(null);
  const [htmlInput, setHtmlInput] = useState('');
  const [editorState, setEditorState] = useState<OnChangeStateEvent | null>(
    null
  );
  const [editorHtml, setEditorHtml] = useState('');
  const [htmlStyleOverrideJson, setHtmlStyleOverrideJson] = useState('');

  const htmlStyle = useMemo<HtmlStyle>(() => {
    const raw = htmlStyleOverrideJson.trim();
    if (!raw) {
      return defaultHtmlStyle;
    }
    try {
      const parsed = JSON.parse(raw) as Partial<HtmlStyle>;
      return mergeHtmlStyle(defaultHtmlStyle, parsed);
    } catch {
      return defaultHtmlStyle;
    }
  }, [htmlStyleOverrideJson]);

  const handleSetValue = () => {
    ref.current?.setValue(htmlInput);
  };

  const handleClear = () => {
    ref.current?.setValue('');
    setHtmlInput('');
    setEditorHtml('');
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
          onChangeHtml={(e) => {
            setEditorHtml(e.nativeEvent.value);
          }}
          onChangeState={(e) => {
            setEditorState(e.nativeEvent);
          }}
        />
      </div>

      <Toolbar editorRef={ref} state={editorState} />

      <div style={styles.controlsContainer}>
        <label
          style={styles.fieldLabel}
          htmlFor="visual-regression-html-style-override"
        >
          htmlStyle override (JSON merged into defaults)
        </label>
        <textarea
          id="visual-regression-html-style-override"
          data-testid="visual-regression-html-style-override"
          value={htmlStyleOverrideJson}
          onChange={(e: ChangeEvent<HTMLTextAreaElement>) => {
            setHtmlStyleOverrideJson(e.target.value);
          }}
          placeholder={'e.g. { "h1": { "bold": false } }'}
          rows={3}
          style={styles.htmlStyleOverrideInput}
        />
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
        <pre
          data-testid="visual-regression-editor-html-output"
          style={styles.editorHtmlOutput}
        >
          {editorHtml}
        </pre>
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
  fieldLabel: {
    display: 'block',
    marginBottom: '4px',
    fontSize: 14,
  },
  htmlStyleOverrideInput: {
    width: '100%',
    marginBottom: '10px',
    fontFamily: 'ui-monospace, monospace',
    fontSize: 12,
  },
  htmlInput: {
    width: '100%',
  },
  actionButtons: {
    display: 'flex',
    gap: '8px',
  },
  editorHtmlOutput: {
    marginTop: 8,
    whiteSpace: 'pre-wrap',
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
