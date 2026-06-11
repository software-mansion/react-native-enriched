import './HtmlOutputPanel.css';

interface HtmlOutputPanelProps {
  html: string;
}

export function HtmlOutputPanel({ html }: HtmlOutputPanelProps) {
  return (
    <div className="html-output" data-testid="html-output-panel">
      <div className="html-output-header" data-testid="html-output-header">
        <span>HTML Output</span>
      </div>
      <pre className="html-output-pre" data-testid="html-output-pre">
        {html}
      </pre>
    </div>
  );
}
