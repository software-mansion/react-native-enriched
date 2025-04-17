import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';
import codegenNativeCommands from 'react-native/Libraries/Utilities/codegenNativeCommands';
import type { HostComponent, ViewProps } from 'react-native';
import React from 'react';

export interface NativeProps extends ViewProps {
  defaultValue?: string;
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
  'ReactNativeRichTextEditorView'
);
