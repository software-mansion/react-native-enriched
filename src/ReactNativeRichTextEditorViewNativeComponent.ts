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
  isH1: boolean;
  isH2: boolean;
  isH3: boolean;
  isCodeBlock: boolean;
  isBlockQuote: boolean;
}

export interface NativeProps extends ViewProps {
  defaultValue?: string;
  onChangeText?: DirectEventHandler<OnChangeTextEvent>;
  onChangeStyle?: DirectEventHandler<OnChangeStyleEvent>;

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
  toggleH1: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleH2: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleH3: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleCodeBlock: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleBlockQuote: (viewRef: React.ElementRef<ComponentType>) => void;
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
    'toggleH1',
    'toggleH2',
    'toggleH3',
    'toggleCodeBlock',
    'toggleBlockQuote',
  ],
});

export default codegenNativeComponent<NativeProps>(
  'ReactNativeRichTextEditorView',
  {
    interfaceOnly: true,
  }
) as HostComponent<NativeProps>;
