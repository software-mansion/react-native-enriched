import { codegenNativeComponent, type ColorValue } from 'react-native';
import type { HostComponent, ViewProps } from 'react-native';
import type {
  DirectEventHandler,
  Float,
  Int32,
  UnsafeMixed,
} from 'react-native/Libraries/Types/CodegenTypes';

type Heading = {
  fontSize?: Float;
  bold?: boolean;
};

export interface EnrichedTextHtmlStyleInternal {
  h1?: Heading;
  h2?: Heading;
  h3?: Heading;
  h4?: Heading;
  h5?: Heading;
  h6?: Heading;
  blockquote?: {
    borderColor?: ColorValue;
    borderWidth?: Float;
    gapWidth?: Float;
    color?: ColorValue;
  };
  codeblock?: {
    color?: ColorValue;
    borderRadius?: Float;
    backgroundColor?: ColorValue;
  };
  code?: {
    color?: ColorValue;
    backgroundColor?: ColorValue;
  };
  a?: {
    color?: ColorValue;
    textDecorationLine?: string;
  };
  // This is a workaround for the fact that codegen does not support Records.
  // On native Android side this will become a ReadableMap, on native iOS we can work with a folly::dynamic object.
  mention?: UnsafeMixed;
  ol?: {
    gapWidth?: Float;
    marginLeft?: Float;
    markerFontWeight?: string;
    markerColor?: ColorValue;
  };
  ul?: {
    bulletColor?: ColorValue;
    bulletSize?: Float;
    marginLeft?: Float;
    gapWidth?: Float;
  };
}

export interface OnLinkPressEvent {
  url: string;
}

export interface OnMentionPressEventInternal {
  text: string;
  indicator: string;
  attributes: UnsafeMixed;
}

export interface OnMentionPressEvent {
  text: string;
  indicator: string;
  attributes: Record<string, string>;
}

export interface NativeProps extends ViewProps {
  // Custom props
  text: string;
  htmlStyle?: EnrichedTextHtmlStyleInternal;

  // ReactNative TextProps
  ellipsizeMode: string;
  numberOfLines: Int32;
  selectable: boolean;
  selectionColor?: ColorValue;

  // Events
  onLinkPress?: DirectEventHandler<OnLinkPressEvent>;
  onMentionPress?: DirectEventHandler<OnMentionPressEventInternal>;

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
