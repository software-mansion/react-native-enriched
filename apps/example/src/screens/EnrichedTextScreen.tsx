import { useState } from 'react';
import { View, StyleSheet, ScrollView } from 'react-native';
import {
  EnrichedText,
  type OnLinkPressEvent,
  type OnMentionPressEvent,
} from 'react-native-enriched';
import { Button } from '../components/Button';
import { ValueModal } from '../components/ValueModal';
import { enrichedTextHtmlStyle } from '../constants/editorConfig';

interface EnrichedTextScreenProps {
  onSwitch: () => void;
}

export function EnrichedTextScreen({ onSwitch }: EnrichedTextScreenProps) {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [html, setHtml] = useState<string | null>(null);

  const handleSubmit = (value: string) => {
    setHtml(value);
    setIsModalOpen(false);
  };

  const handleLinkPress = (e: OnLinkPressEvent) => {
    setHtml(`You pressed the link: ${e.url}`);
  };

  const handleMentionPress = (e: OnMentionPressEvent) => {
    setHtml(
      `You pressed the mention: text: ${e.text}, type: ${e.indicator}, attributes: ${JSON.stringify(e.attributes)}`
    );
  };

  return (
    <>
      <ScrollView
        style={styles.container}
        contentContainerStyle={styles.content}
      >
        <View style={styles.buttonRow}>
          <Button
            title="Test Screen"
            onPress={onSwitch}
            style={styles.rowButton}
            testID="toggle-screen-button"
          />
          <Button
            title="Set Text"
            onPress={() => setIsModalOpen(true)}
            style={styles.rowButton}
            testID="set-enriched-text-button"
          />
        </View>
        {html !== null && (
          <View style={styles.rendererContainer} testID="enriched-text">
            <EnrichedText
              style={styles.text}
              htmlStyle={enrichedTextHtmlStyle}
              onLinkPress={handleLinkPress}
              onMentionPress={handleMentionPress}
              useHtmlNormalizer
            >
              {html}
            </EnrichedText>
          </View>
        )}
      </ScrollView>
      <ValueModal
        avoidKeyboard
        isOpen={isModalOpen}
        onSubmit={handleSubmit}
        onClose={() => setIsModalOpen(false)}
      />
    </>
  );
}

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
  buttonRow: {
    flexDirection: 'row',
    width: '100%',
    gap: 8,
  },
  rowButton: {
    flex: 1,
  },
  rendererContainer: {
    width: '100%',
    padding: 16,
    borderWidth: StyleSheet.hairlineWidth,
    marginVertical: 16,
    borderRadius: 8,
  },
  text: {
    fontSize: 18,
    color: 'black',
    fontFamily: 'Nunito-Regular',
  },
});
