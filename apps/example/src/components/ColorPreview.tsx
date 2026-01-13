import { StyleSheet, Text, View } from 'react-native';
import { type FC } from 'react';

type Props = {
  color: string;
};

export const ColorPreview: FC<Props> = ({ color }) => {
  return (
    <>
      <View
        style={[
          styles.preview,
          {
            backgroundColor: color,
          },
        ]}
      />
      <Text>{color}</Text>
    </>
  );
};

const styles = StyleSheet.create({
  preview: {
    marginVertical: 8,
    width: 40,
    height: 40,
    borderRadius: 20,
  },
});
