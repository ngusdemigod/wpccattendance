export default function Loading() {
  return <div className="dashboard-page" aria-busy="true"><div className="skeleton title-skeleton"/><div className="metric-grid">{Array.from({length: 4}, (_, i) => <div className="skeleton metric-card" key={i}/>)}</div><div className="skeleton directory-panel"/></div>;
}
