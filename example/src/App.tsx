import {
  View,
  StyleSheet,
  Text,
  type NativeSyntheticEvent,
  Linking,
  Alert,
  TextInput,
} from 'react-native';
import {
  RichTextInput,
  type OnChangeTextEvent,
  type OnChangeStyleEvent,
  type RichTextInputInstance,
  type OnPressLinkEvent,
  type OnLinkDetectedEvent,
  type OnMentionChangeEvent,
  type OnPressMentionEvent,
  type OnChangeHtmlEvent,
} from '@swmansion/react-native-rich-text-editor';
import { useRef, useState } from 'react';
import { Button } from './components/Button';
import { Toolbar } from './components/Toolbar';
import { LinkModal } from './components/LinkModal';
import { launchImageLibrary } from 'react-native-image-picker';
import { MentionPopup } from './components/MentionPopup';
import { type MentionItem, useMention } from './useMention';

type StylesState = OnChangeStyleEvent;

type CurrentLinkState = OnLinkDetectedEvent;

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
  isImage: false,
  isMention: false,
};

const DEFAULT_LINK_STATE = {
  text: '',
  url: '',
};

export default function App() {
  const [isMentionPopupOpen, setIsMentionPopupOpen] = useState(false);
  const [isLinkModalOpen, setIsLinkModalOpen] = useState(false);

  const [stylesState, setStylesState] = useState<StylesState>(DEFAULT_STYLE);
  const [defaultValue, setDefaultValue] = useState('');
  const [currentLink, setCurrentLink] =
    useState<CurrentLinkState>(DEFAULT_LINK_STATE);

  const ref = useRef<RichTextInputInstance>(null);

  const { mentionData, onMentionChange } = useMention();

  const handleChangeText = (e: NativeSyntheticEvent<OnChangeTextEvent>) => {
    console.log('Text changed:', e?.nativeEvent.value);
  };

  const handleChangeHtml = (e: NativeSyntheticEvent<OnChangeHtmlEvent>) => {
    console.log('HTML changed:', e?.nativeEvent.value);
  };

  const handleChangeStyle = (e: NativeSyntheticEvent<OnChangeStyleEvent>) => {
    setStylesState(e.nativeEvent);
  };

  const handleLinkPress = async (e: NativeSyntheticEvent<OnPressLinkEvent>) => {
    const url = e.nativeEvent.url;
    const formattedUrl = url.startsWith('http') ? url : `https://${url}`;
    await Linking.openURL(formattedUrl);
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

  const openMentionPopup = () => {
    setIsMentionPopupOpen(true);
  };

  const closeMentionPopup = () => {
    setIsMentionPopupOpen(false);
  };

  const submitLink = (text: string, url: string) => {
    ref.current?.setLink(text, url);
    closeLinkModal();
  };

  const selectImage = async () => {
    const response = await launchImageLibrary({
      mediaType: 'photo',
      selectionLimit: 1,
    });

    const imageUri = response.assets?.[0]?.originalPath;
    if (!imageUri) return;

    ref.current?.setImage(imageUri);
  };

  const handleMentionChange = (
    e: NativeSyntheticEvent<OnMentionChangeEvent>
  ) => {
    if (!isMentionPopupOpen) {
      openMentionPopup();
    }

    onMentionChange(e.nativeEvent.text);
  };

  const handleMentionSelected = (item: MentionItem) => {
    ref.current?.setMention(item.name, item.id);
    closeMentionPopup();
  };

  const handleMentionPress = (e: NativeSyntheticEvent<OnPressMentionEvent>) => {
    Alert.alert(
      'Mention Pressed',
      `Text: ${e.nativeEvent.text}\nValue: ${e.nativeEvent.value}`
    );
  };

  return (
    <>
      <View style={styles.container}>
        <Text style={styles.label}>SWM Rich Text Editor</Text>
        <View style={styles.editor}>
          <RichTextInput
            ref={ref}
            style={styles.editorInput}
            placeholder="Type something here..."
            placeholderTextColor="blue"
            defaultValue={defaultValue}
            onChangeText={handleChangeText}
            onChangeHtml={handleChangeHtml}
            onChangeStyle={handleChangeStyle}
            onPressLink={handleLinkPress}
            onLinkDetected={handleLinkDetected}
            onMentionStart={openMentionPopup}
            onMentionChange={handleMentionChange}
            onMentionEnd={closeMentionPopup}
            onPressMention={handleMentionPress}
          />
          <Toolbar
            stylesState={stylesState}
            editorRef={ref}
            onOpenLinkModal={openLinkModal}
            onSelectImage={selectImage}
          />
        </View>
        <TextInput
          placeholder="Default value"
          style={styles.defaultInput}
          onChangeText={setDefaultValue}
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
      <MentionPopup
        data={mentionData}
        isOpen={isMentionPopupOpen}
        onItemPress={handleMentionSelected}
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
  editorInput: {
    marginTop: 24,
    width: '100%',
    maxHeight: 120,
    backgroundColor: 'gainsboro',
    fontSize: 18,
    fontFamily: 'CascadiaCode-Regular',
    paddingVertical: 12,
    paddingHorizontal: 14,
  },
  defaultInput: {
    marginTop: 24,
    width: '100%',
    borderBottomWidth: 1,
    borderBottomColor: 'grey',
  },
});
