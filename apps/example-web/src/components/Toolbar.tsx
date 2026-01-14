import {
  type EnrichedTextInputInstance,
  type OnChangeStateEvent,
} from 'react-native-enriched';
import './Toolbar.css';

const STYLE_ITEMS = [
  { name: 'bold', label: 'B' },
  { name: 'italic', label: 'I' },
  { name: 'underline', label: 'U' },
  { name: 'strikethrough', label: 'S' },
  { name: 'heading-1', label: 'H1' },
  { name: 'heading-2', label: 'H2' },
  { name: 'heading-3', label: 'H3' },
  { name: 'heading-4', label: 'H4' },
  { name: 'heading-5', label: 'H5' },
  { name: 'heading-6', label: 'H6' },
  { name: 'quote', label: 'Quote' },
  { name: 'code-block', label: 'Code' },
  { name: 'unordered-list', label: 'UL' },
  { name: 'ordered-list', label: 'OL' },
  { name: 'link', label: 'Link' },
  { name: 'image', label: 'Image' },
] as const;

type Item = (typeof STYLE_ITEMS)[number];
type StylesState = OnChangeStateEvent;

export interface ToolbarProps {
  stylesState: StylesState;
  editorRef?: React.RefObject<EnrichedTextInputInstance | null>;
  onOpenLinkModal: () => void;
  onSelectImage: () => void;
}

export const Toolbar: React.FC<ToolbarProps> = ({
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
        currentRef.toggleBold();
        break;
      case 'italic':
        currentRef.toggleItalic();
        break;
      case 'underline':
        currentRef.toggleUnderline();
        break;
      case 'strikethrough':
        currentRef.toggleStrikeThrough();
        break;
      case 'heading-1':
        currentRef.toggleH1();
        break;
      case 'heading-2':
        currentRef.toggleH2();
        break;
      case 'heading-3':
        currentRef.toggleH3();
        break;
      case 'heading-4':
        currentRef.toggleH4();
        break;
      case 'heading-5':
        currentRef.toggleH5();
        break;
      case 'heading-6':
        currentRef.toggleH6();
        break;
      case 'code-block':
        currentRef.toggleCodeBlock();
        break;
      case 'quote':
        currentRef.toggleBlockQuote();
        break;
      case 'unordered-list':
        currentRef.toggleUnorderedList();
        break;
      case 'ordered-list':
        currentRef.toggleOrderedList();
        break;
      case 'link':
        onOpenLinkModal();
        break;
      case 'image':
        onSelectImage();
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
      default:
        return false;
    }
  };

  return (
    <div className="toolbar">
      {STYLE_ITEMS.map((item) => (
        <button
          key={item.name}
          className={`toolbar-button ${isActive(item) ? 'active' : ''}`}
          disabled={isDisabled(item)}
          onClick={() => {
            handlePress(item);
          }}
          title={item.label}
        >
          {item.label}
        </button>
      ))}
    </div>
  );
};
