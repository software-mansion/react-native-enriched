import { type FC } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import {
  incomingHtmlStyle,
  outgoingHtmlStyle,
} from '../../constants/chatHtmlStyle';
import { EnrichedText } from 'react-native-enriched';

export type MessageAuthor = 'me' | 'them';

export interface MessageBubbleProps {
  text: string;
  html: string;
  author: MessageAuthor;
}

export function MessageBubble({ text, author, html }: MessageBubbleProps) {
  const { viewStyle, bubbleStyle, textStyle, htmlStyle } = getViewStyle(author);

  return (
    <View style={viewStyle}>
      <View style={bubbleStyle}>
        <EnrichedText style={textStyle} htmlStyle={htmlStyle}>
          {html}
        </EnrichedText>
      </View>
    </View>
  );
}

const getViewStyle = (author: MessageAuthor) => {
  const isMe = author === 'me';
  const viewStyle = [styles.row, isMe ? styles.rowMe : styles.rowThem];
  const bubbleStyle = [
    styles.bubble,
    isMe ? styles.bubbleMe : styles.bubbleThem,
  ];
  const textStyle = {
    ...styles.text,
    ...(isMe ? styles.textMe : styles.textThem),
  };
  const htmlStyle = isMe ? outgoingHtmlStyle : incomingHtmlStyle;
  return { viewStyle, bubbleStyle, textStyle, htmlStyle };
};

const styles = StyleSheet.create({
  row: {
    width: '100%',
    flexDirection: 'row',
    marginVertical: 3,
  },
  rowMe: {
    justifyContent: 'flex-end',
  },
  rowThem: {
    justifyContent: 'flex-start',
  },
  bubble: {
    maxWidth: '78%',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 18,
  },
  bubbleMe: {
    backgroundColor: '#0a84ff',
    borderBottomRightRadius: 6,
  },
  bubbleThem: {
    backgroundColor: '#e9e9eb',
    borderBottomLeftRadius: 6,
  },
  text: {
    fontSize: 16,
  },
  textMe: {
    color: '#ffffff',
  },
  textThem: {
    color: '#111111',
  },
});
