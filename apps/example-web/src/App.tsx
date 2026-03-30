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
import { SetValueModal } from './components/SetValueModal';
import { HtmlOutputPanel } from './components/HtmlOutputPanel';

function App() {
  const ref = useRef<EnrichedTextInputInstance>(null);
  const [currentHtml, setCurrentHtml] = useState('');
  const [showHtmlOutput, setShowHtmlOutput] = useState(false);
  const [isSetValueModalOpen, setIsSetValueModalOpen] = useState(false);

  const handleFocus = (e: FocusEvent) => {
    console.log('[EnrichedTextInput] onFocus', e.nativeEvent);
  };

  const handleBlur = (e: BlurEvent) => {
    console.log('[EnrichedTextInput] onBlur', e.nativeEvent);
  };

  const handleKeyPress = (e: NativeSyntheticEvent<OnKeyPressEvent>) => {
    console.log('[EnrichedTextInput] onKeyPress event', e.nativeEvent);
  };

  const handleOnChangeText = (e: NativeSyntheticEvent<OnChangeTextEvent>) => {
    console.log('[EnrichedTextInput] onChangeText event', e.nativeEvent);
  };

  const handleOnChangeHtml = (e: NativeSyntheticEvent<{ value: string }>) => {
    console.log('[EnrichedTextInput] onChangeHtml event', e.nativeEvent);
    setCurrentHtml(e.nativeEvent.value);
  };

  const handleChangeSelection = (
    e: NativeSyntheticEvent<OnChangeSelectionEvent>
  ) => {
    console.log('[EnrichedTextInput] onChangeSelection event', e.nativeEvent);
  };

  return (
    <div className="container">
      <h1 className="app-title">Enriched Text Input</h1>

      <div className="editor-wrapper" onClick={() => ref.current?.focus()}>
        <div className="editor-content">
          <EnrichedTextInput
            ref={ref}
            placeholder="Type something"
            autoFocus
            editable
            scrollEnabled
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

      <EditorActions
        showHtmlOutput={showHtmlOutput}
        onFocus={() => {
          ref.current?.focus();
        }}
        onBlur={() => {
          ref.current?.blur();
        }}
        onClear={() => {
          ref.current?.setValue('');
        }}
        onToggleHtml={() => {
          setShowHtmlOutput((prev) => !prev);
        }}
        onOpenSetValue={() => {
          setIsSetValueModalOpen(true);
        }}
      />

      {showHtmlOutput && <HtmlOutputPanel html={currentHtml} />}

      {isSetValueModalOpen && (
        <SetValueModal
          onSetValue={(value) => {
            ref.current?.setValue(value);
          }}
          onClose={() => {
            setIsSetValueModalOpen(false);
          }}
        />
      )}
    </div>
  );
}

export default App;
