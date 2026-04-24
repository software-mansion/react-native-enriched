import { useState } from 'react';
import { DevScreen } from './screens/DevScreen';
import { TestScreen } from './screens/TestScreen';
import { EnrichedTextScreen } from './screens/EnrichedTextScreen';

type Screen = 'dev' | 'test' | 'enrichedText';

export default function App() {
  const [screen, setScreen] = useState<Screen>('dev');

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
