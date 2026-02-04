import './App.css';
import { EnrichedTextInput } from 'react-native-enriched';

function App() {
  return (
    <div className="container">
      <div>Text input</div>
      <EnrichedTextInput placeholder="Type something..." />
    </div>
  );
}

export default App;
