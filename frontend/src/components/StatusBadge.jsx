export default function StatusBadge({ status }) { return <span className={`badge status ${status || 'queued'}`}>{status?.replaceAll('_', ' ') || 'queued'}</span> }
