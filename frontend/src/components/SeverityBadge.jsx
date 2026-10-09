export default function SeverityBadge({ severity }) { return <span className={`badge severity ${severity || 'info'}`}>{severity?.replace('_', ' ') || 'info'}</span> }
