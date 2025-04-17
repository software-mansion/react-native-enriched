import { View, StyleSheet } from 'react-native';
import { ReactNativeRichTextEditorView } from '@swmansion/react-native-rich-text-editor';

export default function App() {
  return (
    <View style={styles.container}>
      <ReactNativeRichTextEditorView color="#32a852" style={styles.box} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
