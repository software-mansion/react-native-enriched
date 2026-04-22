import { type FC } from 'react';
import {
  Image,
  Pressable,
  StyleSheet,
  Text,
  View,
  type StyleProp,
  type ViewStyle,
} from 'react-native';
import { Icon } from '../Icon';

export interface ChatHeaderProps {
  name?: string;
  avatarUri?: string;
  isOnline?: boolean;
  onBackPress?: () => void;
  style?: StyleProp<ViewStyle>;
}

const DEFAULT_AVATAR = 'https://i.pravatar.cc/120?img=12';

export const ChatHeader: FC<ChatHeaderProps> = ({
  name = 'John Doe',
  avatarUri = DEFAULT_AVATAR,
  isOnline = true,
  onBackPress,
  style,
}) => {
  return (
    <View style={[styles.container, style]}>
      <Pressable
        onPress={onBackPress}
        hitSlop={12}
        style={styles.backButton}
        testID="chat-back-button"
      >
        <Icon name="angle-left" size={28} color="#0a66ff" />
      </Pressable>
      <View style={styles.avatarWrapper}>
        <Image source={{ uri: avatarUri }} style={styles.avatar} />
        {isOnline && <View style={styles.onlineDot} />}
      </View>
      <View style={styles.textWrapper}>
        <Text style={styles.name} numberOfLines={1}>
          {name}
        </Text>
        <Text style={styles.status} numberOfLines={1}>
          {isOnline ? 'Online' : 'Offline'}
        </Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 10,
    backgroundColor: 'white',
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#d0d0d0',
  },
  backButton: {
    width: 32,
    height: 32,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 6,
  },
  avatarWrapper: {
    width: 40,
    height: 40,
    marginRight: 10,
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#e0e0e0',
  },
  onlineDot: {
    position: 'absolute',
    right: 0,
    bottom: 0,
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: '#2ecc71',
    borderWidth: 2,
    borderColor: 'white',
  },
  textWrapper: {
    flex: 1,
    justifyContent: 'center',
  },
  name: {
    fontSize: 16,
    fontWeight: '700',
    color: '#111',
  },
  status: {
    fontSize: 12,
    color: '#777',
    marginTop: 1,
  },
});
