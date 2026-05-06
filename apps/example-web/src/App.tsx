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
  type OnLinkDetected,
} from 'react-native-enriched';
import { WEB_DEFAULT_HTML_STYLE } from './defaultHtmlStyle';
import type { NativeSyntheticEvent } from 'react-native';
import { EditorActions } from './components/EditorActions';
import { SetValueModal } from './components/SetValueModal';
import { LinkModal } from './components/LinkModal';
import { HtmlOutputPanel } from './components/HtmlOutputPanel';
import './App.css';
import { Toolbar } from './components/Toolbar';

const DEFAULT_LINK_STATE: OnLinkDetected = {
  text: '',
  url: '',
  start: 0,
  end: 0,
};

function App() {
  const ref = useRef<EnrichedTextInputInstance>(null);
  const [currentHtml, setCurrentHtml] = useState('');
  const [showHtmlOutput, setShowHtmlOutput] = useState(false);
  const [isSetValueModalOpen, setIsSetValueModalOpen] = useState(false);
  const [editorState, setEditorState] = useState<OnChangeStateEvent | null>(
    null
  );
  const [selection, setSelection] = useState<OnChangeSelectionEvent | null>(
    null
  );
  const [currentLink, setCurrentLink] =
    useState<OnLinkDetected>(DEFAULT_LINK_STATE);
  const [isLinkModalOpen, setIsLinkModalOpen] = useState(false);

  const isLinkActive = !!editorState?.link.isActive;
  const hasLinkUrl = currentLink.url.length > 0;
  const hasLinkSpan = currentLink.start !== 0 || currentLink.end !== 0;
  const selectionInsideLink =
    selection !== null &&
    selection.start >= currentLink.start &&
    selection.end <= currentLink.end;

  const insideCurrentLink =
    isLinkActive && hasLinkUrl && hasLinkSpan && selectionInsideLink;

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
    setSelection(e.nativeEvent);
  };

  const openLinkModal = () => {
    setIsLinkModalOpen(true);
  };

  const closeLinkModal = () => {
    setIsLinkModalOpen(false);
  };

  const submitLink = (text: string, url: string) => {
    if (!selection || url.length === 0) {
      closeLinkModal();
      return;
    }
    const newText = text.length > 0 ? text : url;
    if (insideCurrentLink) {
      ref.current?.setLink(currentLink.start, currentLink.end, newText, url);
    } else {
      ref.current?.setLink(selection.start, selection.end, newText, url);
    }
    closeLinkModal();
  };

  const handleChangeState = (e: NativeSyntheticEvent<OnChangeStateEvent>) => {
    console.log('[EnrichedTextInput] onChangeState event', e.nativeEvent);
    setEditorState(e.nativeEvent);
  };

  const handleOnLinkDetected = (e: OnLinkDetected) => {
    console.log('[EnrichedTextInput] onLinkDetected event', e);
    setCurrentLink(e);
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
        onLinkDetected={handleOnLinkDetected}
        htmlStyle={WEB_DEFAULT_HTML_STYLE}
      />

      <Toolbar
        editorRef={ref}
        state={editorState}
        onOpenLinkModal={openLinkModal}
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

      {isLinkModalOpen && (
        <LinkModal
          editedText={
            insideCurrentLink ? currentLink.text : (selection?.text ?? '')
          }
          editedUrl={insideCurrentLink ? currentLink.url : ''}
          onSubmit={submitLink}
          onClose={closeLinkModal}
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

export default App;
