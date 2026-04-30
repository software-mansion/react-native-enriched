import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import './index.css';
import RouteSelector from './RouteSelector';

const rootElement = document.getElementById('root');
if (!rootElement) throw new Error('Root element "#root" not found');

createRoot(rootElement).render(
  <StrictMode>
    <RouteSelector />
  </StrictMode>
);
