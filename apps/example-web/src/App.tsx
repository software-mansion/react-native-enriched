import { useRef, useState } from 'react';
import {
  EnrichedTextInput,
  type EnrichedTextInputInstance,
  type OnChangeHtmlEvent,
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
  const [html, setHtml] = useState('');

  const handleChangeState = (state: OnChangeStateEvent) => {
    setStylesState(state);
  };

  const handleOnChangeHtml = (state: OnChangeHtmlEvent) => {
    setHtml(state.value);
  };

  const handleOpenLinkModal = () => {
    console.log('Open link modal');
  };

  const handleSelectImage = () => {
    console.log('Select image');
  };

  const defaultValue = `<html>
    <p><b>Bold</b></p>
    <p><i>Italic</i></p>
    <p><u>Underline</u></p>
    <p><s>Strike</s></p>
    <h1>Header1</h1>
    </html>`;

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
          editable={true}
          defaultValue={defaultValue}
          placeholder="Type something..."
          placeholderTextColor="rgb(0, 26, 114)"
          selectionColor="deepskyblue"
          cursorColor="dodgerblue"
          autoCapitalize="sentences"
          style={{ border: '1px solid #ddd', padding: '8px' }}
          onChangeState={handleChangeState}
          onChangeHtml={handleOnChangeHtml}
        />
        <div className="html-output">
          <h3>HTML Output:</h3>
          <div>{html}</div>
        </div>
      </div>
    </div>
  );
}

export default App;
