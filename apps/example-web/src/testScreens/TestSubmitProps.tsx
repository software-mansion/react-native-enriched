import { useRef, useState } from 'react';
import {
  EnrichedTextInput,
  type EnrichedTextInputInstance,
  type EnrichedTextInputProps,
  type OnSubmitEditing,
} from 'react-native-enriched';
import type { NativeSyntheticEvent, ReturnKeyTypeOptions } from 'react-native';

const editorWrapStyle = {
  backgroundColor: '#ddd',
  padding: '16px',
  borderRadius: '8px',
} as const;

export function TestSubmitProps() {
  const ref = useRef<EnrichedTextInputInstance>(null);
  const params = new URLSearchParams(window.location.search);

  const modeParam = params.get('mode');
  const mode: 'newline' | 'submit' | 'blurAndSubmit' =
    modeParam === 'submit' || modeParam === 'blurAndSubmit'
      ? modeParam
      : 'newline';

  const enterKeyTest = params.get('enterKeyTest') === '1';
  const returnKeyQuery = params.get('returnKeyType') ?? 'search';

  const submitBehavior: EnrichedTextInputProps['submitBehavior'] = enterKeyTest
    ? 'newline'
    : mode === 'newline'
      ? 'newline'
      : mode;

  const returnKeyType: ReturnKeyTypeOptions | undefined = enterKeyTest
    ? (returnKeyQuery as ReturnKeyTypeOptions)
    : undefined;

  const [submitLog, setSubmitLog] = useState({
    submitCount: 0,
    text: '',
  });

  const handleSubmitEditing = (e: NativeSyntheticEvent<OnSubmitEditing>) => {
    setSubmitLog((prev) => ({
      submitCount: prev.submitCount + 1,
      text: e.nativeEvent.text,
    }));
  };

  return (
    <div data-testid="test-submit-root">
      <p data-testid="test-submit-mode-label">{mode}</p>
      <div
        className="editor-wrapper"
        style={editorWrapStyle}
        onClick={() => ref.current?.focus()}
      >
        <EnrichedTextInput
          ref={ref}
          placeholder="Submit / keyboard test"
          autoFocus
          editable
          scrollEnabled
          submitBehavior={submitBehavior}
          returnKeyType={returnKeyType}
          onSubmitEditing={handleSubmitEditing}
        />
      </div>
      <pre data-testid="submit-log">
        {JSON.stringify({
          submitCount: submitLog.submitCount,
          text: submitLog.text,
        })}
      </pre>
    </div>
  );
}
