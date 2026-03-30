import { Platform } from 'react-native';
import {
  type EnrichedTextInputInstance,
  type OnChangeTextEvent,
  type OnLinkDetected,
  type OnChangeMentionEvent,
  type OnChangeHtmlEvent,
  type OnChangeStateEvent,
  type OnChangeSelectionEvent,
  type OnKeyPressEvent,
  type OnPasteImagesEvent,
  type OnSubmitEditing,
} from 'react-native-enriched';
import { useRef, useState } from 'react';
import { type MentionItem } from '../components/MentionPopup';
import { useUserMention } from './useUserMention';
import { useChannelMention } from './useChannelMention';
import {
  DEFAULT_LINK_STATE,
  DEFAULT_STYLES,
  type StylesState,
} from '../constants/editorConfig';
import {
  DEFAULT_IMAGE_HEIGHT,
  DEFAULT_IMAGE_WIDTH,
  prepareImageDimensions,
} from '../utils/prepareImageDimensions';
import { launchImageLibrary } from 'react-native-image-picker';

type CurrentLinkState = OnLinkDetected;

interface Selection {
  start: number;
  end: number;
  text: string;
}

export function useEditorState() {
  const ref = useRef<EnrichedTextInputInstance>(null);

  const [isChannelPopupOpen, setIsChannelPopupOpen] = useState(false);
  const [isUserPopupOpen, setIsUserPopupOpen] = useState(false);
  const [isLinkModalOpen, setIsLinkModalOpen] = useState(false);
  const [isImageModalOpen, setIsImageModalOpen] = useState(false);
  const [isValueModalOpen, setIsValueModalOpen] = useState(false);
  const [currentHtml, setCurrentHtml] = useState('');
  const [selection, setSelection] = useState<Selection>();
  const [stylesState, setStylesState] = useState<StylesState>(DEFAULT_STYLES);
  const [currentLink, setCurrentLink] =
    useState<CurrentLinkState>(DEFAULT_LINK_STATE);

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

  const handleClear = () => {
    ref.current?.setValue('');
  };

  const openLinkModal = () => setIsLinkModalOpen(true);
  const closeLinkModal = () => setIsLinkModalOpen(false);
  const openImageModal = () => setIsImageModalOpen(true);
  const closeImageModal = () => setIsImageModalOpen(false);
  const openValueModal = () => setIsValueModalOpen(true);
  const closeValueModal = () => setIsValueModalOpen(false);

  const openUserMentionPopup = () => setIsUserPopupOpen(true);
  const closeUserMentionPopup = () => {
    setIsUserPopupOpen(false);
    userMention.onMentionChange('');
  };

  const openChannelMentionPopup = () => setIsChannelPopupOpen(true);
  const closeChannelMentionPopup = () => {
    setIsChannelPopupOpen(false);
    channelMention.onMentionChange('');
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
    if (indicator === '@') {
      closeUserMentionPopup();
      userMention.onMentionChange('');
      return;
    }
    closeChannelMentionPopup();
    channelMention.onMentionChange('');
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
    console.log('Selection changed:', sel);
    setSelection(sel);
  };

  const handlePasteImagesEvent = (e: OnPasteImagesEvent) => {
    console.log('Pasted images:', e.images);
    e.images.forEach((image) => {
      const { finalWidth, finalHeight } = prepareImageDimensions(
        image.width,
        image.height
      );
      ref.current?.setImage(image.uri, finalWidth, finalHeight);
    });
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

    if (response?.assets?.[0] === undefined) return;

    const asset = response.assets[0];
    const imageUri = Platform.OS === 'android' ? asset.originalPath : asset.uri;

    if (imageUri) {
      const { finalWidth, finalHeight } = prepareImageDimensions(
        asset.width,
        asset.height,
        width,
        height
      );
      ref.current?.setImage(imageUri, finalWidth, finalHeight);
    }
  };

  const handleSubmitEditingEvent = (e: OnSubmitEditing) => {
    console.log('Submitted editing:', e.text);
  };

  const handleSetSelection = (start: number, end: number) => {
    ref.current?.setSelection(start, end);
  };

  return {
    ref,
    stylesState,
    currentHtml,
    selection,
    currentLink,
    insideCurrentLink,
    isLinkModalOpen,
    isImageModalOpen,
    isValueModalOpen,
    isUserPopupOpen,
    isChannelPopupOpen,
    userMention,
    channelMention,
    openLinkModal,
    closeLinkModal,
    openImageModal,
    closeImageModal,
    openValueModal,
    closeValueModal,
    handleFocus,
    handleBlur,
    handleClear,
    handleChangeText,
    handleChangeHtml,
    handleChangeState,
    handleLinkDetected,
    handleSelectionChangeEvent,
    handleKeyPress,
    handleFocusEvent,
    handleBlurEvent,
    handlePasteImagesEvent,
    handleStartMention,
    handleEndMention,
    handleChangeMention,
    handleUserMentionSelected,
    handleChannelMentionSelected,
    handleSubmitEditingEvent,
    submitLink,
    submitSetValue,
    selectImage,
    handleSetSelection,
  };
}
