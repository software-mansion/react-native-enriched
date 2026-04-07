import App from './App';
import { TestSetSelection } from './testScreens/TestSetSelection';
import { VisualRegressionScreen } from './testScreens/VisualRegressionScreen';
import { useEffect, useState } from 'react';

export default function RouteSelector() {
  const [path, setPath] = useState(window.location.pathname);

  useEffect(() => {
    const onPopState = () => {
      setPath(window.location.pathname);
    };

    window.addEventListener('popstate', onPopState);
    return () => {
      window.removeEventListener('popstate', onPopState);
    };
  }, []);

  if (path === '/test-set-selection') {
    return <TestSetSelection />;
  }

  if (path === '/visual-regression') {
    return <VisualRegressionScreen />;
  }

  return <App />;
}
