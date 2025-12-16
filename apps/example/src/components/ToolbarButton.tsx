import { type FC } from 'react';
import { Pressable, StyleSheet, Text } from 'react-native';
import { Icon, type IconName } from './Icon';

interface ToolbarButtonIconProps {
  text?: never;
  icon: IconName;
  isActive: boolean;
  onPress: () => void;
}

interface ToolbarButtonTextProps {
  text: string;
  icon?: never;
  isActive: boolean;
  onPress: () => void;
}

export type ToolbarButtonProps =
  | ToolbarButtonIconProps
  | ToolbarButtonTextProps;

export const ToolbarButton: FC<ToolbarButtonProps> = ({
  icon,
  text,
  isActive,
  onPress,
}) => {
  return (
    <Pressable
      style={[styles.container, isActive && styles.containerActive]}
      onPress={onPress}
    >
      {icon ? (
        <Icon name={icon} size={20} color="white" />
      ) : (
        <Text style={styles.text}>{text}</Text>
      )}
    </Pressable>
  );
};

const styles = StyleSheet.create({
  container: {
    justifyContent: 'center',
    alignItems: 'center',
    width: 56,
    height: 56,
    backgroundColor: 'rgba(0, 26, 114, 0.8)',
  },
  containerActive: {
    backgroundColor: 'rgb(0, 26, 114)',
  },
  text: {
    color: 'white',
    fontSize: 20,
  },
});
