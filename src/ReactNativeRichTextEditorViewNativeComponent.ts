import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';
import codegenNativeCommands from 'react-native/Libraries/Utilities/codegenNativeCommands';
import type {
  DirectEventHandler,
  Float,
} from 'react-native/Libraries/Types/CodegenTypes';
import type { ColorValue, HostComponent, ViewProps } from 'react-native';
import React from 'react';

export interface OnChangeTextEvent {
  value: string;
}

export interface OnChangeStyleEvent {
  isBold: boolean;
  isItalic: boolean;
  isUnderline: boolean;
  isStrikeThrough: boolean;
  isInlineCode: boolean;
  isH1: boolean;
  isH2: boolean;
  isH3: boolean;
  isLink: boolean;
  isImage: boolean;
  isMention: boolean;
}

export interface OnPressLinkEvent {
  url: string;
}

export interface OnLinkDetectedEvent {
  text: string;
  url: string;
}

export interface OnMentionEvent {
  text: string | null;
}

export interface OnPressMentionEvent {
  text: string;
  value: string;
}

export interface NativeProps extends ViewProps {
  defaultValue?: string;
  onChangeText?: DirectEventHandler<OnChangeTextEvent>;
  onChangeStyle?: DirectEventHandler<OnChangeStyleEvent>;
  onPressLink?: DirectEventHandler<OnPressLinkEvent>;
  onLinkDetected?: DirectEventHandler<OnLinkDetectedEvent>;
  onMention?: DirectEventHandler<OnMentionEvent>;
  onPressMention?: DirectEventHandler<OnPressMentionEvent>;

  // Style related props - used for generating proper setters in component's manager
  // These should not be passed as regular props
  color?: ColorValue;
  fontSize?: Float;
  fontFamily?: string;
  fontWeight?: string;
  fontStyle?: string;
}

type ComponentType = HostComponent<NativeProps>;

interface NativeCommands {
  // General commands
  focus: (viewRef: React.ElementRef<ComponentType>) => void;
  blur: (viewRef: React.ElementRef<ComponentType>) => void;

  // Text formatting commands
  toggleBold: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleItalic: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleUnderline: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleStrikeThrough: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleInlineCode: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleH1: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleH2: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleH3: (viewRef: React.ElementRef<ComponentType>) => void;
  addLink: (
    viewRef: React.ElementRef<ComponentType>,
    text: string,
    url: string
  ) => void;
  addImage: (viewRef: React.ElementRef<ComponentType>, uri: string) => void;
  startMention: (viewRef: React.ElementRef<ComponentType>) => void;
  addMention: (
    viewRef: React.ElementRef<ComponentType>,
    text: string,
    value: string
  ) => void;
}

export const Commands: NativeCommands = codegenNativeCommands<NativeCommands>({
  supportedCommands: [
    // General commands
    'focus',
    'blur',

    // Text formatting commands
    'toggleBold',
    'toggleItalic',
    'toggleUnderline',
    'toggleStrikeThrough',
    'toggleInlineCode',
    'toggleH1',
    'toggleH2',
    'toggleH3',
    'addLink',
    'addImage',
    'startMention',
    'addMention',
  ],
});

export default codegenNativeComponent<NativeProps>(
  'ReactNativeRichTextEditorView',
  {
    interfaceOnly: true,
  }
) as HostComponent<NativeProps>;
