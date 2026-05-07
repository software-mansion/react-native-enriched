import { useRef, useState } from 'react';
import {
  EnrichedTextInput,
  type EnrichedInputStyle,
  type EnrichedTextInputInstance,
} from 'react-native-enriched';
import { WEB_DEFAULT_HTML_STYLE } from '../defaultHtmlStyle';

export function TestMentions() {
  const ref = useRef<EnrichedTextInputInstance>(null);
  const [eventType, setEventType] = useState('');
  const [eventIndicator, setEventIndicator] = useState('');
  const [eventText, setEventText] = useState('');
  const [html, setHtml] = useState('');
  const [detectedCount, setDetectedCount] = useState(0);
  const [detectedText, setDetectedText] = useState('');
  const [detectedIndicator, setDetectedIndicator] = useState('');

  const preventDefault = (e: React.MouseEvent<HTMLButtonElement>) => {
    e.preventDefault();
  };
  return (
    <div>
      <div data-testid="mention-test-editor">
        <EnrichedTextInput
          ref={ref}
          defaultValue="<html><p></p></html>"
          editable
          scrollEnabled
          style={editorStyle}
          htmlStyle={WEB_DEFAULT_HTML_STYLE}
          mentionIndicators={['@', '#']}
          onStartMention={(indicator) => {
            setEventType('start');
            setEventIndicator(indicator);
            setEventText('');
          }}
          onChangeMention={({ indicator, text }) => {
            setEventType('change');
            setEventIndicator(indicator);
            setEventText(text);
          }}
          onEndMention={() => {
            setEventType('end');
            setEventIndicator('');
            setEventText('');
          }}
          onMentionDetected={({ text, indicator }) => {
            setDetectedCount((c) => c + 1);
            setDetectedText(text);
            setDetectedIndicator(indicator);
          }}
          onChangeHtml={(e) => {
            setHtml(e.nativeEvent.value);
          }}
        />
      </div>
      <div style={styles.fields}>
        <Field label="event type">
          <span data-testid="mention-event-type">{eventType}</span>
        </Field>
        <Field label="event indicator">
          <span data-testid="mention-event-indicator">{eventIndicator}</span>
        </Field>
        <Field label="event text">
          <span data-testid="mention-event-text">{eventText}</span>
        </Field>
        <Field label="detected count">
          <span data-testid="mention-detected-count">{detectedCount}</span>
        </Field>
        <Field label="detected text">
          <span data-testid="mention-detected-text">{detectedText}</span>
        </Field>
        <Field label="detected indicator">
          <span data-testid="mention-detected-indicator">
            {detectedIndicator}
          </span>
        </Field>
      </div>
      <pre data-testid="mention-html-output">{html}</pre>
      <button
        data-testid="mention-set-user-button"
        onMouseDown={preventDefault}
        onClick={() => ref.current?.setMention('@', 'Jane', { id: '1' })}
      >
        Set Mention (user)
      </button>
      <button
        data-testid="mention-set-channel-button"
        onMouseDown={preventDefault}
        onClick={() => ref.current?.setMention('#', 'general', { id: '42' })}
      >
        Set Mention (channel)
      </button>
      <button
        data-testid="mention-start-user-button"
        onMouseDown={preventDefault}
        onClick={() => ref.current?.startMention('@')}
      >
        Start mention (user)
      </button>
      <button
        data-testid="mention-start-channel-button"
        onMouseDown={preventDefault}
        onClick={() => ref.current?.startMention('#')}
      >
        Start mention (channel)
      </button>
      <button data-testid="mention-blur-target">Blur Editor</button>
    </div>
  );
}

function Field({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div style={styles.field}>
      <span style={styles.label}>{label}:</span>
      {children}
    </div>
  );
}

const styles = {
  fields: {
    marginTop: 12,
    display: 'flex',
    flexDirection: 'column' as const,
    gap: 4,
  },
  field: { display: 'flex', gap: 8, alignItems: 'center' as const },
  label: { fontSize: 12, color: '#666', minWidth: 130 },
};

const editorStyle: EnrichedInputStyle = {
  width: '100%',
  minHeight: 24,
  maxWidth: 300,
  paddingVertical: 8,
  paddingHorizontal: 8,
  fontSize: 16,
  backgroundColor: 'gainsboro',
};
