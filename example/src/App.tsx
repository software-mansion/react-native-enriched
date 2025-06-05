import {
  View,
  StyleSheet,
  Text,
  type NativeSyntheticEvent,
  TextInput,
  ScrollView,
} from 'react-native';
import {
  RichTextInput,
  type OnChangeTextEvent,
  type RichTextInputInstance,
  type OnLinkDetected,
  type OnChangeMentionEvent,
  type OnChangeHtmlEvent,
  type OnChangeStateEvent,
  type OnChangeSelectionEvent,
  type RichTextStyle,
} from '@swmansion/react-native-rich-text-editor';
import { useRef, useState } from 'react';
import { Button } from './components/Button';
import { Toolbar } from './components/Toolbar';
import { LinkModal } from './components/LinkModal';
import { launchImageLibrary } from 'react-native-image-picker';
import { MentionPopup } from './components/MentionPopup';
import { type MentionItem, useMention } from './useMention';

type StylesState = OnChangeStateEvent;

type CurrentLinkState = OnLinkDetected;

interface Selection {
  start: number;
  end: number;
  text: string;
}

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

const DEBUG_SCROLLABLE = false;

export default function App() {
  const [isMentionPopupOpen, setIsMentionPopupOpen] = useState(false);
  const [isLinkModalOpen, setIsLinkModalOpen] = useState(false);

  const [selection, setSelection] = useState<Selection>();
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

  const handleChangeState = (e: NativeSyntheticEvent<OnChangeStateEvent>) => {
    setStylesState(e.nativeEvent);
  };

  const handleFocus = () => {
    ref.current?.focus();
  };

  const handleBlur = () => {
    ref.current?.blur();
  };

  const handleSetValue = () => {
    ref.current?.setValue('<html><b>Hello</b> <i>world</i></html>');
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
    onMentionChange('');
  };

  const submitLink = (text: string, url: string) => {
    if (!selection) return;

    ref.current?.setLink(selection.start, selection.end, text, url);
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

  const handleChangeMention = ({ text }: OnChangeMentionEvent) => {
    if (!isMentionPopupOpen) {
      openMentionPopup();
    }

    onMentionChange(text);
  };

  const handleMentionSelected = (item: MentionItem) => {
    ref.current?.setMention(`@${item.name}`, {
      id: item.id,
      type: 'user',
    });
    closeMentionPopup();
  };

  const handleFocusEvent = () => {
    console.log('Input focused');
  };

  const handleBlurEvent = () => {
    console.log('Input blurred');
  };

  const handleSelectionChangeEvent = (
    e: NativeSyntheticEvent<OnChangeSelectionEvent>
  ) => {
    setSelection(e.nativeEvent);
  };

  return (
    <>
      <ScrollView
        style={styles.container}
        contentContainerStyle={styles.content}
      >
        <Text style={styles.label}>SWM Rich Text Editor</Text>
        <View style={styles.editor}>
          <RichTextInput
            autoFocus
            ref={ref}
            mentionIndicators={['@', '#']}
            style={styles.editorInput}
            richTextStyle={richTextStyles}
            placeholder="Type something here..."
            placeholderTextColor="blue"
            selectionColor="red"
            cursorColor="yellow"
            defaultValue={defaultValue}
            onChangeText={handleChangeText}
            onChangeHtml={handleChangeHtml}
            onChangeState={handleChangeState}
            onLinkDetected={setCurrentLink}
            onMentionDetected={console.log}
            onStartMention={openMentionPopup}
            onChangeMention={handleChangeMention}
            onEndMention={closeMentionPopup}
            onFocus={handleFocusEvent}
            onBlur={handleBlurEvent}
            onChangeSelection={handleSelectionChangeEvent}
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
        <Button title="Set value" onPress={handleSetValue} />
        {DEBUG_SCROLLABLE && <View style={styles.scrollPlaceholder} />}
      </ScrollView>
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

const richTextStyles: RichTextStyle = {
  h1: {
    fontSize: 40,
  },
  h2: {
    fontSize: 32,
  },
  h3: {
    fontSize: 24,
  },
  blockquote: {
    borderColor: 'navy',
    borderWidth: 4,
    gapWidth: 16,
  },
  codeblock: {
    color: 'green',
    borderRadius: 8,
    backgroundColor: 'aquamarine',
  },
  code: {
    color: 'purple',
    backgroundColor: 'yellow',
  },
  a: {
    color: 'green',
    textDecorationLine: 'underline',
  },
  mention: {
    color: 'red',
    backgroundColor: 'lightyellow',
    textDecorationLine: 'underline',
  },
  img: {
    width: 50,
    height: 50,
  },
  ol: {
    gapWidth: 16,
    marginLeft: 24,
  },
  ul: {
    bulletColor: 'aquamarine',
    bulletSize: 8,
    marginLeft: 24,
    gapWidth: 16,
  },
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  content: {
    flexGrow: 1,
    padding: 16,
    paddingTop: 100,
    alignItems: 'center',
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
    height: 40,
    borderBottomWidth: 1,
    borderBottomColor: 'grey',
  },
  scrollPlaceholder: {
    marginTop: 24,
    width: '100%',
    height: 1000,
    backgroundColor: 'rgb(0, 26, 114)',
  },
});
