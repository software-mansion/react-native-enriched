import { useRef, useState } from 'react';
import {
  EnrichedTextInput,
  type EnrichedTextInputInstance,
  type OnChangeStateEvent,
} from 'react-native-enriched';
import { Toolbar } from './components/Toolbar';

import './App.css';

const DEFAULT_STYLE_STATE = {
  isActive: false,
  isConflicting: false,
  isBlocking: false,
};

const DEFAULT_STYLES: OnChangeStateEvent = {
  bold: DEFAULT_STYLE_STATE,
  italic: DEFAULT_STYLE_STATE,
  underline: DEFAULT_STYLE_STATE,
  strikeThrough: DEFAULT_STYLE_STATE,
  inlineCode: DEFAULT_STYLE_STATE,
  h1: DEFAULT_STYLE_STATE,
  h2: DEFAULT_STYLE_STATE,
  h3: DEFAULT_STYLE_STATE,
  h4: DEFAULT_STYLE_STATE,
  h5: DEFAULT_STYLE_STATE,
  h6: DEFAULT_STYLE_STATE,
  blockQuote: DEFAULT_STYLE_STATE,
  codeBlock: DEFAULT_STYLE_STATE,
  orderedList: DEFAULT_STYLE_STATE,
  unorderedList: DEFAULT_STYLE_STATE,
  link: DEFAULT_STYLE_STATE,
  image: DEFAULT_STYLE_STATE,
  mention: DEFAULT_STYLE_STATE,
};

function App() {
  const ref = useRef<EnrichedTextInputInstance>(null);
  const [stylesState, setStylesState] =
    useState<OnChangeStateEvent>(DEFAULT_STYLES);

  const handleChangeState = (state: OnChangeStateEvent) => {
    console.log('Editor state changed:', state);
    setStylesState(state);
  };

  const handleOpenLinkModal = () => {
    console.log('Open link modal');
  };

  const handleSelectImage = () => {
    console.log('Select image');
  };

  return (
    <div className="container">
      <h1>Enriched Text Input</h1>
      <div className="editor">
        <Toolbar
          stylesState={stylesState}
          editorRef={ref}
          onOpenLinkModal={handleOpenLinkModal}
          onSelectImage={handleSelectImage}
        />
        <EnrichedTextInput
          ref={ref}
          autoFocus={false}
          placeholder="Type something..."
          style={{ border: '1px solid #ddd', padding: '8px' }}
          onChangeState={(e) => {
            handleChangeState(e.nativeEvent);
          }}
        />
      </div>
    </div>
  );
}

export default App;
