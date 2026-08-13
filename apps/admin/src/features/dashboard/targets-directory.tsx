"use client";

import { useActionState, useEffect, useRef, useState } from "react";
import { EyeIcon, XIcon } from "@phosphor-icons/react";
import posthog from "posthog-js";
import { addTargetProgress } from "./mutations";
import type { PageData, DirectoryRow } from "./queries";
import { DashboardPagination } from "./dashboard-pagination";

const date=(value:string|undefined)=>value&&!Number.isNaN(new Date(value).valueOf())?new Date(value).toLocaleDateString("en-NG",{day:"2-digit",month:"short",year:"numeric"}):"—";
const amount=(value:string|undefined)=>{const number=Number(value||0);return Number.isFinite(number)?new Intl.NumberFormat("en-NG",{maximumFractionDigits:2}).format(number):value||"—";};
const progress=(row:DirectoryRow)=>{const current=Number(row.details?.current_value||0),goal=Number(row.details?.goal_value||0);return{current,goal,percent:goal?Math.min(100,Math.round(current*100/goal)):0};};
const statusClass=(status:string)=>status.toLowerCase().replaceAll(" ","-");

function ProgressUpdate({row}:{row:DirectoryRow}){
  const[state,action,pending]=useActionState(addTargetProgress,{}),[key]=useState(()=>crypto.randomUUID()),step=row.details?.progress_step||"1";
  useEffect(()=>{if(state.ok&&state.message?.includes("trophy")&&posthog.has_opted_in_capturing())posthog.capture("target_hit",{target_id:row.id});},[state.ok,state.message,row.id]);
  return <form action={action} className="target-update-form" onSubmit={()=>{if(posthog.has_opted_in_capturing())posthog.capture("target_progress_updated",{target_id:row.id});}}><input type="hidden" name="target_id" value={row.id}/><input type="hidden" name="idempotency_key" value={key}/><label>Progress increment<input name="delta" type="number" step="any" defaultValue={step} required/></label><button className="primary-action" disabled={pending}>{pending?"Updating…":"Update progress"}</button>{state.error&&<span className="form-error" role="alert">{state.error}</span>}{state.ok&&<span className="form-success" role="status">{state.message}</span>}</form>;
}

function TargetDialog({row,onClose}:{row:DirectoryRow;onClose:()=>void}){
  const dialog=useRef<HTMLDialogElement>(null),values=progress(row),days=Math.max(0,Math.ceil((new Date(row.details?.ends_at||0).valueOf()-Date.now())/86400000));
  useEffect(()=>{dialog.current?.showModal();},[]);
  return <dialog ref={dialog} className="record-dialog target-detail-dialog" aria-labelledby="target-detail-title" aria-describedby="target-detail-description" onClose={onClose}><div className="dialog-heading"><div><p className="eyebrow">{row.details?.category} · {row.details?.metric}</p><h2 id="target-detail-title">{row.primary}</h2><p className="sr-only" id="target-detail-description">Target progress and schedule details.</p></div><button type="button" onClick={()=>dialog.current?.close()} aria-label="Close target details"><XIcon size={20}/></button></div><div className="record-dialog-body target-detail-body"><div className="profile-metrics">{[["Current",amount(String(values.current))],["Goal",amount(String(values.goal))],["Progress",`${values.percent}%`],["Days remaining",String(days)]].map(([label,value])=><article key={label}><span>{label}</span><strong>{value}</strong></article>)}</div><div className="target-detail-progress"><div><span>Delivery progress</span><strong>{values.percent}%</strong></div><progress max="100" value={values.percent}>{values.percent}%</progress></div><dl><div><dt>Period / event</dt><dd>{row.details?.period_label||"—"}</dd></div><div><dt>Period type</dt><dd>{row.details?.period_type||"—"}</dd></div><div><dt>Starts</dt><dd>{date(row.details?.starts_at)}</dd></div><div><dt>Ends</dt><dd>{date(row.details?.ends_at)}</dd></div><div><dt>Progress step</dt><dd>{row.details?.progress_step||"—"}</dd></div><div><dt>Last updated</dt><dd>{date(row.details?.updated_at)}</dd></div></dl>{row.status!=="Completed"&&<ProgressUpdate row={row}/>}</div></dialog>;
}

export function TargetsDirectory({data}:{data:PageData}){
  const[selected,setSelected]=useState<DirectoryRow|null>(null);
  const open=(row:DirectoryRow)=>{setSelected(row);if(posthog.has_opted_in_capturing())posthog.capture("target_opened",{target_id:row.id,status:row.status});};
  return <><section className="directory-panel targets-card"><div className="panel-heading"><div><h2>Target register</h2><p>Current measurable goals and their delivery status</p></div><span>{data.pagination?.total??data.rows.length} targets</span></div>{data.loadError?<p className="table-empty-message" role="alert">{data.loadError}</p>:data.rows.length?<><div className="table-scroll" tabIndex={0} aria-label="Scrollable target register"><table className="data-table targets-table"><thead><tr><th>Target</th><th>Metric</th><th>Period / Event</th><th>Current</th><th>Goal</th><th>Progress</th><th>Ends</th><th>Status</th><th>Actions</th></tr></thead><tbody>{data.rows.map(row=>{const values=progress(row);return <tr key={row.id} onDoubleClick={()=>open(row)}><td><strong>{row.primary}</strong><span className="target-category">{row.details?.category}</span></td><td>{row.details?.metric||"—"}</td><td>{row.details?.period_label||row.details?.period_type||"—"}</td><td className="target-value">{amount(row.details?.current_value)}</td><td className="target-value">{amount(row.details?.goal_value)}</td><td><div className="target-progress"><span>{values.percent}%</span><progress max="100" value={values.percent} aria-label={`${row.primary} progress`}>{values.percent}%</progress></div></td><td>{date(row.details?.ends_at)}</td><td><span className={`status-pill target-status-${statusClass(row.status)}`}><i/>{row.status}</span></td><td><button type="button" className="row-link target-view" onClick={()=>open(row)}><EyeIcon size={14}/>View</button></td></tr>})}</tbody></table></div>{data.pagination&&<DashboardPagination {...data.pagination} label="Target pages"/>}</>:<div className="empty-state"><h3>No targets yet</h3><p>Create your first measurable target for membership, souls, attendance or app usage.</p></div>}</section>{selected&&<TargetDialog row={selected} onClose={()=>setSelected(null)}/>}</>;
}
