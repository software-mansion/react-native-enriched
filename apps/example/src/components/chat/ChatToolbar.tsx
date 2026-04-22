import { type FC } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import type {
  EnrichedTextInputInstance,
  OnChangeStateEvent,
} from 'react-native-enriched';
import { Icon, type IconName } from '../Icon';

interface ToolItem {
  name:
    | 'bold'
    | 'italic'
    | 'underline'
    | 'unordered-list'
    | 'quote'
    | 'inline-code';
  icon: IconName;
}

const TOOL_ITEMS: ReadonlyArray<ToolItem> = [
  { name: 'bold', icon: 'bold' },
  { name: 'italic', icon: 'italic' },
  { name: 'underline', icon: 'underline' },
  { name: 'unordered-list', icon: 'list-ul' },
  { name: 'quote', icon: 'quote-right' },
  { name: 'inline-code', icon: 'code' },
];

export interface ChatToolbarProps {
  stylesState: OnChangeStateEvent;
  editorRef: React.RefObject<EnrichedTextInputInstance | null>;
}

export const ChatToolbar: FC<ChatToolbarProps> = ({
  stylesState,
  editorRef,
}) => {
  const handlePress = (name: ToolItem['name']) => {
    const editor = editorRef.current;
    if (!editor) return;

    switch (name) {
      case 'bold':
        editor.toggleBold();
        break;
      case 'italic':
        editor.toggleItalic();
        break;
      case 'underline':
        editor.toggleUnderline();
        break;
      case 'unordered-list':
        editor.toggleUnorderedList();
        break;
      case 'quote':
        editor.toggleBlockQuote();
        break;
      case 'inline-code':
        editor.toggleInlineCode();
        break;
    }
  };

  const getState = (name: ToolItem['name']) => {
    switch (name) {
      case 'bold':
        return stylesState.bold;
      case 'italic':
        return stylesState.italic;
      case 'underline':
        return stylesState.underline;
      case 'unordered-list':
        return stylesState.unorderedList;
      case 'quote':
        return stylesState.blockQuote;
      case 'inline-code':
        return stylesState.inlineCode;
    }
  };

  return (
    <View style={styles.container} testID="chat-toolbar">
      {TOOL_ITEMS.map((item) => {
        const state = getState(item.name);
        return (
          <Pressable
            key={item.name}
            onPress={() => handlePress(item.name)}
            disabled={state.isBlocking}
            hitSlop={6}
            style={({ pressed }) => [
              styles.button,
              state.isActive && styles.buttonActive,
              state.isBlocking && styles.buttonDisabled,
              pressed && styles.buttonPressed,
            ]}
            testID={`chat-toolbar-${item.name}`}
          >
            <Icon
              name={item.icon}
              size={18}
              color={state.isActive ? '#0a66ff' : '#333333'}
            />
          </Pressable>
        );
      })}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 8,
    paddingVertical: 6,
    backgroundColor: 'white',
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: '#e0e0e0',
  },
  button: {
    width: 36,
    height: 36,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 8,
    marginRight: 4,
  },
  buttonActive: {
    backgroundColor: 'rgba(10, 102, 255, 0.12)',
  },
  buttonPressed: {
    opacity: 0.6,
  },
  buttonDisabled: {
    opacity: 0.35,
  },
});
