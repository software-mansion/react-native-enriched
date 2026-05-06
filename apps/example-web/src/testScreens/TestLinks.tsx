import { useRef, useState, type ChangeEvent } from 'react';
import {
  EnrichedTextInput,
  type EnrichedInputStyle,
  type EnrichedTextInputInstance,
  type OnLinkDetected,
} from 'react-native-enriched';
import { WEB_DEFAULT_HTML_STYLE } from '../defaultHtmlStyle';

function toInteger(value: string): number {
  const parsed = parseInt(value, 10);
  return Number.isNaN(parsed) ? 0 : parsed;
}

export function TestLinks() {
  const ref = useRef<EnrichedTextInputInstance>(null);
  const [htmlInput, setHtmlInput] = useState('<html><p></p></html>');
  const [editorHtml, setEditorHtml] = useState('');
  const [startInput, setStartInput] = useState('6');
  const [endInput, setEndInput] = useState('11');
  const [linkTextInput, setLinkTextInput] = useState('world');
  const [linkUrlInput, setLinkUrlInput] = useState('https://example.com');
  const [removeStartInput, setRemoveStartInput] = useState('6');
  const [removeEndInput, setRemoveEndInput] = useState('11');
  const [selStartInput, setSelStartInput] = useState('0');
  const [selEndInput, setSelEndInput] = useState('0');
  const [lastOnLinkDetected, setLastOnLinkDetected] =
    useState<OnLinkDetected | null>(null);

  return (
    <div data-testid="test-links-root">
      <div data-testid="test-links-editor" onClick={() => ref.current?.focus()}>
        <EnrichedTextInput
          ref={ref}
          defaultValue="<html><p></p></html>"
          editable
          scrollEnabled
          style={editorStyle}
          htmlStyle={WEB_DEFAULT_HTML_STYLE}
          onChangeHtml={(e) => {
            setEditorHtml(e.nativeEvent.value);
          }}
          onLinkDetected={(e) => {
            setLastOnLinkDetected(e);
          }}
        />
      </div>

      <textarea
        data-testid="test-links-html-input"
        value={htmlInput}
        onChange={(e: ChangeEvent<HTMLTextAreaElement>) => {
          setHtmlInput(e.target.value);
        }}
        rows={4}
      />
      <button
        type="button"
        data-testid="test-links-set-value-button"
        onClick={() => ref.current?.setValue(htmlInput)}
      >
        Set value
      </button>

      <div>
        <input
          data-testid="test-links-setlink-start"
          type="number"
          value={startInput}
          onChange={(e) => {
            setStartInput(e.target.value);
          }}
        />
        <input
          data-testid="test-links-setlink-end"
          type="number"
          value={endInput}
          onChange={(e) => {
            setEndInput(e.target.value);
          }}
        />
        <input
          data-testid="test-links-setlink-text"
          value={linkTextInput}
          onChange={(e) => {
            setLinkTextInput(e.target.value);
          }}
        />
        <input
          data-testid="test-links-setlink-url"
          value={linkUrlInput}
          onChange={(e) => {
            setLinkUrlInput(e.target.value);
          }}
        />
        <button
          type="button"
          data-testid="test-links-apply-setlink-button"
          onClick={() =>
            ref.current?.setLink(
              toInteger(startInput),
              toInteger(endInput),
              linkTextInput,
              linkUrlInput
            )
          }
        >
          setLink
        </button>
      </div>

      <div>
        <input
          data-testid="test-links-removelink-start"
          type="number"
          value={removeStartInput}
          onChange={(e) => {
            setRemoveStartInput(e.target.value);
          }}
        />
        <input
          data-testid="test-links-removelink-end"
          type="number"
          value={removeEndInput}
          onChange={(e) => {
            setRemoveEndInput(e.target.value);
          }}
        />
        <button
          type="button"
          data-testid="test-links-apply-removelink-button"
          onClick={() =>
            ref.current?.removeLink(
              toInteger(removeStartInput),
              toInteger(removeEndInput)
            )
          }
        >
          removeLink
        </button>
      </div>

      <div>
        <input
          data-testid="test-links-selection-start"
          type="number"
          value={selStartInput}
          onChange={(e) => {
            setSelStartInput(e.target.value);
          }}
        />
        <input
          data-testid="test-links-selection-end"
          type="number"
          value={selEndInput}
          onChange={(e) => {
            setSelEndInput(e.target.value);
          }}
        />
        <button
          type="button"
          data-testid="test-links-apply-selection-button"
          onClick={() =>
            ref.current?.setSelection(
              toInteger(selStartInput),
              toInteger(selEndInput)
            )
          }
        >
          setSelection
        </button>
      </div>

      <pre data-testid="on-link-detected-payload">
        {JSON.stringify(lastOnLinkDetected)}
      </pre>

      <pre data-testid="test-links-html-output">{editorHtml}</pre>
    </div>
  );
}

const editorStyle: EnrichedInputStyle = {
  width: '100%',
  maxWidth: 360,
  minHeight: 100,
  paddingVertical: 8,
  paddingHorizontal: 8,
  fontSize: 16,
};
