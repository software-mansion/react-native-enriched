import {
  View,
  StyleSheet,
  Text,
  type NativeSyntheticEvent,
  TextInput,
  ScrollView,
} from 'react-native';
import {
  EnrichedTextInput,
  type OnChangeTextEvent,
  type EnrichedTextInputInstance,
  type OnLinkDetected,
  type OnChangeMentionEvent,
  type OnChangeHtmlEvent,
  type OnChangeStateEvent,
  type OnChangeSelectionEvent,
  type HtmlStyle,
} from 'react-native-enriched';
import { useRef, useState } from 'react';
import { Button } from './components/Button';
import { Toolbar } from './components/Toolbar';
import { LinkModal } from './components/LinkModal';
import { launchImageLibrary } from 'react-native-image-picker';
import { type MentionItem, MentionPopup } from './components/MentionPopup';
import { useUserMention } from './useUserMention';
import { useChannelMention } from './useChannelMention';

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
  start: 0,
  end: 0,
};

const DEBUG_SCROLLABLE = false;

// Enabling this prop fixes input flickering while auto growing.
// However, it's still experimental and not tested well.
const ANDROID_EXPERIMENTAL_SYNCHRONOUS_EVENTS = true;

export default function App() {
  const [isChannelPopupOpen, setIsChannelPopupOpen] = useState(false);
  const [isUserPopupOpen, setIsUserPopupOpen] = useState(false);
  const [isLinkModalOpen, setIsLinkModalOpen] = useState(false);

  const [selection, setSelection] = useState<Selection>();
  const [stylesState, setStylesState] = useState<StylesState>(DEFAULT_STYLE);
  const [defaultValue, setDefaultValue] = useState('');
  const [currentLink, setCurrentLink] =
    useState<CurrentLinkState>(DEFAULT_LINK_STATE);

  const ref = useRef<EnrichedTextInputInstance>(null);

  const userMention = useUserMention();
  const channelMention = useChannelMention();

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

  const openUserMentionPopup = () => {
    setIsUserPopupOpen(true);
  };

  const closeUserMentionPopup = () => {
    setIsUserPopupOpen(false);
    userMention.onMentionChange('');
  };

  const openChannelMentionPopup = () => {
    setIsChannelPopupOpen(true);
  };

  const closeChannelMentionPopup = () => {
    setIsChannelPopupOpen(false);
    channelMention.onMentionChange('');
  };

  const handleStartMention = (indicator: string) => {
    indicator === '@' ? openUserMentionPopup() : openChannelMentionPopup();
  };

  const handleEndMention = (indicator: string) => {
    const isUserMention = indicator === '@';

    if (isUserMention) {
      closeUserMentionPopup();
      userMention.onMentionChange('');
      return;
    }

    closeChannelMentionPopup();
    channelMention.onMentionChange('');
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

  const handleChangeMention = ({ indicator, text }: OnChangeMentionEvent) => {
    indicator === '@'
      ? userMention.onMentionChange(text)
      : channelMention.onMentionChange(text);
    indicator === '@'
      ? !isUserPopupOpen && setIsUserPopupOpen(true)
      : !isChannelPopupOpen && setIsChannelPopupOpen(true);
  };

  const handleUserMentionSelected = (item: MentionItem) => {
    ref.current?.setMention('@', `@${item.name}`, {
      id: item.id,
      type: 'user',
    });
    closeUserMentionPopup();
  };

  const handleChannelMentionSelected = (item: MentionItem) => {
    ref.current?.setMention('#', `#${item.name}`, {
      id: item.id,
      type: 'channel',
    });
    closeChannelMentionPopup();
  };

  const handleFocusEvent = () => {
    console.log('Input focused');
  };

  const handleBlurEvent = () => {
    console.log('Input blurred');
  };

  const handleLinkDetected = (state: CurrentLinkState) => {
    console.log(state);
    setCurrentLink(state);
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
          <EnrichedTextInput
            autoFocus
            ref={ref}
            mentionIndicators={['@', '#']}
            style={styles.editorInput}
            htmlStyle={htmlStyle}
            placeholder="Type something here..."
            placeholderTextColor="blue"
            selectionColor="red"
            cursorColor="yellow"
            autocapitalize="sentences"
            defaultValue={defaultValue}
            onChangeText={handleChangeText}
            onChangeHtml={handleChangeHtml}
            onChangeState={handleChangeState}
            onLinkDetected={handleLinkDetected}
            onMentionDetected={console.log}
            onStartMention={handleStartMention}
            onChangeMention={handleChangeMention}
            onEndMention={handleEndMention}
            onFocus={handleFocusEvent}
            onBlur={handleBlurEvent}
            onChangeSelection={handleSelectionChangeEvent}
            androidExperimentalSynchronousEvents={
              ANDROID_EXPERIMENTAL_SYNCHRONOUS_EVENTS
            }
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
        variant="user"
        data={userMention.data}
        isOpen={isUserPopupOpen}
        onItemPress={handleUserMentionSelected}
      />
      <MentionPopup
        variant="channel"
        data={channelMention.data}
        isOpen={isChannelPopupOpen}
        onItemPress={handleChannelMentionSelected}
      />
    </>
  );
}

const htmlStyle: HtmlStyle = {
  h1: {
    fontSize: 40,
    bold: true,
  },
  h2: {
    fontSize: 32,
    bold: true,
  },
  h3: {
    fontSize: 24,
    bold: true,
  },
  blockquote: {
    borderColor: 'navy',
    borderWidth: 4,
    gapWidth: 16,
    color: 'navy',
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
    '#': {
      color: 'blue',
      backgroundColor: 'lightblue',
      textDecorationLine: 'underline',
    },
    '@': {
      color: 'green',
      backgroundColor: 'lightgreen',
      textDecorationLine: 'none',
    },
  },
  img: {
    width: 50,
    height: 50,
  },
  ol: {
    gapWidth: 16,
    marginLeft: 24,
    markerColor: 'navy',
    markerFontWeight: 'bold',
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
