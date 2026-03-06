import { type FC, useEffect, useState } from 'react';
import { Pressable, StyleSheet, TextInput, View } from 'react-native';
import { Button } from './Button';
import { Icon } from './Icon';
import { ModalShell } from './ModalShell';

interface LinkModalProps {
  isOpen: boolean;
  avoidKeyboard?: boolean;
  editedText: string;
  editedUrl: string;
  onClose: () => void;
  onSubmit: (text: string, url: string) => void;
}

export const LinkModal: FC<LinkModalProps> = ({
  isOpen,
  avoidKeyboard,
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
    <ModalShell isOpen={isOpen} avoidKeyboard={avoidKeyboard}>
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
            autoCapitalize="none"
            autoCorrect={false}
          />
          <TextInput
            placeholder="Link"
            defaultValue={editedUrl}
            style={styles.input}
            onChangeText={setUrl}
            autoCapitalize="none"
            autoCorrect={false}
          />
          <Button
            title="Save"
            onPress={handleSave}
            disabled={url.length === 0}
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
