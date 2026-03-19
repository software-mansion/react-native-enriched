import './App.css';
import { EnrichedTextInput } from 'react-native-enriched';

function App() {
  return (
    <div className="container">
      <EnrichedTextInput defaultValue="<p>Hello from web!</p><p>A quick brown fox jumps over the lazy dog</p>" />
    </div>
  );
}

export default App;
