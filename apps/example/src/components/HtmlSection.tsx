import { useState } from 'react';
import { Button } from './Button';
import { StyleSheet, TextInput } from 'react-native';

interface HtmlSectionProps {
  currentHtml: string;
}

export const HtmlSection = ({ currentHtml }: HtmlSectionProps) => {
  const [showHtml, setShowHtml] = useState(false);

  return (
    <>
      <Button
        title={showHtml ? 'Hide HTML' : 'Show HTML'}
        onPress={() => setShowHtml((current) => !current)}
        style={styles.button}
      />
      {showHtml && (
        <TextInput
          multiline
          editable={false}
          style={styles.htmlText}
          value={currentHtml}
        />
      )}
    </>
  );
};

const styles = StyleSheet.create({
  htmlText: {
    marginTop: 24,
    width: '100%',
    maxHeight: 190,
    borderWidth: 1,
    borderRadius: 15,
    backgroundColor: 'gainsboro',
    padding: 10,
    alignSelf: 'flex-start',
    color: 'rgb(0, 0, 0, 0.8)',
    fontWeight: '500',
    fontSize: 16,
  },
  button: {
    width: '100%',
  },
});
