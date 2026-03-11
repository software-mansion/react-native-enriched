import { View, StyleSheet, Text, ScrollView } from 'react-native';
import { EnrichedTextInput } from 'react-native-enriched';
import { Button } from '../components/Button';
import { Toolbar } from '../components/Toolbar';
import { LinkModal } from '../components/LinkModal';
import { ValueModal } from '../components/ValueModal';
import { MentionPopup } from '../components/MentionPopup';
import { HtmlSection } from '../components/HtmlSection';
import { ImageModal } from '../components/ImageModal';
import { useEditorState } from '../hooks/useEditorState';
import {
  LINK_REGEX,
  htmlStyle,
  ANDROID_EXPERIMENTAL_SYNCHRONOUS_EVENTS,
  DEBUG_SCROLLABLE,
} from '../constants/editorConfig';

interface DevScreenProps {
  onSwitch: () => void;
}

export function DevScreen({ onSwitch }: DevScreenProps) {
  const editor = useEditorState();

  return (
    <>
      <ScrollView
        style={styles.container}
        contentContainerStyle={styles.content}
      >
        <Text style={styles.label}>Enriched Text Input</Text>
        <View style={styles.editor} testID="editor-container">
          <EnrichedTextInput
            ref={editor.ref}
            mentionIndicators={['@', '#']}
            style={styles.editorInput}
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
            layout="horizontal"
          />
        </View>
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
        </View>
        <Button
          title="Set input's value"
          onPress={editor.openValueModal}
          style={styles.valueButton}
          testID="set-value-button"
        />
        <Button
          title="Test Screen"
          onPress={onSwitch}
          style={styles.valueButton}
          testID="toggle-screen-button"
        />
        <HtmlSection currentHtml={editor.currentHtml} />
        {DEBUG_SCROLLABLE && <View style={styles.scrollPlaceholder} />}
      </ScrollView>
      <LinkModal
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
        isOpen={editor.isImageModalOpen}
        onSubmit={editor.selectImage}
        onClose={editor.closeImageModal}
      />
      <ValueModal
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
  label: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    color: 'rgb(0, 26, 114)',
  },
  buttonStack: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    width: '100%',
  },
  button: {
    width: '45%',
  },
  valueButton: {
    width: '100%',
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
  scrollPlaceholder: {
    marginTop: 24,
    width: '100%',
    height: 1000,
    backgroundColor: 'rgb(0, 26, 114)',
  },
  alignmentLabel: {
    marginTop: 20,
    fontSize: 18,
    fontWeight: 'bold',
    textAlign: 'center',
    color: 'rgb(0, 26, 114)',
  },
  alignmentButton: {
    width: '25%',
  },
});
