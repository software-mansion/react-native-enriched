import { Pressable, StyleSheet, Text } from 'react-native';
import type { FC } from 'react';
import type { StyleProp, ViewStyle } from 'react-native';

interface ButtonProps {
  title: string;
  onPress: () => void;
  disabled?: boolean;
  style?: StyleProp<ViewStyle>;
  testID?: string;
}

export const Button: FC<ButtonProps> = ({
  title,
  onPress,
  disabled = false,
  style = {},
  testID,
}) => {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.button,
        pressed && styles.pressed,
        disabled && styles.disabled,
        style,
      ]}
      disabled={disabled}
      testID={testID}
    >
      <Text style={styles.buttonLabel}>{title}</Text>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  button: {
    padding: 16,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 24,
    backgroundColor: 'rgb(0, 26, 114)',
    borderRadius: 8,
  },
  buttonLabel: {
    color: 'white',
    fontWeight: 'bold',
    fontSize: 16,
  },
  disabled: {
    backgroundColor: 'darkgray',
  },
  pressed: {
    opacity: 0.9,
  },
});
