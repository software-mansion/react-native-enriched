import { Text, type TextStyle } from 'react-native';
import glyphMap from '../../assets/icons/FontAwesome.json';
import { type FC, memo } from 'react';

export type IconName = keyof typeof glyphMap;

export interface IconProps {
  name: IconName;
  size?: number;
  color?: string;
}

const BaseIcon: FC<IconProps> = ({ name, size = 24, color = 'black' }) => {
  const glyphValue = glyphMap[name];
  const glyph = glyphValue ? String.fromCharCode(glyphValue) : '';

  const styleDefaults: TextStyle = {
    color,
    fontFamily: 'FontAwesome',
    fontSize: size,
    fontWeight: 'normal',
    fontStyle: 'normal',
  };

  return (
    <Text selectable={false} style={styleDefaults}>
      {glyph}
    </Text>
  );
};

export const Icon = memo(BaseIcon);
