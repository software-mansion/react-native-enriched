import type { FC } from 'react';
import {
  FlatList,
  type ListRenderItemInfo,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { Icon } from './Icon';
import type { MentionData, MentionItem } from '../useMention';

interface MentionPopupProps {
  data: MentionData;
  isOpen: boolean;
  onItemPress: (item: MentionItem) => void;
}

export const MentionPopup: FC<MentionPopupProps> = ({
  data,
  isOpen,
  onItemPress,
}) => {
  if (!isOpen || !data.length) return null;

  const renderItem = ({ item }: ListRenderItemInfo<MentionItem>) => (
    <Pressable
      style={({ pressed }) => [
        styles.itemContainer,
        pressed && styles.itemContainerPressed,
      ]}
      onPress={() => onItemPress(item)}
    >
      <View style={styles.avatar}>
        <Icon name="user" color="grey" size={24} />
      </View>
      <Text style={styles.itemLabel}>{item.name}</Text>
    </Pressable>
  );

  return (
    <View style={styles.container}>
      <FlatList
        overScrollMode="never"
        data={data}
        style={styles.scrollView}
        renderItem={renderItem}
        contentContainerStyle={styles.content}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    width: '100%',
    zIndex: 1,
    // padding: 16,
    bottom: 0,
  },
  scrollView: {
    flex: 1,
    borderRadius: 8,
    maxHeight: 120,
    borderWidth: 1,
    borderColor: 'grey',
    backgroundColor: 'white',
  },
  content: {
    flexGrow: 1,
    paddingVertical: 16,
  },
  itemContainer: {
    paddingVertical: 8,
    paddingHorizontal: 16,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  itemContainerPressed: {
    backgroundColor: 'rgba(0, 26, 114, 0.1)',
  },
  itemLabel: {
    fontSize: 16,
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    marginRight: 8,
    backgroundColor: 'gainsboro',
    justifyContent: 'center',
    alignItems: 'center',
  },
});
