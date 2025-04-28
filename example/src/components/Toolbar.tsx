import { FlatList, type ListRenderItemInfo, StyleSheet } from 'react-native';
import { ToolbarButton } from './ToolbarButton';

// TODO: provide proper onPress handlers and isActive state
const STYLE_ITEMS = [
  {
    name: 'bold',
    icon: 'bold',
    isActive: false,
    onPress: () => {},
  },
  {
    name: 'italic',
    icon: 'italic',
    isActive: false,
    onPress: () => {},
  },
  {
    name: 'underline',
    icon: 'underline',
    isActive: false,
    onPress: () => {},
  },
  {
    name: 'strikethrough',
    icon: 'strikethrough',
    isActive: false,
    onPress: () => {},
  },
  {
    name: 'inline-code',
    icon: 'code',
    isActive: false,
    onPress: () => {},
  },
  {
    name: 'heading-1',
    text: 'H1',
    isActive: false,
    onPress: () => {},
  },
  {
    name: 'heading-2',
    text: 'H2',
    isActive: false,
    onPress: () => {},
  },
  {
    name: 'heading-3',
    text: 'H3',
    isActive: false,
    onPress: () => {},
  },
  {
    name: 'quote',
    icon: 'quote-right',
    isActive: false,
    onPress: () => {},
  },
  {
    name: 'code-block',
    icon: 'file-code-o',
    isActive: false,
    onPress: () => {},
  },
  {
    name: 'image',
    icon: 'image',
    isActive: false,
    onPress: () => {},
  },
  {
    name: 'link',
    icon: 'link',
    isActive: false,
    onPress: () => {},
  },
  {
    name: 'mention',
    icon: 'at',
    isActive: false,
    onPress: () => {},
  },
  {
    name: 'unordered-list',
    icon: 'list-ul',
    isActive: false,
    onPress: () => {},
  },
  {
    name: 'ordered-list',
    icon: 'list-ol',
    isActive: false,
    onPress: () => {},
  },
] as const;

type Item = (typeof STYLE_ITEMS)[number];

export const Toolbar = () => {
  const renderItem = ({ item }: ListRenderItemInfo<Item>) => {
    return <ToolbarButton {...item} />;
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
