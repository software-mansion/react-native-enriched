import { useRef, useState } from 'react';
import './App.css';
import {
  EnrichedTextInput,
  type EnrichedTextInputInstance,
  type OnKeyPressEvent,
  type OnChangeSelectionEvent,
} from 'react-native-enriched';
import type { NativeSyntheticEvent } from 'react-native';
import { EditorActions } from './components/EditorActions';
import { SetHtmlValueControl } from './components/SetHtmlValueControl';
import { HtmlOutputPanel } from './components/HtmlOutputPanel';

function App() {
  const ref = useRef<EnrichedTextInputInstance>(null);
  const [currentHtml, setCurrentHtml] = useState('');
  const [showHtmlOutput, setShowHtmlOutput] = useState(false);

  const handleFocus = () => {
    console.log('[EnrichedTextInput] onFocus');
  };

  const handleBlur = () => {
    console.log('[EnrichedTextInput] onBlur');
  };

  const handleKeyPress = (e: NativeSyntheticEvent<OnKeyPressEvent>) => {
    console.log('[EnrichedTextInput] onKeyPress', e.nativeEvent.key);
  };

  const handleOnChangeHtml = (e: NativeSyntheticEvent<{ value: string }>) => {
    console.log('[EnrichedTextInput] onChangeHtml', e.nativeEvent.value);
    setCurrentHtml(e.nativeEvent.value);
  };

  const handleChangeSelection = (
    e: NativeSyntheticEvent<OnChangeSelectionEvent>
  ) => {
    console.log('[EnrichedTextInput] onChangeSelection', e.nativeEvent);
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
