import App from './App';
import { TestMentions } from './testScreens/TestMentions';
import { TestLinks } from './testScreens/TestLinks';
import { TestSetSelection } from './testScreens/TestSetSelection';
import { VisualRegression } from './testScreens/VisualRegression';
import { TestSubmitProps } from './testScreens/TestSubmitProps';
import { TestEnrichedText } from './testScreens/TestEnrichedText';
import { TestEllipsize } from './testScreens/TestEllipsize';
import { TestRenderCycle } from './testScreens/TestRenderCycle';
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

  if (path === '/test-links') {
    return <TestLinks />;
  }

  if (path === '/visual-regression') {
    return <VisualRegression />;
  }

  if (path === '/test-submit-props') {
    return <TestSubmitProps />;
  }

  if (path === '/test-mentions') {
    return <TestMentions />;
  }

  if (path === '/test-enriched-text') {
    return <TestEnrichedText />;
  }

  if (path === '/test-ellipsize') {
    return <TestEllipsize />;
  }

  if (path === '/test-render-cycle') {
    return <TestRenderCycle />;
  }

  return <App />;
}
