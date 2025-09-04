import { useState } from 'react';
import { Button } from './Button';
import { ScrollView, StyleSheet, TextInput } from 'react-native';

interface HtmlSectionProps {
  currentHtml: string;
}

export const HtmlSection = ({ currentHtml }: HtmlSectionProps) => {
  const [showHtml, setShowHtml] = useState(false);
  const [htmlTextHeight, setHtmlTextHeight] = useState(0);

  const handleContentSizeChange = (
    _contentWidth: number,
    contentHeight: number
  ) => {
    setHtmlTextHeight(Math.min(contentHeight + 20, 190));
  };

  return (
    <>
      <Button
        title={showHtml ? 'Hide HTML' : 'Show HTML'}
        onPress={() => setShowHtml((current) => !current)}
        style={styles.button}
      />
      {showHtml && (
        <ScrollView
          style={[styles.htmlScroll, { maxHeight: htmlTextHeight }]}
          onContentSizeChange={handleContentSizeChange}
        >
          <TextInput
            multiline
            editable={false}
            style={styles.htmlText}
            value={currentHtml}
          />
        </ScrollView>
      )}
    </>
  );
};

const styles = StyleSheet.create({
  htmlScroll: {
    marginTop: 24,
    width: '100%',
    borderWidth: 1,
    borderRadius: 15,
    backgroundColor: 'gainsboro',
    padding: 10,
  },
  htmlText: {
    alignSelf: 'flex-start',
    color: 'rgb(0, 0, 0, 0.8)',
    fontWeight: '500',
    fontSize: 16,
  },
  button: {
    width: '100%',
  },
});
