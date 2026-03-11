import { type FC, type ReactNode } from 'react';
import {
  KeyboardAvoidingView,
  Modal,
  Platform,
  StyleSheet,
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
  return (
    <Modal visible={isOpen} animationType="slide" transparent>
      <KeyboardAvoidingView
        style={styles.container}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        enabled={avoidKeyboard}
      >
        {children}
      </KeyboardAvoidingView>
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
