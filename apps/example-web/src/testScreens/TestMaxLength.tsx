import { useRef, useState, type ChangeEvent } from 'react';
import {
  EnrichedTextInput,
  type EnrichedInputStyle,
  type EnrichedTextInputInstance,
} from 'react-native-enriched-html';
import { WEB_DEFAULT_HTML_STYLE } from '../defaultHtmlStyle';

function toInteger(value: string): number {
  const parsed = parseInt(value, 10);
  return Number.isNaN(parsed) ? 0 : parsed;
}

export function TestMaxLength() {
  const ref = useRef<EnrichedTextInputInstance>(null);
  const [maxLengthInput, setMaxLengthInput] = useState('10');
  const [htmlInput, setHtmlInput] = useState('<html><p></p></html>');
  const [editorHtml, setEditorHtml] = useState('');
  const [selection, setSelection] = useState({ start: '0', end: '0' });
  const [link, setLink] = useState({
    start: '0',
    end: '0',
    text: 'link',
    url: 'https://example.com',
  });
  const [mention, setMention] = useState({ indicator: '@', text: 'Jane' });
  const [imageInput, setImageInput] = useState({
    src: '/pw-e2e-ok.png',
    width: '40',
    height: '40',
  });

  const maxLength =
    maxLengthInput.trim() === '' ? undefined : toInteger(maxLengthInput);

  return (
    <div data-testid="test-max-length-root">
      <div
        data-testid="test-max-length-editor"
        onClick={() => ref.current?.focus()}
      >
        <EnrichedTextInput
          ref={ref}
          defaultValue="<html><p></p></html>"
          editable
          scrollEnabled
          style={editorStyle}
          htmlStyle={WEB_DEFAULT_HTML_STYLE}
          maxLength={maxLength}
          mentionIndicators={['@', '#']}
          onChangeHtml={(e) => {
            setEditorHtml(e.nativeEvent.value);
          }}
        />
      </div>

      <div>
        <label>
          maxLength{' '}
          <input
            data-testid="test-max-length-maxlength-input"
            value={maxLengthInput}
            onChange={(e: ChangeEvent<HTMLInputElement>) => {
              setMaxLengthInput(e.target.value);
            }}
          />
        </label>
      </div>

      <textarea
        data-testid="test-max-length-html-input"
        value={htmlInput}
        onChange={(e: ChangeEvent<HTMLTextAreaElement>) => {
          setHtmlInput(e.target.value);
        }}
        rows={4}
      />
      <button
        type="button"
        data-testid="test-max-length-set-value-button"
        onClick={() => ref.current?.setValue(htmlInput)}
      >
        Set value
      </button>

      <div>
        <input
          data-testid="test-max-length-selection-start"
          type="number"
          value={selection.start}
          onChange={(e) => {
            setSelection((prev) => ({ ...prev, start: e.target.value }));
          }}
        />
        <input
          data-testid="test-max-length-selection-end"
          type="number"
          value={selection.end}
          onChange={(e) => {
            setSelection((prev) => ({ ...prev, end: e.target.value }));
          }}
        />
        <button
          type="button"
          data-testid="test-max-length-apply-selection-button"
          onClick={() =>
            ref.current?.setSelection(
              toInteger(selection.start),
              toInteger(selection.end)
            )
          }
        >
          setSelection
        </button>
      </div>

      <div>
        <input
          data-testid="test-max-length-setlink-start"
          type="number"
          value={link.start}
          onChange={(e) => {
            setLink((prev) => ({ ...prev, start: e.target.value }));
          }}
        />
        <input
          data-testid="test-max-length-setlink-end"
          type="number"
          value={link.end}
          onChange={(e) => {
            setLink((prev) => ({ ...prev, end: e.target.value }));
          }}
        />
        <input
          data-testid="test-max-length-setlink-text"
          value={link.text}
          onChange={(e) => {
            setLink((prev) => ({ ...prev, text: e.target.value }));
          }}
        />
        <input
          data-testid="test-max-length-setlink-url"
          value={link.url}
          onChange={(e) => {
            setLink((prev) => ({ ...prev, url: e.target.value }));
          }}
        />
        <button
          type="button"
          data-testid="test-max-length-apply-setlink-button"
          onClick={() =>
            ref.current?.setLink(
              toInteger(link.start),
              toInteger(link.end),
              link.text,
              link.url
            )
          }
        >
          setLink
        </button>
      </div>

      <div>
        <input
          data-testid="test-max-length-mention-indicator"
          value={mention.indicator}
          onChange={(e) => {
            setMention((prev) => ({ ...prev, indicator: e.target.value }));
          }}
        />
        <input
          data-testid="test-max-length-mention-text"
          value={mention.text}
          onChange={(e) => {
            setMention((prev) => ({ ...prev, text: e.target.value }));
          }}
        />
        <button
          type="button"
          data-testid="test-max-length-set-mention-button"
          onMouseDown={(e) => {
            e.preventDefault();
          }}
          onClick={() =>
            ref.current?.setMention(mention.indicator, mention.text, {
              id: '1',
            })
          }
        >
          setMention
        </button>
        <button
          type="button"
          data-testid="test-max-length-start-mention-button"
          onMouseDown={(e) => {
            e.preventDefault();
          }}
          onClick={() => ref.current?.startMention(mention.indicator)}
        >
          startMention
        </button>
      </div>

      <div>
        <input
          data-testid="test-max-length-image-src"
          value={imageInput.src}
          onChange={(e) => {
            setImageInput((prev) => ({ ...prev, src: e.target.value }));
          }}
        />
        <input
          data-testid="test-max-length-image-width"
          type="number"
          value={imageInput.width}
          onChange={(e) => {
            setImageInput((prev) => ({ ...prev, width: e.target.value }));
          }}
        />
        <input
          data-testid="test-max-length-image-height"
          type="number"
          value={imageInput.height}
          onChange={(e) => {
            setImageInput((prev) => ({ ...prev, height: e.target.value }));
          }}
        />
        <button
          type="button"
          data-testid="test-max-length-set-image-button"
          onClick={() =>
            ref.current?.setImage(
              imageInput.src,
              toInteger(imageInput.width),
              toInteger(imageInput.height)
            )
          }
        >
          setImage
        </button>
      </div>

      <pre data-testid="test-max-length-html-output">{editorHtml}</pre>
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
