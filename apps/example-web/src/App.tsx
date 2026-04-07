import { useRef, useState } from 'react';
import {
  EnrichedTextInput,
  type EnrichedTextInputInstance,
  type OnKeyPressEvent,
  type OnChangeTextEvent,
  type OnChangeSelectionEvent,
  type OnChangeStateEvent,
  type FocusEvent,
  type BlurEvent,
  type EnrichedInputStyle,
  type HtmlStyle,
} from 'react-native-enriched';
import type { NativeSyntheticEvent } from 'react-native';
import { EditorActions } from './components/EditorActions';
import { SetValueModal } from './components/SetValueModal';
import { HtmlOutputPanel } from './components/HtmlOutputPanel';
import './App.css';
import { Toolbar } from './components/Toolbar';

function App() {
  const ref = useRef<EnrichedTextInputInstance>(null);
  const [currentHtml, setCurrentHtml] = useState('');
  const [showHtmlOutput, setShowHtmlOutput] = useState(false);
  const [isSetValueModalOpen, setIsSetValueModalOpen] = useState(false);
  const [editorState, setEditorState] = useState<OnChangeStateEvent | null>(
    null
  );

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

  const handleChangeState = (e: NativeSyntheticEvent<OnChangeStateEvent>) => {
    console.log('[EnrichedTextInput] onChangeState event', e.nativeEvent);
    setEditorState(e.nativeEvent);
  };

  return (
    <div className="container">
      <h1 className="app-title">Enriched Text Input</h1>

      <EnrichedTextInput
        ref={ref}
        placeholder="Type something here..."
        autoFocus
        editable
        scrollEnabled
        autoCapitalize="sentences"
        style={enrichedInputStyle}
        onFocus={handleFocus}
        onBlur={handleBlur}
        onKeyPress={handleKeyPress}
        onChangeText={handleOnChangeText}
        onChangeSelection={handleChangeSelection}
        onChangeHtml={handleOnChangeHtml}
        onChangeState={handleChangeState}
        htmlStyle={htmlStyle}
      />

      <Toolbar
        state={editorState}
        onToggleBold={() => ref.current?.toggleBold()}
        onToggleItalic={() => ref.current?.toggleItalic()}
        onToggleUnderline={() => ref.current?.toggleUnderline()}
        onToggleStrikeThrough={() => ref.current?.toggleStrikeThrough()}
        onToggleInlineCode={() => ref.current?.toggleInlineCode()}
      />

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

const enrichedInputStyle: EnrichedInputStyle = {
  backgroundColor: 'gainsboro',
  width: '100%',
  marginVertical: 12,
  maxHeight: 300,
  paddingVertical: 12,
  paddingHorizontal: 14,
  borderRadius: 8,
  fontSize: 18,
};

const htmlStyle: HtmlStyle = {
  code: {
    color: 'purple',
    backgroundColor: 'yellow',
  },
};

export default App;
