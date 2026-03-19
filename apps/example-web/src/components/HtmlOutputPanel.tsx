import './HtmlOutputPanel.css';

interface HtmlOutputPanelProps {
  html: string;
}

export function HtmlOutputPanel({ html }: HtmlOutputPanelProps) {
  return (
    <div className="html-output">
      <div className="html-output-header">
        <span>HTML Output</span>
      </div>
      <pre className="html-output-pre">{html}</pre>
    </div>
  );
}
