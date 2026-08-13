import { EnvelopeSimpleIcon, WarningCircleIcon } from "@phosphor-icons/react/dist/ssr";
import type { PageData } from "./queries";
import { DashboardPagination } from "./dashboard-pagination";

export function BroadcastHistoryPanel({data}:{data:PageData}){
  return <section className="broadcast-history" aria-labelledby="broadcast-history-title">
    <div className="panel-heading"><div><h2 id="broadcast-history-title">Campaign history</h2><p>Completed recipients / total recipients.</p></div><span>{data.pagination?.total??data.rows.length} campaigns</span></div>
    {data.loadError?<div className="history-empty" role="alert"><WarningCircleIcon size={22}/><strong>History unavailable</strong><span>{data.loadError}</span></div>:data.rows.length?<div className="broadcast-history-list">{data.rows.map(row=>{const completed=Number(row.details?.completed_recipients||0),total=Number(row.details?.total_recipients||0),failed=Number(row.details?.failed_recipients||0),percent=total?Math.round(completed*100/total):0;return <article key={row.id}>
      <div className="broadcast-history-title"><EnvelopeSimpleIcon size={18}/><div><strong>{row.primary}</strong><span>{row.id.slice(0,8).toUpperCase()} · Email · {(row.details?.audience_category||"individuals").replaceAll("_"," ")} · {row.meta}</span></div></div>
      <div className="broadcast-history-status"><span className="status-pill">{row.status.replaceAll("_"," ")}</span><strong>{completed} / {total}</strong></div>
      <progress max="100" value={percent} aria-label={`${row.primary} delivery progress`}>{percent}%</progress>
      <div className="broadcast-history-meta"><span>completed / total · {percent}%</span>{failed>0&&<span className="delivery-failure">{failed} failed</span>}</div>
    </article>;})}</div>:<div className="history-empty"><EnvelopeSimpleIcon size={22}/><strong>No campaigns found</strong><span>Queued email campaigns will appear here.</span></div>}
    {data.pagination&&<DashboardPagination {...data.pagination} label="Campaign history pages"/>}
  </section>;
}
