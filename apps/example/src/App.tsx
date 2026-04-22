import { useState } from 'react';
import { DevScreen } from './screens/DevScreen';
import { TestScreen } from './screens/TestScreen';
import { EnrichedTextScreen } from './screens/EnrichedTextScreen';
import { ChatScreen } from './screens/ChatScreen';
import { View } from 'react-native';

type Screen = 'dev' | 'test' | 'enrichedText';

export default function App() {
  const [screen, setScreen] = useState<Screen>('dev');
  return (
    <View style={{ flex: 1, paddingVertical: 40, backgroundColor: 'white' }}>
      <ChatScreen />
    </View>
  );

  if (screen === 'test') {
    return (
      <TestScreen
        onSwitch={() => setScreen('dev')}
        onSwitchEnrichedText={() => setScreen('enrichedText')}
      />
    );
  }

  if (screen === 'enrichedText') {
    return <EnrichedTextScreen onSwitch={() => setScreen('test')} />;
  }

  return <DevScreen onSwitch={() => setScreen('test')} />;
}
