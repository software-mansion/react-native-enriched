import { useMemo, type FC } from 'react';
import { Pressable, StyleSheet, Text } from 'react-native';

interface ColorButtonProps {
  text: string;
  isActive: boolean;
  onPress: (color: string) => void;
  color: string;
}

export const ToolbarColorButton: FC<ColorButtonProps> = ({
  text,
  isActive,
  onPress,
  color,
}) => {
  const handlePress = () => {
    onPress(color);
  };

  const containerStyle = useMemo(
    () => [
      styles.container,
      { backgroundColor: isActive ? color : 'rgba(0, 26, 114, 0.8)' },
    ],
    [isActive, color]
  );

  return (
    <Pressable style={containerStyle} onPress={handlePress}>
      <Text style={[styles.text, !isActive && { color }]}>{text}</Text>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  container: {
    justifyContent: 'center',
    alignItems: 'center',
    width: 56,
    height: 56,
  },
  text: {
    color: 'white',
    fontSize: 20,
  },
});
