import { type FC, useEffect, useState } from 'react';
import { Modal, Pressable, StyleSheet, TextInput, View } from 'react-native';
import { Button } from './Button';
import { Icon } from './Icon';

interface LinkModalProps {
  isOpen: boolean;
  editedText: string;
  editedUrl: string;
  onClose: () => void;
  onSubmit: (text: string, url: string) => void;
}

export const LinkModal: FC<LinkModalProps> = ({
  isOpen,
  editedText,
  editedUrl,
  onClose,
  onSubmit,
}) => {
  const [text, setText] = useState('');
  const [url, setUrl] = useState('');

  useEffect(() => {
    setText(editedText);
    setUrl(editedUrl);
  }, [editedText, editedUrl]);

  const handleSave = () => {
    onSubmit(text, url);
  };

  return (
    <Modal visible={isOpen} animationType="slide" transparent>
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
              defaultValue={editedText}
              style={styles.input}
              onChangeText={setText}
            />
            <TextInput
              placeholder="Link"
              defaultValue={editedUrl}
              style={styles.input}
              onChangeText={setUrl}
            />
            <Button
              title="Save"
              onPress={handleSave}
              disabled={url.length === 0}
              style={styles.saveButton}
            />
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
    backgroundColor: 'rgb(0, 0, 0, 0.5)',
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
    fontSize: 15,
    borderBottomWidth: 1,
    borderBottomColor: 'grey',
    width: '100%',
    marginVertical: 10,
  },
  saveButton: {
    width: '75%',
  },
});
