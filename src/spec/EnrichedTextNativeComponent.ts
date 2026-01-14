import { codegenNativeComponent } from 'react-native';
import type { HostComponent, ViewProps } from 'react-native';

export interface NativeProps extends ViewProps {
  text: string;
}

export default codegenNativeComponent<NativeProps>('EnrichedTextView', {
  interfaceOnly: true,
}) as HostComponent<NativeProps>;
