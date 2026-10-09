export const shortId = (id) => id ? `${id.slice(0, 8)}…` : '—'
export const dateTime = (value) => value ? new Intl.DateTimeFormat('en-GB', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value)) : '—'
export const relativeTime = (value) => value ? new Intl.RelativeTimeFormat('en', { numeric: 'auto' }).format(Math.round((new Date(value) - new Date()) / 86400000), 'day') : '—'
