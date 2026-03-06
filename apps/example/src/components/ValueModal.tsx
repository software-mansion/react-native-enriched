import { type FC, useState } from 'react';
import { Keyboard, Pressable, StyleSheet, TextInput, View } from 'react-native';
import { Button } from './Button';
import { Icon } from './Icon';
import { ModalShell } from './ModalShell';

interface ValueModalProps {
  isOpen: boolean;
  avoidKeyboard?: boolean;
  onClose: () => void;
  onSubmit: (value: string) => void;
}

export const ValueModal: FC<ValueModalProps> = ({
  isOpen,
  avoidKeyboard,
  onClose,
  onSubmit,
}) => {
  const [value, setValue] = useState('');

  const handleSave = () => {
    Keyboard.dismiss();
    onSubmit(value);
  };

  return (
    <ModalShell isOpen={isOpen} avoidKeyboard={avoidKeyboard}>
      <View style={styles.modal}>
        <View style={styles.header}>
          <Pressable onPress={onClose} style={styles.closeButton}>
            <Icon name="close" color="rgb(0, 26, 114)" size={20} />
          </Pressable>
        </View>
        <View style={styles.content}>
          <TextInput
            multiline
            placeholder="New value"
            style={styles.input}
            onChangeText={setValue}
          />
          <Button
            testID="set-value-button"
            title="Set Value"
            onPress={handleSave}
            style={styles.saveButton}
          />
        </View>
      </View>
    </ModalShell>
  );
};

const styles = StyleSheet.create({
  modal: {
    width: 300,
    height: 400,
    backgroundColor: 'white',
    borderRadius: 8,
    padding: 16,
  },
  header: {
    width: '100%',
    alignItems: 'flex-end',
  },
  closeButton: {
    justifyContent: 'center',
    alignItems: 'center',
    width: 24,
    height: 24,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  input: {
    fontSize: 15,
    borderWidth: 1,
    borderColor: 'grey',
    borderRadius: 10,
    padding: 10,
    height: 240,
    width: '100%',
    marginVertical: 10,
  },
  saveButton: {
    width: '75%',
  },
});
