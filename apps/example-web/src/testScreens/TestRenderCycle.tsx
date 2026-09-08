import { useMemo, useRef, useState } from 'react';
import {
  EnrichedTextInput,
  type EnrichedTextInputInstance,
  type HtmlStyle,
} from 'react-native-enriched-html';
import { WEB_DEFAULT_HTML_STYLE } from '../defaultHtmlStyle';

const VARIANTS = {
  a: {
    defaultValue: '<p>Variant A</p>',
    htmlStyle: WEB_DEFAULT_HTML_STYLE,
  },
  b: {
    defaultValue: '<h1>Variant B</h1>',
    htmlStyle: { ...WEB_DEFAULT_HTML_STYLE, h1: { fontSize: 48 } },
  },
} as const satisfies Record<
  string,
  { defaultValue: string; htmlStyle: HtmlStyle }
>;

export function TestRenderCycle() {
  const ref = useRef<EnrichedTextInputInstance>(null);
  const [variant, setVariant] = useState<keyof typeof VARIANTS>('a');

  const { defaultValue, htmlStyle } = useMemo(
    () => VARIANTS[variant],
    [variant]
  );

  return (
    <div data-testid="test-render-cycle-root">
      <div
        className="editor-wrapper"
        style={editorContainerStyle}
        data-testid="editor-container"
        onClick={() => ref.current?.focus()}
      >
        <EnrichedTextInput
          ref={ref}
          defaultValue={defaultValue}
          htmlStyle={htmlStyle}
          placeholder="Test editor"
          autoFocus
          editable
          scrollEnabled
        />
      </div>

      <button
        type="button"
        data-testid="toggle-variant-button"
        onClick={() => {
          setVariant((prev) => (prev === 'a' ? 'b' : 'a'));
        }}
      >
        Toggle variant
      </button>

      <pre data-testid="variant-output">{variant}</pre>
    </div>
  );
}

const editorContainerStyle = {
  backgroundColor: '#ddd',
  padding: '16px',
  borderRadius: '8px',
} as const;
