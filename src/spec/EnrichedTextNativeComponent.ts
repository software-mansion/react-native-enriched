import { codegenNativeComponent, type ColorValue } from 'react-native';
import type { HostComponent, ViewProps } from 'react-native';
import type { Float } from 'react-native/Libraries/Types/CodegenTypes';

export interface NativeProps extends ViewProps {
  text: string;

  // Style related props - used for generating proper setters in component's manager
  // These should not be passed as regular props
  color?: ColorValue;
  fontSize?: Float;
  fontFamily?: string;
  fontWeight?: string;
  fontStyle?: string;
}

export default codegenNativeComponent<NativeProps>('EnrichedTextView', {
  interfaceOnly: true,
}) as HostComponent<NativeProps>;
