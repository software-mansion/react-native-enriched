import { StyleSheet, Text, View } from 'react-native';

type Props = {
  color: string;
};

const ColorPreview: React.FC<Props> = ({ color }) => {
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

export default ColorPreview;
