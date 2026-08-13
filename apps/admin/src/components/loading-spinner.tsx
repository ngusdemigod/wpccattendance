export function LoadingSpinner({ label = "Loading" }: { label?: string }) {
  return <span className="loading-indicator" role="status" aria-label={label}><span className="loading-spinner" aria-hidden="true"/></span>;
}

export function BusyLabel({ label }: { label: string }) {
  return <><span className="loading-spinner" aria-hidden="true"/><span>{label}</span></>;
}
