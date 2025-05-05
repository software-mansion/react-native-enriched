import {
  View,
  StyleSheet,
  Text,
  type NativeSyntheticEvent,
  TextInput,
} from 'react-native';
import {
  RichTextInput,
  type OnChangeTextEvent,
  type OnChangeStyleEvent,
  type RichTextInputInstance,
} from '@swmansion/react-native-rich-text-editor';
import { useRef, useState } from 'react';
import { Button } from './components/Button';
import { Toolbar } from './components/Toolbar';

type StylesState = OnChangeStyleEvent;

const DEFAULT_VALUE = 'This is fully native Rich Text Editor component';
const DEFAULT_STYLE: StylesState = {
  isBold: false,
  isItalic: false,
  isUnderline: false,
  isStrikeThrough: false,
  isH1: false,
  isH2: false,
  isH3: false,
  isBlockQuote: false,
  isCodeBlock: false,
};

export default function App() {
  const [defaultValue, setDefaultValue] = useState(DEFAULT_VALUE);
  const [stylesState, setStylesState] = useState<StylesState>(DEFAULT_STYLE);
  const ref = useRef<RichTextInputInstance>(null);

  const handleChangeText = (e: NativeSyntheticEvent<OnChangeTextEvent>) => {
    console.log('Text changed:', e?.nativeEvent.value);
  };

  const handleChangeStyle = (e: NativeSyntheticEvent<OnChangeStyleEvent>) => {
    setStylesState(e.nativeEvent);
  };

  const handleFocus = () => {
    ref.current?.focus();
  };

  const handleBlur = () => {
    ref.current?.blur();
  };

  const toggleDefaultValue = () => {
    setDefaultValue((prev) => (prev === DEFAULT_VALUE ? '' : DEFAULT_VALUE));
  };

  return (
    <View style={styles.container}>
      <Text style={styles.label}>SWM Rich Text Editor</Text>
      <View style={styles.editor}>
        <RichTextInput
          ref={ref}
          style={styles.input}
          defaultValue={defaultValue}
          onChangeText={handleChangeText}
          onChangeStyle={handleChangeStyle}
        />
        <Toolbar stylesState={stylesState} editorRef={ref} />
      </View>
      <TextInput multiline defaultValue={defaultValue} style={styles.input} />
      <Button title="Focus" onPress={handleFocus} />
      <Button title="Blur" onPress={handleBlur} />
      <Button title="Toggle Default Value" onPress={toggleDefaultValue} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 16,
  },
  editor: {
    width: '100%',
  },
  label: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    color: 'rgb(0, 26, 114)',
  },
  input: {
    marginTop: 24,
    width: '100%',
    maxHeight: 120,
    backgroundColor: 'gainsboro',
    fontSize: 18,
    paddingVertical: 12,
    paddingHorizontal: 14,
  },
});
