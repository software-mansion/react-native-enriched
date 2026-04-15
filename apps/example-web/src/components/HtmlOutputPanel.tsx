import { useMemo } from 'react';
import { html as beautifyHtml } from 'js-beautify';

import './HtmlOutputPanel.css';

interface HtmlOutputPanelProps {
  html: string;
}

export function HtmlOutputPanel({ html }: HtmlOutputPanelProps) {
  const formattedHtml = useMemo(() => {
    if (!html.trim()) {
      return html;
    }

    try {
      return beautifyHtml(html, {
        indent_size: 2,
        preserve_newlines: true,
        max_preserve_newlines: 2,
        wrap_line_length: 0,
      });
    } catch {
      return html;
    }
  }, [html]);

  return (
    <div className="html-output" data-testid="html-output-panel">
      <div className="html-output-header" data-testid="html-output-header">
        <span>HTML Output</span>
      </div>
      <pre className="html-output-pre" data-testid="html-output-pre">
        {formattedHtml}
      </pre>
    </div>
  );
}
