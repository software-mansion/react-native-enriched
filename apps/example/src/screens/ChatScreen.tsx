import { useCallback, useState } from 'react';
import {
  FlatList,
  KeyboardAvoidingView,
  Modal,
  Platform,
  Pressable,
  SafeAreaView,
  StyleSheet,
  Text,
  View,
  type ListRenderItemInfo,
} from 'react-native';
import type {
  OnLinkPressEvent,
  OnMentionPressEvent,
} from 'react-native-enriched';
import { ChatHeader } from '../components/chat/ChatHeader';
import { ChatInput } from '../components/chat/ChatInput';
import {
  MessageBubble,
  type MessageAuthor,
} from '../components/chat/MessageBubble';

interface ChatMessage {
  id: string;
  html: string;
  author: MessageAuthor;
  text: string;
}

const SEED_MESSAGES: ChatMessage[] = [
  {
    id: 'seed-1',
    author: 'them',
    html: 'Hey! How is the development coming along?',
    text: 'Hey! How is the development coming along?',
  },
];

interface ChatScreenProps {
  onBackPress?: () => void;
}

export function ChatScreen({ onBackPress }: ChatScreenProps) {
  const [messages, setMessages] = useState<ChatMessage[]>(SEED_MESSAGES);
  const [eventModal, setEventModal] = useState<{
    title: string;
    lines: string[];
  } | null>(null);

  const handleSend = useCallback((html: string, text: string) => {
    setMessages((prev) => [
      { id: `msg-${Date.now()}`, html, text, author: 'me' },
      ...prev,
    ]);
  }, []);

  const handleLinkPress = useCallback((e: OnLinkPressEvent) => {
    setEventModal({
      title: 'onLinkPress',
      lines: [],
    });
  }, []);

  const handleMentionPress = useCallback((e: OnMentionPressEvent) => {
    setEventModal({
      title: 'onMentionPress',
      lines: [],
    });
  }, []);

  const renderItem = useCallback(
    ({ item }: ListRenderItemInfo<ChatMessage>) => (
      <MessageBubble
        text={item.text}
        html={item.html}
        author={item.author}
        onLinkPress={handleLinkPress}
        onMentionPress={handleMentionPress}
      />
    ),
    [handleLinkPress, handleMentionPress]
  );

  const keyExtractor = useCallback((item: ChatMessage) => item.id, []);

  return (
    <KeyboardAvoidingView style={styles.flex} behavior={'padding'}>
      <ChatHeader onBackPress={onBackPress} />
      <FlatList
        style={styles.list}
        contentContainerStyle={styles.listContent}
        data={messages}
        renderItem={renderItem}
        keyExtractor={keyExtractor}
        inverted
        keyboardShouldPersistTaps="handled"
        testID="chat-messages-list"
      />
      <ChatInput onSend={handleSend} />
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: 'white',
    paddingVertical: 20,
    paddingBottom: 30,
  },
  flex: {
    flex: 1,
  },
  list: {
    flex: 1,
    backgroundColor: '#f6f6f6',
  },
  listContent: {
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.25)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  modalCard: {
    width: '100%',
    maxWidth: 360,
    backgroundColor: 'white',
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 14,
    shadowColor: 'black',
    shadowOpacity: 0.2,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 4 },
    elevation: 3,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#111',
    marginBottom: 8,
  },
  modalLine: {
    fontSize: 14,
    color: '#333',
    marginBottom: 6,
  },
  modalButton: {
    marginTop: 8,
    alignSelf: 'flex-end',
    backgroundColor: '#0a84ff',
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 8,
  },
  modalButtonLabel: {
    color: 'white',
    fontSize: 14,
    fontWeight: '600',
  },
});
