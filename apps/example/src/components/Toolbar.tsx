import { FlatList, type ListRenderItemInfo, StyleSheet } from 'react-native';
import { ToolbarButton } from './ToolbarButton';
import type {
  OnChangeStateEvent,
  EnrichedTextInputInstance,
} from 'react-native-enriched';
import type { FC } from 'react';

const STYLE_ITEMS = [
  {
    name: 'bold',
    icon: 'bold',
  },
  {
    name: 'italic',
    icon: 'italic',
  },
  {
    name: 'underline',
    icon: 'underline',
  },
  {
    name: 'strikethrough',
    icon: 'strikethrough',
  },
  {
    name: 'inline-code',
    icon: 'code',
  },
  {
    name: 'heading-1',
    text: 'H1',
  },
  {
    name: 'heading-2',
    text: 'H2',
  },
  {
    name: 'heading-3',
    text: 'H3',
  },
  {
    name: 'heading-4',
    text: 'H4',
  },
  {
    name: 'heading-5',
    text: 'H5',
  },
  {
    name: 'heading-6',
    text: 'H6',
  },
  {
    name: 'quote',
    icon: 'quote-right',
  },
  {
    name: 'code-block',
    icon: 'file-code-o',
  },
  {
    name: 'image',
    icon: 'image',
  },
  {
    name: 'link',
    icon: 'link',
  },
  {
    name: 'mention',
    icon: 'at',
  },
  {
    name: 'unordered-list',
    icon: 'list-ul',
  },
  {
    name: 'ordered-list',
    icon: 'list-ol',
  },
  {
    name: 'checkbox-list',
    icon: 'check-square-o',
  },
] as const;

type Item = (typeof STYLE_ITEMS)[number];
type StylesState = OnChangeStateEvent;

export interface ToolbarProps {
  stylesState: StylesState;
  editorRef?: React.RefObject<EnrichedTextInputInstance | null>;
  onOpenLinkModal: () => void;
  onSelectImage: () => void;
}

export const Toolbar: FC<ToolbarProps> = ({
  stylesState,
  editorRef,
  onOpenLinkModal,
  onSelectImage,
}) => {
  const handlePress = (item: Item) => {
    const currentRef = editorRef?.current;
    if (!currentRef) return;

    switch (item.name) {
      case 'bold':
        editorRef.current?.toggleBold();
        break;
      case 'italic':
        editorRef.current?.toggleItalic();
        break;
      case 'underline':
        editorRef.current?.toggleUnderline();
        break;
      case 'strikethrough':
        editorRef.current?.toggleStrikeThrough();
        break;
      case 'inline-code':
        editorRef?.current?.toggleInlineCode();
        break;
      case 'heading-1':
        editorRef.current?.toggleH1();
        break;
      case 'heading-2':
        editorRef.current?.toggleH2();
        break;
      case 'heading-3':
        editorRef.current?.toggleH3();
        break;
      case 'heading-4':
        editorRef.current?.toggleH4();
        break;
      case 'heading-5':
        editorRef.current?.toggleH5();
        break;
      case 'heading-6':
        editorRef.current?.toggleH6();
        break;
      case 'code-block':
        editorRef?.current?.toggleCodeBlock();
        break;
      case 'quote':
        editorRef?.current?.toggleBlockQuote();
        break;
      case 'unordered-list':
        editorRef.current?.toggleUnorderedList();
        break;
      case 'ordered-list':
        editorRef.current?.toggleOrderedList();
        break;
      case 'checkbox-list':
        // Make checkbox checked by default
        editorRef.current?.toggleCheckboxList(true);
        break;
      case 'link':
        onOpenLinkModal();
        break;
      case 'image':
        onSelectImage();
        break;
      case 'mention':
        editorRef.current?.startMention('@');
        break;
    }
  };

  const isDisabled = (item: Item) => {
    switch (item.name) {
      case 'bold':
        return stylesState.bold.isBlocking;
      case 'italic':
        return stylesState.italic.isBlocking;
      case 'underline':
        return stylesState.underline.isBlocking;
      case 'strikethrough':
        return stylesState.strikeThrough.isBlocking;
      case 'inline-code':
        return stylesState.inlineCode.isBlocking;
      case 'heading-1':
        return stylesState.h1.isBlocking;
      case 'heading-2':
        return stylesState.h2.isBlocking;
      case 'heading-3':
        return stylesState.h3.isBlocking;
      case 'heading-4':
        return stylesState.h4.isBlocking;
      case 'heading-5':
        return stylesState.h5.isBlocking;
      case 'heading-6':
        return stylesState.h6.isBlocking;
      case 'code-block':
        return stylesState.codeBlock.isBlocking;
      case 'quote':
        return stylesState.blockQuote.isBlocking;
      case 'unordered-list':
        return stylesState.unorderedList.isBlocking;
      case 'ordered-list':
        return stylesState.orderedList.isBlocking;
      case 'link':
        return stylesState.link.isBlocking;
      case 'image':
        return stylesState.image.isBlocking;
      case 'mention':
        return stylesState.mention.isBlocking;
      default:
        return false;
    }
  };

  const isActive = (item: Item) => {
    switch (item.name) {
      case 'bold':
        return stylesState.bold.isActive;
      case 'italic':
        return stylesState.italic.isActive;
      case 'underline':
        return stylesState.underline.isActive;
      case 'strikethrough':
        return stylesState.strikeThrough.isActive;
      case 'inline-code':
        return stylesState.inlineCode.isActive;
      case 'heading-1':
        return stylesState.h1.isActive;
      case 'heading-2':
        return stylesState.h2.isActive;
      case 'heading-3':
        return stylesState.h3.isActive;
      case 'heading-4':
        return stylesState.h4.isActive;
      case 'heading-5':
        return stylesState.h5.isActive;
      case 'heading-6':
        return stylesState.h6.isActive;
      case 'code-block':
        return stylesState.codeBlock.isActive;
      case 'quote':
        return stylesState.blockQuote.isActive;
      case 'unordered-list':
        return stylesState.unorderedList.isActive;
      case 'ordered-list':
        return stylesState.orderedList.isActive;
      case 'link':
        return stylesState.link.isActive;
      case 'image':
        return stylesState.image.isActive;
      case 'mention':
        return stylesState.mention.isActive;
      default:
        return false;
    }
  };

  const renderItem = ({ item }: ListRenderItemInfo<Item>) => {
    return (
      <ToolbarButton
        {...item}
        isActive={isActive(item)}
        isDisabled={isDisabled(item)}
        onPress={() => handlePress(item)}
      />
    );
  };

  const keyExtractor = (item: Item) => item.name;

  return (
    <FlatList
      horizontal
      data={STYLE_ITEMS}
      renderItem={renderItem}
      keyExtractor={keyExtractor}
      style={styles.container}
    />
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
});
