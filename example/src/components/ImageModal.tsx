import { type FC, useState } from 'react';
import { Modal, Pressable, StyleSheet, TextInput, View } from 'react-native';
import { Button } from './Button';
import { Icon } from './Icon';

interface ImageModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (
    width: number | undefined,
    height: number | undefined,
    url?: string
  ) => void;
}

export const ImageModal: FC<ImageModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
}) => {
  const [width, setWidth] = useState('');
  const [height, setHeight] = useState('');
  const [url, setUrl] = useState('');

  const handleSave = () => {
    const parsedWidth = parseFloat(width);
    const parsedHeight = parseFloat(height);
    const finalWidth = isNaN(parsedWidth) ? undefined : parsedWidth;
    const finalHeight = isNaN(parsedHeight) ? undefined : parsedHeight;

    onSubmit(finalWidth, finalHeight, url.trim() === '' ? undefined : url);
    onClose();
    resetState();
  };

  const closeModal = () => {
    onClose();
    resetState();
  };

  const resetState = () => {
    setWidth('');
    setHeight('');
    setUrl('');
  };

  return (
    <Modal visible={isOpen} animationType="slide" transparent>
      <View style={styles.container}>
        <View style={styles.modal}>
          <View style={styles.header}>
            <Pressable onPress={closeModal} style={styles.closeButton}>
              <Icon name="close" color="rgb(0, 26, 114)" size={20} />
            </Pressable>
          </View>
          <View style={styles.content}>
            <TextInput
              placeholder="Width"
              style={styles.input}
              value={width}
              onChangeText={setWidth}
            />
            <TextInput
              placeholder="Height"
              style={styles.input}
              value={height}
              onChangeText={setHeight}
            />
            <TextInput
              placeholder="Remote URL"
              style={styles.input}
              value={url}
              onChangeText={setUrl}
            />
            <Button
              title="Choose Image"
              onPress={handleSave}
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
    height: 320,
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
