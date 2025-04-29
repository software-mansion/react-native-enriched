import { FlatList, type ListRenderItemInfo, StyleSheet } from 'react-native';
import { ToolbarButton } from './ToolbarButton';
import type { RichTextInputInstance } from '@swmansion/react-native-rich-text-editor';
import type { FC } from 'react';

// TODO: provide proper onPress handlers and isActive state
const STYLE_ITEMS = [
  {
    name: 'bold',
    icon: 'bold',
    isActive: false,
  },
  {
    name: 'italic',
    icon: 'italic',
    isActive: false,
  },
  {
    name: 'underline',
    icon: 'underline',
    isActive: false,
  },
  {
    name: 'strikethrough',
    icon: 'strikethrough',
    isActive: false,
  },
  {
    name: 'inline-code',
    icon: 'code',
    isActive: false,
  },
  {
    name: 'heading-1',
    text: 'H1',
    isActive: false,
  },
  {
    name: 'heading-2',
    text: 'H2',
    isActive: false,
  },
  {
    name: 'heading-3',
    text: 'H3',
    isActive: false,
  },
  {
    name: 'quote',
    icon: 'quote-right',
    isActive: false,
  },
  {
    name: 'code-block',
    icon: 'file-code-o',
    isActive: false,
  },
  {
    name: 'image',
    icon: 'image',
    isActive: false,
  },
  {
    name: 'link',
    icon: 'link',
    isActive: false,
  },
  {
    name: 'mention',
    icon: 'at',
    isActive: false,
  },
  {
    name: 'unordered-list',
    icon: 'list-ul',
    isActive: false,
  },
  {
    name: 'ordered-list',
    icon: 'list-ol',
    isActive: false,
  },
] as const;

type Item = (typeof STYLE_ITEMS)[number];

interface ToolbarProps {
  editorRef?: React.RefObject<RichTextInputInstance | null>;
}

export const Toolbar: FC<ToolbarProps> = ({ editorRef }) => {
  const handlePress = (item: Item) => {
    const currentRef = editorRef?.current;
    if (!currentRef) return;

    switch (item.name) {
      case 'bold':
        editorRef.current?.toggleBold();
        break;
      case 'italic':
        editorRef.current?.toggleItalic();
        break;
      case 'underline':
        editorRef.current?.toggleUnderline();
        break;
      case 'strikethrough':
        editorRef.current?.toggleStrikeThrough();
        break;
      default:
        console.warn('Unsupported action:', item.name);
    }
  };

  const renderItem = ({ item }: ListRenderItemInfo<Item>) => {
    return <ToolbarButton {...item} onPress={() => handlePress(item)} />;
  };

  const keyExtractor = (item: Item) => item.name;

  return (
    <FlatList
      horizontal
      data={STYLE_ITEMS}
      renderItem={renderItem}
      keyExtractor={keyExtractor}
      style={styles.container}
    />
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
});
