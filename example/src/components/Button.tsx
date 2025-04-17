import { Pressable, StyleSheet, Text } from 'react-native';
import type { FC } from 'react';

interface ButtonProps {
  title: string;
  onPress: () => void;
}

export const Button: FC<ButtonProps> = ({ title, onPress }) => {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) =>
        pressed ? [styles.button, { opacity: 0.9 }] : styles.button
      }
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
    width: '100%',
    backgroundColor: 'rgb(0, 26, 114)',
    borderRadius: 8,
  },
  buttonLabel: {
    color: 'white',
    fontWeight: 'bold',
    fontSize: 16,
  },
});
