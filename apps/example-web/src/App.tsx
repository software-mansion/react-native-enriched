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
  type OnPasteImagesEvent,
  type OnSubmitEditing,
  type OnChangeMentionEvent,
  type OnMentionDetected,
} from 'react-native-enriched';
import { WEB_DEFAULT_HTML_STYLE } from './defaultHtmlStyle';
import type { NativeSyntheticEvent } from 'react-native';
import { EditorActions } from './components/EditorActions';
import { SetValueModal } from './components/SetValueModal';
import { ImageModal } from './components/ImageModal';
import { LinkModal } from './components/LinkModal';
import { HtmlOutputPanel } from './components/HtmlOutputPanel';
import './App.css';
import { Toolbar } from './components/Toolbar';
import { MentionPopup, type MentionItem } from './components/MentionPopup';
import { useUserMention } from './hooks/useUserMention';
import { useChannelMention } from './hooks/useChannelMention';

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
  const [isChannelPopupOpen, setIsChannelPopupOpen] = useState(false);
  const [isUserPopupOpen, setIsUserPopupOpen] = useState(false);
  const [editorState, setEditorState] = useState<OnChangeStateEvent | null>(
    null
  );
  const [selection, setSelection] = useState<OnChangeSelectionEvent | null>(
    null
  );
  const [currentLink, setCurrentLink] =
    useState<OnLinkDetected>(DEFAULT_LINK_STATE);
  const [isLinkModalOpen, setIsLinkModalOpen] = useState(false);
  const [isImageModalOpen, setIsImageModalOpen] = useState(false);

  const isLinkActive = !!editorState?.link.isActive;
  const hasLinkUrl = currentLink.url.length > 0;
  const hasLinkSpan = currentLink.start !== 0 || currentLink.end !== 0;
  const selectionInsideLink =
    selection !== null &&
    selection.start >= currentLink.start &&
    selection.end <= currentLink.end;

  const insideCurrentLink =
    isLinkActive && hasLinkUrl && hasLinkSpan && selectionInsideLink;

  const userMention = useUserMention();
  const channelMention = useChannelMention();

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
    console.log('[EnrichedTextInput] Start mention', indicator);
    if (indicator === '@') {
      userMention.onMentionChange('');
      openUserMentionPopup();
      return;
    }
    channelMention.onMentionChange('');
    openChannelMentionPopup();
  };

  const handleEndMention = (indicator: string) => {
    console.log('[EnrichedTextInput] End mention', indicator);
    if (indicator === '@') {
      closeUserMentionPopup();
      userMention.onMentionChange('');
      return;
    }
    closeChannelMentionPopup();
    channelMention.onMentionChange('');
  };

  const handleChangeMention = ({ indicator, text }: OnChangeMentionEvent) => {
    console.log('[EnrichedTextInput] Change mention', indicator, text);
    if (indicator === '@') {
      userMention.onMentionChange(text);
      if (!isUserPopupOpen) setIsUserPopupOpen(true);
    } else {
      channelMention.onMentionChange(text);
      if (!isChannelPopupOpen) setIsChannelPopupOpen(true);
    }
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

  const mentionPopoverOpen =
    (isUserPopupOpen && userMention.data.length > 0) ||
    (isChannelPopupOpen && channelMention.data.length > 0);

  const handleOnMentionDetected = (e: OnMentionDetected) => {
    console.log('[EnrichedTextInput] onMentionDetected event', e);
  };

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

  const openImageModal = () => {
    setIsImageModalOpen(true);
  };

  const closeImageModal = () => {
    setIsImageModalOpen(false);
  };

  const submitImage = (url: string, width: number, height: number) => {
    ref.current?.setImage(url, width, height);
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

  const handleSubmitEditing = (e: NativeSyntheticEvent<OnSubmitEditing>) => {
    console.log('[EnrichedTextInput] onSubmitEditing event', e.nativeEvent);
  };

  const handleOnLinkDetected = (e: OnLinkDetected) => {
    console.log('[EnrichedTextInput] onLinkDetected event', e);
    setCurrentLink(e);
  };

  const handlePasteImages = (e: NativeSyntheticEvent<OnPasteImagesEvent>) => {
    const DEFAULT_W = 80;
    const DEFAULT_H = 80;
    for (const image of e.nativeEvent.images) {
      const w = image.width > 0 ? image.width : DEFAULT_W;
      const h = image.height > 0 ? image.height : DEFAULT_H;
      ref.current?.setImage(image.uri, w, h);
    }
  };

  return (
    <div className="container">
      <h1 className="app-title">Enriched Text Input</h1>

      <div
        className={
          mentionPopoverOpen
            ? 'editor-mention-host editor-mention-host--mention-open'
            : 'editor-mention-host'
        }
      >
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
          onSubmitEditing={handleSubmitEditing}
          onLinkDetected={handleOnLinkDetected}
          onPasteImages={handlePasteImages}
          onStartMention={handleStartMention}
          onChangeMention={handleChangeMention}
          onEndMention={handleEndMention}
          onMentionDetected={handleOnMentionDetected}
          mentionIndicators={['@', '#']}
          htmlStyle={WEB_DEFAULT_HTML_STYLE}
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
      </div>

      <Toolbar
        editorRef={ref}
        state={editorState}
        onOpenLinkModal={openLinkModal}
        onOpenImageModal={openImageModal}
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

      {isImageModalOpen && (
        <ImageModal onSubmit={submitImage} onClose={closeImageModal} />
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
