import {
  View,
  StyleSheet,
  Text,
  type NativeSyntheticEvent,
  TextInput,
  Linking,
} from 'react-native';
import {
  RichTextInput,
  type OnChangeTextEvent,
  type OnChangeStyleEvent,
  type RichTextInputInstance,
  type OnPressLinkEvent,
  type OnLinkDetectedEvent,
} from '@swmansion/react-native-rich-text-editor';
import { useRef, useState } from 'react';
import { Button } from './components/Button';
import { Toolbar } from './components/Toolbar';
import { LinkModal } from './components/LinkModal';

type StylesState = OnChangeStyleEvent;

type CurrentLinkState = OnLinkDetectedEvent;

const DEFAULT_VALUE = 'This is fully native Rich Text Editor component';
const DEFAULT_STYLE: StylesState = {
  isBold: false,
  isItalic: false,
  isUnderline: false,
  isStrikeThrough: false,
  isInlineCode: false,
  isH1: false,
  isH2: false,
  isH3: false,
  isBlockQuote: false,
  isCodeBlock: false,
  isOrderedList: false,
  isUnorderedList: false,
  isLink: false,
};

const DEFAULT_LINK_STATE = {
  text: '',
  url: '',
};

export default function App() {
  const [isLinkModalOpen, setIsLinkModalOpen] = useState(false);
  const [stylesState, setStylesState] = useState<StylesState>(DEFAULT_STYLE);
  const [currentLink, setCurrentLink] =
    useState<CurrentLinkState>(DEFAULT_LINK_STATE);
  const ref = useRef<RichTextInputInstance>(null);

  const handleChangeText = (e: NativeSyntheticEvent<OnChangeTextEvent>) => {
    console.log('Text changed:', e?.nativeEvent.value);
  };

  const handleChangeStyle = (e: NativeSyntheticEvent<OnChangeStyleEvent>) => {
    setStylesState(e.nativeEvent);
  };

  const handleLinkPress = async (e: NativeSyntheticEvent<OnPressLinkEvent>) => {
    await Linking.openURL(e.nativeEvent.url);
  };

  const handleLinkDetected = async (
    e: NativeSyntheticEvent<OnLinkDetectedEvent>
  ) => {
    setCurrentLink(e.nativeEvent);
  };

  const handleFocus = () => {
    ref.current?.focus();
  };

  const handleBlur = () => {
    ref.current?.blur();
  };

  const openLinkModal = () => {
    setIsLinkModalOpen(true);
  };

  const closeLinkModal = () => {
    setIsLinkModalOpen(false);
  };

  const submitLink = (text: string, url: string) => {
    ref.current?.setLink(text, url);
    closeLinkModal();
  };

  return (
    <>
      <View style={styles.container}>
        <Text style={styles.label}>SWM Rich Text Editor</Text>
        <View style={styles.editor}>
          <RichTextInput
            ref={ref}
            style={styles.input}
            defaultValue={DEFAULT_VALUE}
            onChangeText={handleChangeText}
            onChangeStyle={handleChangeStyle}
            onPressLink={handleLinkPress}
            onLinkDetected={handleLinkDetected}
          />
          <Toolbar
            stylesState={stylesState}
            editorRef={ref}
            onOpenLinkModal={openLinkModal}
          />
        </View>
        <TextInput
          multiline
          defaultValue={DEFAULT_VALUE}
          style={styles.input}
        />
        <Button title="Focus" onPress={handleFocus} />
        <Button title="Blur" onPress={handleBlur} />
      </View>
      <LinkModal
        defaults={currentLink}
        isOpen={isLinkModalOpen}
        onSubmit={submitLink}
        onClose={closeLinkModal}
      />
    </>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 16,
  },
  editor: {
    width: '100%',
  },
  label: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    color: 'rgb(0, 26, 114)',
  },
  input: {
    marginTop: 24,
    width: '100%',
    maxHeight: 120,
    backgroundColor: 'gainsboro',
    fontSize: 18,
    paddingVertical: 12,
    paddingHorizontal: 14,
  },
});
