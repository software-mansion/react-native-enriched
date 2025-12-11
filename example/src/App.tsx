import { View, StyleSheet, Text, ScrollView, Platform } from 'react-native';
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
import { ValueModal } from './components/ValueModal';
import { launchImageLibrary } from 'react-native-image-picker';
import { type MentionItem, MentionPopup } from './components/MentionPopup';
import { useUserMention } from './hooks/useUserMention';
import { useChannelMention } from './hooks/useChannelMention';
import { HtmlSection } from './components/HtmlSection';
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
// Disabled for now, as it's causing some strange issues.
// See: https://github.com/software-mansion/react-native-enriched/issues/229
const ANDROID_EXPERIMENTAL_SYNCHRONOUS_EVENTS = false;

const generateHugeHtml = (repeat = 200) => {
  const parts: string[] = [];
  parts.push('<html>');

  // small helper to make deterministic colors
  const colorAt = (i: number) => {
    const r = (37 * (i + 1)) % 256;
    const g = (83 * (i + 7)) % 256;
    const b = (199 * (i + 13)) % 256;
    const toHex = (n: number) => n.toString(16).padStart(2, '0');
    return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
  };

  for (let i = 0; i < repeat; i++) {
    const col = colorAt(i);
    const imgW = 200 + (i % 5) * 40;
    const imgH = 100 + (i % 3) * 30;

    parts.push(
      // Headings
      `\n<h1>Section ${i + 1}</h1>`,
      `\n<h2>Subsection ${i + 1}.1</h2>`,
      `\n<h3>Topic ${i + 1}.1.a</h3>`,

      // Paragraph with mixed inline styles
      `\n<p>This is a <b>bold</b> and <i>italic</i> paragraph with <u>underline</u>, ` +
        `<s>strike</s>, <code>inline_code_${i}</code>, ` +
        `<a href="https://example.com/${i}">a link ${i}</a>, ` +
        `<mention text="@alex_${i}" indicator="@"></mention>, ` +
        `<mention text="#general_${i}" indicator="#"></mention>, ` +
        `<font color="${col}">colored text ${col}</font> and some plain text to bulk it up.</p>`,

      // Line break
      `\n<br>`,

      // Unordered list
      `<ul>`,
      `<li>bullet A ${i}</li>`,
      `<li>bullet B ${i}</li>`,
      `<li>bullet C ${i}</li>`,
      `</ul>`,

      // Ordered list
      `\n<ol>`,
      `\n<li>step 1.${i}</li>`,
      `\n<li>step 2.${i}</li>`,
      `\n<li>step 3.${i}</li>`,
      `\n</ol>`,

      // Blockquote
      `\n<blockquote>`,
      `\n<p>“Blockquote line 1 for ${i}.”</p>`,
      `\n<p>“Blockquote line 2 for ${i}.”</p>`,
      `\n</blockquote>`,

      // Code block (escaped characters)
      `\n<codeblock>`,
      `\n<p>for (let k = 0; k < ${i % 7}; k++) { console.log(&quot;block_${i}&quot;); }</p>`,
      `\n</codeblock>`,

      // Image (self-closing)
      `\n<p><img src="https://picsum.photos/seed/${i}/${imgW}/${imgH}" width="${imgW}" height="${imgH}" /></p>`
    );
  }

  parts.push('\n</html>');
  return parts.join('');
};

const initialHugeHtml = generateHugeHtml();

export default function App() {
  const [isChannelPopupOpen, setIsChannelPopupOpen] = useState(false);
  const [isUserPopupOpen, setIsUserPopupOpen] = useState(false);
  const [isLinkModalOpen, setIsLinkModalOpen] = useState(false);
  const [isImageModalOpen, setIsImageModalOpen] = useState(false);
  const [isValueModalOpen, setIsValueModalOpen] = useState(false);
  const [currentHtml, setCurrentHtml] = useState('');

  const [selection, setSelection] = useState<Selection>();
  const [stylesState, setStylesState] = useState<StylesState>(DEFAULT_STYLE);
  const [currentLink, setCurrentLink] =
    useState<CurrentLinkState>(DEFAULT_LINK_STATE);
  const [visible, setVisible] = useState(false);

  const ref = useRef<EnrichedTextInputInstance>(null);

  const userMention = useUserMention();
  const channelMention = useChannelMention();

  const insideCurrentLink =
    stylesState.isLink &&
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
    setCurrentHtml(e.value);
  };

  const handleChangeState = (state: OnChangeStateEvent) => {
    setStylesState(state);
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

  const openValueModal = () => {
    setIsValueModalOpen(true);
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

  const handleLinkDetected = (state: CurrentLinkState) => {
    console.log(state);
    setCurrentLink(state);
  };

  const handleSelectionChangeEvent = (sel: OnChangeSelectionEvent) => {
    setSelection(sel);
  };

  return (
    <>
      <ScrollView
        style={styles.container}
        contentContainerStyle={styles.content}
      >
        <Button title="Set visible" onPress={() => setVisible(!visible)} />
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
        <View style={styles.buttonStack}>
          <Button title="Focus" onPress={handleFocus} style={styles.button} />
          <Button title="Blur" onPress={handleBlur} style={styles.button} />
        </View>
        <Button
          title="Set input's value"
          onPress={openValueModal}
          style={styles.valueButton}
        />
        <HtmlSection currentHtml={currentHtml} />
        {DEBUG_SCROLLABLE && <View style={styles.scrollPlaceholder} />}
      </ScrollView>
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
    backgroundColor: 'white',
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
  scrollPlaceholder: {
    marginTop: 24,
    width: '100%',
    height: 1000,
    backgroundColor: 'rgb(0, 26, 114)',
  },
});
