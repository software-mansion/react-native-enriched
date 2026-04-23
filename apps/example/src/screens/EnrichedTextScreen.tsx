import { useState } from 'react';
import { View, StyleSheet, ScrollView, Text } from 'react-native';
import {
  EnrichedText,
  type OnLinkPressEvent,
  type OnMentionPressEvent,
} from 'react-native-enriched';
import { Button } from '../components/Button';
import { ValueModal } from '../components/ValueModal';
import { enrichedTextHtmlStyle } from '../constants/htmlStyle';

type EllipsizeMode = EnrichedTextProps['ellipsizeMode']

interface EnrichedTextScreenProps {
  onSwitch: () => void;
}

export function EnrichedTextScreen({ onSwitch }: EnrichedTextScreenProps) {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [html, setHtml] = useState<string | null>(null);
  const [ellipsizeMode, setEllipsizeMode] = useState<EllipsizeMode>('tail');
  const [numberOfLines, setNumberOfLines] = useState<number>(0);

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
        <View style={styles.sectionContainer}>
          <Text style={styles.sectionTitle} testID="ellipsize-current-mode">
            ellipsizeMode: {ellipsizeMode}
          </Text>
          <View style={styles.buttonRow}>
            <Button
              title="Head"
              onPress={() => setEllipsizeMode('head')}
              style={styles.rowButton}
              testID="ellipsize-head-button"
            />
            <Button
              title="Middle"
              onPress={() => setEllipsizeMode('middle')}
              style={styles.rowButton}
              testID="ellipsize-middle-button"
            />
            <Button
              title="Tail"
              onPress={() => setEllipsizeMode('tail')}
              style={styles.rowButton}
              testID="ellipsize-tail-button"
            />
          </View>
        </View>
        <View style={styles.sectionContainer}>
          <Text style={styles.sectionTitle} testID="number-of-lines-current">
            numberOfLines: {numberOfLines === 0 ? 'unset' : numberOfLines}
          </Text>
          <View style={styles.buttonRow}>
            <Button
              title="All"
              onPress={() => setNumberOfLines(0)}
              style={styles.rowButton}
              testID="number-of-lines-all-button"
            />
            <Button
              title="1"
              onPress={() => setNumberOfLines(1)}
              style={styles.rowButton}
              testID="number-of-lines-1-button"
            />
            <Button
              title="2"
              onPress={() => setNumberOfLines(2)}
              style={styles.rowButton}
              testID="number-of-lines-2-button"
            />
          </View>
        </View>
        {html !== null && (
          <View style={styles.rendererContainer} testID="enriched-text">
            <EnrichedText
              style={styles.text}
              htmlStyle={enrichedTextHtmlStyle}
              numberOfLines={numberOfLines}
              ellipsizeMode={ellipsizeMode}
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
    paddingTop: 50,
    alignItems: 'center',
  },
  buttonRow: {
    flexDirection: 'row',
    width: '100%',
    gap: 8,
  },
  sectionContainer: {
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: 'gray',
    borderRadius: 8,
    padding: 16,
    marginTop: 8,
  },
  sectionTitle: {
    alignSelf: 'flex-start',
    fontSize: 20,
    fontWeight: '600',
    color: 'black',
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
