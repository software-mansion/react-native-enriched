import { useState } from 'react';
import { DevScreen } from './screens/DevScreen';
import { TestScreen } from './screens/TestScreen';

export default function App() {
  const [isTestScreen, setIsTestScreen] = useState(false);

  if (isTestScreen) {
    return <TestScreen onSwitch={() => setIsTestScreen(false)} />;
  }

  return <DevScreen onSwitch={() => setIsTestScreen(true)} />;
}
