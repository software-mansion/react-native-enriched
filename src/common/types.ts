// Re-export event types from the NativeComponent spec file (source of truth for Codegen)
export type {
  OnChangeTextEvent,
  OnChangeHtmlEvent,
  OnChangeStateEvent,
  OnChangeStateDeprecatedEvent,
  OnKeyPressEvent,
} from '../spec/EnrichedTextInputNativeComponent';

export interface OnMentionDetected {
  text: string;
  indicator: string;
  attributes: Record<string, string>;
}

export interface OnLinkDetected {
  text: string;
  url: string;
  start: number;
  end: number;
}

export interface OnChangeSelectionEvent {
  start: number;
  end: number;
  text: string;
}

export interface OnChangeMentionEvent {
  indicator: string;
  text: string;
}

export interface EnrichedTextInputInstanceBase {
  // General commands
  focus: () => void;
  blur: () => void;
  setValue: (value: string) => void;
  setSelection: (start: number, end: number) => void;
  getHTML: () => Promise<string>;

  // Text formatting commands
  toggleBold: () => void;
  toggleItalic: () => void;
  toggleUnderline: () => void;
  toggleStrikeThrough: () => void;
  toggleInlineCode: () => void;
  toggleH1: () => void;
  toggleH2: () => void;
  toggleH3: () => void;
  toggleH4: () => void;
  toggleH5: () => void;
  toggleH6: () => void;
  toggleCodeBlock: () => void;
  toggleBlockQuote: () => void;
  toggleOrderedList: () => void;
  toggleUnorderedList: () => void;
  setLink: (start: number, end: number, text: string, url: string) => void;
  setImage: (src: string, width: number, height: number) => void;
  startMention: (indicator: string) => void;
  setMention: (
    indicator: string,
    text: string,
    attributes?: Record<string, string>
  ) => void;
}
