import { type FC } from 'react';
import {
  FlatList,
  Pressable,
  StyleSheet,
  Text,
  View,
  type ListRenderItemInfo,
} from 'react-native';
import type { MentionItem } from '../MentionPopup';

interface ChatMentionPopupProps {
  data: MentionItem[];
  isOpen: boolean;
  onItemPress: (item: MentionItem) => void;
}

const ROLE_BY_NAME: Record<string, string> = {
  'John Doe': 'Engineer',
  'Jane Smith': 'Designer',
  'Alice Johnson': 'Product Manager',
  'Bob Brown': 'Engineer',
};

const AVATAR_COLORS = ['#0a84ff', '#30d158', '#ff9f0a', '#ff375f'];

const getInitials = (name: string) => {
  return name
    .split(' ')
    .map((part) => part[0])
    .join('')
    .slice(0, 2)
    .toUpperCase();
};

export const ChatMentionPopup: FC<ChatMentionPopupProps> = ({
  data,
  isOpen,
  onItemPress,
}) => {
  if (!isOpen || data.length === 0) return null;

  const renderItem = ({ item, index }: ListRenderItemInfo<MentionItem>) => {
    const role = ROLE_BY_NAME[item.name] ?? 'Member';
    const initials = getInitials(item.name);
    const avatarColor = AVATAR_COLORS[index % AVATAR_COLORS.length];

    return (
      <Pressable
        style={({ pressed }) => [
          styles.itemRow,
          pressed && styles.itemRowPressed,
        ]}
        onPress={() => onItemPress(item)}
      >
        <View style={[styles.avatar, { backgroundColor: avatarColor }]}>
          <Text style={styles.avatarLabel}>{initials}</Text>
        </View>
        <View style={styles.textWrapper}>
          <Text style={styles.nameLabel}>{item.name}</Text>
          <Text style={styles.roleLabel}>{role}</Text>
        </View>
      </Pressable>
    );
  };

  return (
    <View style={styles.container}>
      <Text style={styles.sectionLabel}>PEOPLE</Text>
      <FlatList
        data={data}
        renderItem={renderItem}
        keyExtractor={(item) => item.id}
        overScrollMode="never"
        keyboardShouldPersistTaps="handled"
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: 'white',
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: '#d4d4d4',
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#d4d4d4',
    maxHeight: 360,
  },
  sectionLabel: {
    fontSize: 13,
    fontWeight: '700',
    letterSpacing: 1.2,
    color: '#8d8d93',
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 8,
  },
  itemRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: '#efefef',
  },
  itemRowPressed: {
    backgroundColor: '#f6f6f7',
  },
  avatar: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  avatarLabel: {
    color: 'white',
    fontSize: 16,
    fontWeight: '700',
  },
  textWrapper: {
    flex: 1,
  },
  nameLabel: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1a1a1a',
  },
  roleLabel: {
    fontSize: 15,
    color: '#9a9a9f',
    marginTop: 1,
  },
});
