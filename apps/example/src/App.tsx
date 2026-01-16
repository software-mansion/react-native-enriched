import { View, StyleSheet, Text, Platform, FlatList } from 'react-native';
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
  type OnKeyPressEvent,
  EnrichedText,
} from 'react-native-enriched';
import { useRef, useState } from 'react';
import { Button } from './components/Button';
import { Toolbar } from './components/Toolbar';
import { LinkModal } from './components/LinkModal';
import { ValueModal } from './components/ValueModal';
import { launchImageLibrary } from 'react-native-image-picker';
import { type MentionItem, MentionPopup } from './components/MentionPopup';
import { useUserMention } from './hooks/useUserMention';
import { useChannelMention } from './hooks/useChannelMention';
import { ImageModal } from './components/ImageModal';
import {
  DEFAULT_IMAGE_HEIGHT,
  DEFAULT_IMAGE_WIDTH,
  prepareImageDimensions,
} from './utils/prepareImageDimensions';

type StylesState = OnChangeStateEvent;

type CurrentLinkState = OnLinkDetected;

interface Selection {
  start: number;
  end: number;
  text: string;
}

const DEFAULT_STYLE_STATE = {
  isActive: false,
  isConflicting: false,
  isBlocking: false,
};

const DEFAULT_STYLES: StylesState = {
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

const DEFAULT_LINK_STATE = {
  text: '',
  url: '',
  start: 0,
  end: 0,
};

const LINK_REGEX =
  /^(?:enriched:\/\/\S+|(?:https?:\/\/)?(?:www\.)?swmansion\.com(?:\/\S*)?)$/i;

// Enabling this prop fixes input flickering while auto growing.
// However, it's still experimental and not tested well.
// Disabled for now, as it's causing some strange issues.
// See: https://github.com/software-mansion/react-native-enriched/issues/229
const ANDROID_EXPERIMENTAL_SYNCHRONOUS_EVENTS = false;

export default function App() {
  const [isChannelPopupOpen, setIsChannelPopupOpen] = useState(false);
  const [isUserPopupOpen, setIsUserPopupOpen] = useState(false);
  const [isLinkModalOpen, setIsLinkModalOpen] = useState(false);
  const [isImageModalOpen, setIsImageModalOpen] = useState(false);
  const [isValueModalOpen, setIsValueModalOpen] = useState(false);

  const [richText, setRichText] = useState<Array<string>>([]);

  const [selection, setSelection] = useState<Selection>();
  const [stylesState, setStylesState] = useState<StylesState>(DEFAULT_STYLES);
  const [currentLink, setCurrentLink] =
    useState<CurrentLinkState>(DEFAULT_LINK_STATE);

  const ref = useRef<EnrichedTextInputInstance>(null);

  const userMention = useUserMention();
  const channelMention = useChannelMention();

  const insideCurrentLink =
    stylesState.link.isActive &&
    currentLink.url.length > 0 &&
    (currentLink.start || currentLink.end) &&
    selection &&
    selection.start >= currentLink.start &&
    selection.end <= currentLink.end;

  const handleChangeText = (e: OnChangeTextEvent) => {
    console.log('Text changed:', e.value);
  };

  const handleChangeHtml = (e: OnChangeHtmlEvent) => {
    console.log('HTML changed:', e.value);
  };

  const handleChangeState = (state: OnChangeStateEvent) => {
    setStylesState(state);
  };

  const pushRichText = async () => {
    const text = await ref.current?.getHTML();
    if (text) {
      setRichText((prev) => [...prev, text]);
    }
  };

  const openLinkModal = () => {
    setIsLinkModalOpen(true);
  };

  const closeLinkModal = () => {
    setIsLinkModalOpen(false);
  };

  const openImageModal = () => {
    setIsImageModalOpen(true);
  };

  const closeImageModal = () => {
    setIsImageModalOpen(false);
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

  const closeValueModal = () => {
    setIsValueModalOpen(false);
  };

  const handleStartMention = (indicator: string) => {
    if (indicator === '@') {
      userMention.onMentionChange('');
      openUserMentionPopup();
      return;
    }

    channelMention.onMentionChange('');
    openChannelMentionPopup();
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

  const submitSetValue = (value: string) => {
    ref.current?.setValue(value);
    closeValueModal();
  };

  const selectImage = async (
    width: number | undefined,
    height: number | undefined,
    remoteUrl?: string
  ) => {
    if (remoteUrl) {
      ref.current?.setImage(
        remoteUrl,
        width ?? DEFAULT_IMAGE_WIDTH,
        height ?? DEFAULT_IMAGE_HEIGHT
      );
      return;
    }

    const response = await launchImageLibrary({
      mediaType: 'photo',
      selectionLimit: 1,
    });

    if (response?.assets?.[0] === undefined) {
      return;
    }

    const asset = response.assets[0];
    const imageUri = Platform.OS === 'android' ? asset.originalPath : asset.uri;

    if (imageUri) {
      const { finalWidth, finalHeight } = prepareImageDimensions(
        asset,
        width,
        height
      );
      ref.current?.setImage(imageUri, finalWidth, finalHeight);
    }
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
  };

  const handleChannelMentionSelected = (item: MentionItem) => {
    ref.current?.setMention('#', `#${item.name}`, {
      id: item.id,
      type: 'channel',
    });
  };

  const handleFocusEvent = () => {
    console.log('Input focused');
  };

  const handleBlurEvent = () => {
    console.log('Input blurred');
  };

  const handleKeyPress = (e: OnKeyPressEvent) => {
    console.log('Key pressed:', e.key);
  };

  const handleLinkDetected = (state: CurrentLinkState) => {
    console.log(state);
    setCurrentLink(state);
  };

  const handleSelectionChangeEvent = (sel: OnChangeSelectionEvent) => {
    setSelection(sel);
  };

  const renderRichText = ({ item }: { item: string }) => (
    <EnrichedText
      numberOfLines={1}
      text={item}
      htmlStyle={htmlStyle}
      style={styles.enrichedText}
    />
  );

  return (
    <>
      <View style={styles.content}>
        <Text style={styles.label}>Enriched Text Input</Text>
        <View style={styles.editor}>
          <EnrichedTextInput
            ref={ref}
            mentionIndicators={['@', '#']}
            style={styles.editorInput}
            htmlStyle={htmlStyle}
            placeholder="Type something here..."
            placeholderTextColor="rgb(0, 26, 114)"
            selectionColor="deepskyblue"
            cursorColor="dodgerblue"
            autoCapitalize="sentences"
            linkRegex={LINK_REGEX}
            onChangeText={(e) => handleChangeText(e.nativeEvent)}
            onChangeHtml={(e) => handleChangeHtml(e.nativeEvent)}
            onChangeState={(e) => handleChangeState(e.nativeEvent)}
            onLinkDetected={handleLinkDetected}
            onMentionDetected={console.log}
            onStartMention={handleStartMention}
            onChangeMention={handleChangeMention}
            onEndMention={handleEndMention}
            onFocus={handleFocusEvent}
            onBlur={handleBlurEvent}
            onChangeSelection={(e) => handleSelectionChangeEvent(e.nativeEvent)}
            onKeyPress={(e) => handleKeyPress(e.nativeEvent)}
            androidExperimentalSynchronousEvents={
              ANDROID_EXPERIMENTAL_SYNCHRONOUS_EVENTS
            }
          />
          <Toolbar
            stylesState={stylesState}
            editorRef={ref}
            onOpenLinkModal={openLinkModal}
            onSelectImage={openImageModal}
          />
        </View>
        <Button title="Push text" onPress={pushRichText} />
        <FlatList
          overScrollMode="never"
          data={richText}
          renderItem={renderRichText}
          keyExtractor={(_, index) => `${index}`}
          style={styles.list}
          contentContainerStyle={styles.listContent}
        />
      </View>
      <LinkModal
        isOpen={isLinkModalOpen}
        editedText={
          insideCurrentLink ? currentLink.text : (selection?.text ?? '')
        }
        editedUrl={insideCurrentLink ? currentLink.url : ''}
        onSubmit={submitLink}
        onClose={closeLinkModal}
      />
      <ImageModal
        isOpen={isImageModalOpen}
        onSubmit={selectImage}
        onClose={closeImageModal}
      />
      <ValueModal
        isOpen={isValueModalOpen}
        onSubmit={submitSetValue}
        onClose={closeValueModal}
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
    fontSize: 24,
    bold: true,
  },
  h2: {
    fontSize: 60,
    bold: true,
  },
  h3: {
    fontSize: 50,
    bold: true,
  },
  h4: {
    fontSize: 40,
    bold: true,
  },
  h5: {
    fontSize: 30,
    bold: true,
  },
  h6: {
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
  content: {
    flex: 1,
    padding: 16,
    alignItems: 'center',
    backgroundColor: 'white',
  },
  list: {
    flex: 1,
    borderColor: 'navy',
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: 8,
    marginVertical: 12,
    width: '100%',
  },
  listContent: {
    padding: 12,
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
  buttonStack: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    width: '100%',
  },
  button: {
    width: '45%',
  },
  valueButton: {
    width: '100%',
  },
  editorInput: {
    marginTop: 24,
    width: '100%',
    maxHeight: 180,
    backgroundColor: 'gainsboro',
    fontSize: 18,
    fontFamily: 'Nunito-Regular',
    paddingVertical: 12,
    paddingHorizontal: 14,
  },
  enrichedText: {
    fontSize: 16,
    fontFamily: 'Nunito-Regular',
    color: 'black',
  },
  scrollPlaceholder: {
    marginTop: 24,
    width: '100%',
    height: 1000,
    backgroundColor: 'rgb(0, 26, 114)',
  },
});
