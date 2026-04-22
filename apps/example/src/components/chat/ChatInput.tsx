import { useRef, useState, type FC } from 'react';
import {
  Platform,
  Pressable,
  StyleSheet,
  View,
  type StyleProp,
  type ViewStyle,
} from 'react-native';
import {
  EnrichedTextInput,
  type EnrichedTextInputInstance,
  type OnChangeMentionEvent,
  type OnChangeStateEvent,
} from 'react-native-enriched';
import { launchImageLibrary } from 'react-native-image-picker';
import { Icon } from '../Icon';
import { type MentionItem } from '../MentionPopup';
import { useUserMention } from '../../hooks/useUserMention';
import { chatInputHtmlStyle } from '../../constants/chatHtmlStyle';
import { DEFAULT_STYLES } from '../../constants/editorConfig';
import { prepareImageDimensions } from '../../utils/prepareImageDimensions';
import { ChatToolbar } from './ChatToolbar';
import { ChatMentionPopup } from './ChatMentionPopup';

export interface ChatInputProps {
  onSend: (html: string, text: string) => void;
  style?: StyleProp<ViewStyle>;
}

export const ChatInput: FC<ChatInputProps> = ({ onSend, style }) => {
  const editorRef = useRef<EnrichedTextInputInstance>(null);
  const [stylesState, setStylesState] =
    useState<OnChangeStateEvent>(DEFAULT_STYLES);
  const [hasText, setHasText] = useState(false);
  const [isMentionPopupOpen, setIsMentionPopupOpen] = useState(false);
  const userMention = useUserMention();
  const [text, setText] = useState('');

  const handleChangeText = (value: string) => {
    setHasText(value.trim().length > 0);
    setText(value);
  };

  const handleStartMention = (indicator: string) => {
    if (indicator !== '@') return;
    userMention.onMentionChange('');
    setIsMentionPopupOpen(true);
  };

  const handleChangeMention = ({ indicator, text }: OnChangeMentionEvent) => {
    if (indicator !== '@') return;
    userMention.onMentionChange(text);
    if (!isMentionPopupOpen) setIsMentionPopupOpen(true);
  };

  const handleEndMention = (indicator: string) => {
    if (indicator !== '@') return;
    setIsMentionPopupOpen(false);
    userMention.onMentionChange('');
  };

  const handleMentionSelected = (item: MentionItem) => {
    editorRef.current?.setMention('@', `@${item.name}`, {
      id: item.id,
      type: 'user',
    });
  };

  const handlePickImage = async () => {
    const response = await launchImageLibrary({
      mediaType: 'photo',
      selectionLimit: 1,
    });

    const asset = response?.assets?.[0];
    if (!asset) return;

    const imageUri = Platform.OS === 'android' ? asset.originalPath : asset.uri;
    if (!imageUri) return;

    const { finalWidth, finalHeight } = prepareImageDimensions(
      asset.width,
      asset.height
    );
    editorRef.current?.setImage(imageUri, finalWidth, finalHeight);
  };

  const handleSend = async () => {
    const html = await editorRef.current?.getHTML();
    if (!html) return;
    onSend(html, text);
    editorRef.current?.setValue('');
    setHasText(false);
  };

  return (
    <View style={[styles.wrapper, style]}>
      <ChatToolbar stylesState={stylesState} editorRef={editorRef} />
      <View style={styles.inputRow}>
        <Pressable
          onPress={handlePickImage}
          hitSlop={8}
          style={styles.iconButton}
          testID="chat-attach-image"
        >
          <Icon name="picture-o" size={24} color="#0a84ff" />
        </Pressable>
        <View style={styles.editorWrapper}>
          <EnrichedTextInput
            ref={editorRef}
            mentionIndicators={['@']}
            style={styles.editor}
            htmlStyle={chatInputHtmlStyle}
            placeholder="Message..."
            placeholderTextColor="#888"
            selectionColor="#0a84ff"
            cursorColor="#0a84ff"
            autoCapitalize="sentences"
            onChangeText={(e) => handleChangeText(e.nativeEvent.value)}
            onChangeState={(e) => setStylesState(e.nativeEvent)}
            onStartMention={handleStartMention}
            onChangeMention={handleChangeMention}
            onEndMention={handleEndMention}
            useHtmlNormalizer
            testID="chat-editor-input"
          />
        </View>
        <Pressable
          onPress={handleSend}
          disabled={!hasText}
          hitSlop={8}
          style={[styles.iconButton, !hasText && styles.iconButtonDisabled]}
          testID="chat-send-button"
        >
          <Icon
            name="paper-plane"
            size={22}
            color={hasText ? '#0a84ff' : '#b0b0b0'}
          />
        </Pressable>
      </View>
      <View style={styles.popupWrapper} pointerEvents="box-none">
        <ChatMentionPopup
          data={userMention.data}
          isOpen={isMentionPopupOpen}
          onItemPress={handleMentionSelected}
        />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  wrapper: {
    backgroundColor: 'white',
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: '#d0d0d0',
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    paddingHorizontal: 8,
    paddingVertical: 6,
  },
  iconButton: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconButtonDisabled: {
    opacity: 0.8,
  },
  editorWrapper: {
    flex: 1,
    backgroundColor: '#f0f0f0',
    borderRadius: 20,
    paddingHorizontal: 12,
    paddingVertical: 4,
    marginHorizontal: 4,
    minHeight: 40,
    maxHeight: 190,
    justifyContent: 'center',
  },
  editor: {
    fontSize: 16,
    color: '#111',
    paddingVertical: 6,
  },
  popupWrapper: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: '100%',
  },
});
