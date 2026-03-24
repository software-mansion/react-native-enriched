import { useRef, useState } from 'react';
import './App.css';
import {
  EnrichedTextInput,
  type EnrichedTextInputInstance,
  type OnKeyPressEvent,
  type OnChangeTextEvent,
  type OnChangeSelectionEvent,
  type FocusEvent,
  type BlurEvent,
} from 'react-native-enriched';
import type { NativeSyntheticEvent } from 'react-native';
import { EditorActions } from './components/EditorActions';
import { SetHtmlValueControl } from './components/SetHtmlValueControl';
import { HtmlOutputPanel } from './components/HtmlOutputPanel';

function App() {
  const ref = useRef<EnrichedTextInputInstance>(null);
  const [currentHtml, setCurrentHtml] = useState('');
  const [showHtmlOutput, setShowHtmlOutput] = useState(false);

  const handleFocus = (e: FocusEvent) => {
    console.log('[EnrichedTextInput] onFocus', e);
  };

  const handleBlur = (e: BlurEvent) => {
    console.log('[EnrichedTextInput] onBlur', e);
  };

  const handleKeyPress = (e: NativeSyntheticEvent<OnKeyPressEvent>) => {
    console.log('[EnrichedTextInput] onKeyPress event', e);
  };

  const handleOnChangeText = (e: NativeSyntheticEvent<OnChangeTextEvent>) => {
    console.log('[EnrichedTextInput] onChangeText event', e);
  };

  const handleOnChangeHtml = (e: NativeSyntheticEvent<{ value: string }>) => {
    console.log('[EnrichedTextInput] onChangeHtml event', e);
    setCurrentHtml(e.nativeEvent.value);
  };

  const handleChangeSelection = (
    e: NativeSyntheticEvent<OnChangeSelectionEvent>
  ) => {
    console.log('[EnrichedTextInput] onChangeSelection event', e);
  };

  return (
    <div className="container">
      <EditorActions
        showHtmlOutput={showHtmlOutput}
        onFocus={() => ref.current?.focus()}
        onBlur={() => ref.current?.blur()}
        onClear={() => ref.current?.setValue('')}
        onToggleHtml={() => {
          setShowHtmlOutput((prev) => !prev);
        }}
      />

      <div className="editor-wrapper" onClick={() => ref.current?.focus()}>
        <div className="editor-content">
          <EnrichedTextInput
            ref={ref}
            placeholder="Type something"
            autoFocus={true}
            editable={true}
            scrollEnabled={true}
            autoCapitalize="sentences"
            onFocus={handleFocus}
            onBlur={handleBlur}
            onKeyPress={handleKeyPress}
            onChangeText={handleOnChangeText}
            onChangeSelection={handleChangeSelection}
            onChangeHtml={handleOnChangeHtml}
          />
        </div>
      </div>

      <SetHtmlValueControl
        onSetValue={(value) => {
          ref.current?.setValue(value);
        }}
      />

      {showHtmlOutput && <HtmlOutputPanel html={currentHtml} />}
    </div>
  );
}

export default App;
