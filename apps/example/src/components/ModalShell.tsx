import { type FC, type ReactNode } from 'react';
import {
  KeyboardAvoidingView,
  Modal,
  Platform,
  StyleSheet,
  View,
} from 'react-native';

interface ModalShellProps {
  isOpen: boolean;
  avoidKeyboard?: boolean;
  children: ReactNode;
}

export const ModalShell: FC<ModalShellProps> = ({
  isOpen,
  avoidKeyboard = false,
  children,
}) => {
  const inner = avoidKeyboard ? (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      {children}
    </KeyboardAvoidingView>
  ) : (
    <View style={styles.container}>{children}</View>
  );

  return (
    <Modal visible={isOpen} animationType="slide" transparent>
      {inner}
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
});
