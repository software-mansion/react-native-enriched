import { Alert, StyleSheet, View } from 'react-native';
import {
  EnrichedText,
  type OnLinkPressEvent,
  type OnMentionPressEvent,
} from 'react-native-enriched';
import { htmlStyle } from '../constants/htmlStyle';

interface TextRendererProps {
  nodes: Array<string>;
}

export const TextRenderer = ({ nodes }: TextRendererProps) => {
  const handleLinkPress = (e: OnLinkPressEvent) => {
    Alert.alert('Link Pressed', `You pressed the link: ${e.url}`);
  };

  const handleMentionPress = (e: OnMentionPressEvent) => {
    Alert.alert(
      'Mention Pressed',
      `You pressed the mention: text: ${e.text}, type: ${e.indicator}, attributes: ${JSON.stringify(e.attributes)}`
    );
  };

  if (nodes.length === 0) {
    return null;
  }

  return (
    <View style={styles.container}>
      {nodes.map((node, index) => (
        <EnrichedText
          key={index}
          style={styles.text}
          htmlStyle={htmlStyle}
          onLinkPress={handleLinkPress}
          onMentionPress={handleMentionPress}
        >
          {node}
        </EnrichedText>
      ))}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
    padding: 16,
    borderWidth: StyleSheet.hairlineWidth,
    marginVertical: 16,
    borderRadius: 8,
  },
  text: {
    fontSize: 16,
    color: 'black',
    marginTop: 4,
  },
});
