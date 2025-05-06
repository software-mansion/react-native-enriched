import { type FC, useState } from 'react';
import { Modal, Pressable, StyleSheet, TextInput, View } from 'react-native';
import Icon from '@react-native-vector-icons/fontawesome';
import { Button } from './Button';

interface LinkModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (text: string, url: string) => void;
}

export const LinkModal: FC<LinkModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
}) => {
  const [text, setText] = useState('');
  const [url, setUrl] = useState('');

  const handleSave = () => {
    onSubmit(text, url);
  };

  return (
    <Modal
      visible={isOpen}
      animationType="slide"
      backdropColor="rgba(0, 0, 0, 0.5)"
    >
      <View style={styles.container}>
        <View style={styles.modal}>
          <View style={styles.header}>
            <Pressable onPress={onClose} style={styles.closeButton}>
              <Icon name="close" color="rgb(0, 26, 114)" size={20} />
            </Pressable>
          </View>
          <View style={styles.content}>
            <TextInput
              placeholder="Text"
              style={styles.input}
              onChangeText={setText}
            />
            <TextInput
              placeholder="Link"
              style={styles.input}
              onChangeText={setUrl}
            />
            <Button title="Save" onPress={handleSave} />
          </View>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  modal: {
    width: 300,
    height: 240,
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
    borderBottomWidth: 1,
    borderBottomColor: 'grey',
    width: '100%',
  },
});
