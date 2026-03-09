import { useState } from 'react';
import { View, StyleSheet, ScrollView } from 'react-native';
import { EnrichedTextInput } from 'react-native-enriched';
import { Button } from '../components/Button';
import { Toolbar } from '../components/Toolbar';
import { LinkModal } from '../components/LinkModal';
import { MentionPopup } from '../components/MentionPopup';
import { ImageModal } from '../components/ImageModal';
import { ValueModal } from '../components/ValueModal';
import { useEditorState } from '../hooks/useEditorState';
import {
  LINK_REGEX,
  htmlStyle,
  ANDROID_EXPERIMENTAL_SYNCHRONOUS_EVENTS,
} from '../constants/editorConfig';

interface TestScreenProps {
  onSwitch: () => void;
}

export function TestScreen({ onSwitch }: TestScreenProps) {
  const editor = useEditorState();
  const [sizeMode, setSizeMode] = useState<'base' | 'max'>('base');

  return (
    <>
      <ScrollView
        style={styles.container}
        contentContainerStyle={styles.content}
      >
        <View style={styles.buttonStack}>
          <Button
            title="Focus"
            onPress={editor.handleFocus}
            style={styles.button}
            testID="focus-button"
          />
          <Button
            title="Blur"
            onPress={editor.handleBlur}
            style={styles.button}
            testID="blur-button"
          />
          <Button
            title="Clear"
            onPress={editor.handleClear}
            style={styles.button}
            testID="clear-button"
          />
          <Button
            title={sizeMode === 'max' ? 'Max' : 'Base'}
            onPress={() => setSizeMode(sizeMode === 'max' ? 'base' : 'max')}
            style={styles.button}
            testID="size-max-button"
          />
        </View>
        <View style={styles.editor} testID="editor-container">
          <EnrichedTextInput
            ref={editor.ref}
            mentionIndicators={['@', '#']}
            style={
              sizeMode === 'max'
                ? { ...styles.editorInput, ...styles.editorInputMax }
                : styles.editorInput
            }
            htmlStyle={htmlStyle}
            placeholder="Type something here..."
            placeholderTextColor="rgb(0, 26, 114)"
            selectionColor="deepskyblue"
            cursorColor="dodgerblue"
            autoCapitalize="sentences"
            linkRegex={LINK_REGEX}
            onChangeText={(e) => editor.handleChangeText(e.nativeEvent)}
            onChangeHtml={(e) => editor.handleChangeHtml(e.nativeEvent)}
            onChangeState={(e) => editor.handleChangeState(e.nativeEvent)}
            onLinkDetected={editor.handleLinkDetected}
            onMentionDetected={console.log}
            onStartMention={editor.handleStartMention}
            onChangeMention={editor.handleChangeMention}
            onEndMention={editor.handleEndMention}
            onFocus={editor.handleFocusEvent}
            onBlur={editor.handleBlurEvent}
            onChangeSelection={(e) =>
              editor.handleSelectionChangeEvent(e.nativeEvent)
            }
            onKeyPress={(e) => editor.handleKeyPress(e.nativeEvent)}
            androidExperimentalSynchronousEvents={
              ANDROID_EXPERIMENTAL_SYNCHRONOUS_EVENTS
            }
            onPasteImages={(e) => editor.handlePasteImagesEvent(e.nativeEvent)}
            useHtmlNormalizer
            testID="editor-input"
          />
          <Toolbar
            stylesState={editor.stylesState}
            editorRef={editor.ref}
            onOpenLinkModal={editor.openLinkModal}
            onSelectImage={editor.openImageModal}
            layout="grid"
          />
        </View>
        <View style={styles.buttonRow}>
          <Button
            title="Set Value"
            onPress={editor.openValueModal}
            style={styles.rowButton}
            testID="set-value-button"
          />
          <Button
            title="Dev Screen"
            onPress={onSwitch}
            style={styles.rowButton}
            testID="toggle-screen-button"
          />
        </View>
      </ScrollView>
      <LinkModal
        avoidKeyboard
        isOpen={editor.isLinkModalOpen}
        editedText={
          editor.insideCurrentLink
            ? editor.currentLink.text
            : (editor.selection?.text ?? '')
        }
        editedUrl={editor.insideCurrentLink ? editor.currentLink.url : ''}
        onSubmit={editor.submitLink}
        onClose={editor.closeLinkModal}
      />
      <ImageModal
        avoidKeyboard
        isOpen={editor.isImageModalOpen}
        onSubmit={editor.selectImage}
        onClose={editor.closeImageModal}
      />
      <ValueModal
        avoidKeyboard
        isOpen={editor.isValueModalOpen}
        onSubmit={editor.submitSetValue}
        onClose={editor.closeValueModal}
      />
      <MentionPopup
        variant="user"
        data={editor.userMention.data}
        isOpen={editor.isUserPopupOpen}
        onItemPress={editor.handleUserMentionSelected}
      />
      <MentionPopup
        variant="channel"
        data={editor.channelMention.data}
        isOpen={editor.isChannelPopupOpen}
        onItemPress={editor.handleChannelMentionSelected}
      />
    </>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'white',
  },
  content: {
    flexGrow: 1,
    padding: 16,
    paddingTop: 100,
    alignItems: 'center',
  },
  editor: {
    width: '100%',
  },
  buttonStack: {
    flexDirection: 'row',
    alignItems: 'center',
    width: '100%',
    gap: 8,
  },
  button: {
    flex: 1,
  },
  buttonRow: {
    flexDirection: 'row',
    width: '100%',
    gap: 8,
  },
  rowButton: {
    flex: 1,
  },
  editorInput: {
    marginTop: 24,
    width: '100%',
    maxHeight: 180,
    backgroundColor: 'gainsboro',
    fontSize: 18,
    fontFamily: 'Nunito-Regular',
    paddingVertical: 12,
    paddingHorizontal: 14,
  },
  editorInputMax: {
    maxHeight: 400,
  },
});
