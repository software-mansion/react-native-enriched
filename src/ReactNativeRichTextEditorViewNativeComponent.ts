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

export interface NativeProps extends ViewProps {
  defaultValue?: string;
  onChangeText?: DirectEventHandler<OnChangeTextEvent>;

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
  focus: (viewRef: React.ElementRef<ComponentType>) => void;
  blur: (viewRef: React.ElementRef<ComponentType>) => void;
}

export const Commands: NativeCommands = codegenNativeCommands<NativeCommands>({
  supportedCommands: ['focus', 'blur'],
});

export default codegenNativeComponent<NativeProps>(
  'ReactNativeRichTextEditorView',
  {
    interfaceOnly: true,
  }
) as HostComponent<NativeProps>;
