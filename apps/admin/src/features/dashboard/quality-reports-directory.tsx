"use client";

import { useActionState, useEffect, useRef, useTransition } from "react";
import { XIcon } from "@phosphor-icons/react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import posthog from "posthog-js";
import type { DirectoryRow, PageData, QualityReportDetail } from "./queries";
import { assignQualityReport, transitionQualityReport } from "./mutations";
import { DashboardPagination } from "./dashboard-pagination";

const capture=(event:string,properties:Record<string,string|number|boolean>)=>{if(posthog.has_opted_in_capturing())posthog.capture(event,properties);};
const date=(value:string)=>{const parsed=new Date(value);return Number.isNaN(parsed.valueOf())?"—":new Intl.DateTimeFormat("en-NG",{day:"2-digit",month:"short",year:"numeric"}).format(parsed);};
const initials=(name:string)=>name.split(/\s+/).filter(Boolean).slice(0,2).map(part=>part[0]?.toUpperCase()).join("")||"QR";
const label=(value:string)=>value.replaceAll("_"," ").replace(/^./,character=>character.toUpperCase());

function Assignment({report,handlers}:{report:QualityReportDetail;handlers:DirectoryRow[]}){
  const [state,action,pending]=useActionState(assignQualityReport,{}),router=useRouter();
  useEffect(()=>{if(state.ok)router.replace(`/dashboard/quality-control/reports?selected=${report.id}`,{scroll:false});},[state.ok,report.id,router]);
  return <form action={action} className="qc-report-assignment"><input type="hidden" name="report_id" value={report.id}/><label>Assigned investigator<select name="assignee_id" defaultValue={report.assignedTo}><option value="">Unassigned</option>{handlers.map(handler=><option value={handler.id} key={handler.id}>{handler.primary}</option>)}</select></label><button className="secondary-action" disabled={pending}>{pending?"Assigning…":"Assign"}</button>{state.error&&<p className="form-error" role="alert">{state.error}</p>}{state.ok&&<p className="form-success" role="status">{state.message}</p>}</form>;
}

function Transitions({report}:{report:QualityReportDetail}){
  const [state,action,pending]=useActionState(transitionQualityReport,{}),router=useRouter();
  useEffect(()=>{if(state.ok){const event=state.message?.includes("escalated")?"qc_report_escalated":state.message?.includes("resolved")?"qc_report_resolved":"qc_report_reopened";capture(event,{report_id:report.id});router.replace(`/dashboard/quality-control/reports?selected=${report.id}`,{scroll:false});}},[state.ok,state.message,report.id,router]);
  const terminal=["resolved","closed"].includes(report.status);
  return <form action={action} className="qc-report-actions"><input type="hidden" name="report_id" value={report.id}/>{terminal?<button name="report_action" value="reopen" className="secondary-action" disabled={pending}>Reopen report</button>:<><button name="report_action" value="escalate" className="secondary-action" disabled={pending||report.status==="in_review"}>Escalate to issue</button><button name="report_action" value="resolve" className="primary-action" disabled={pending}>Mark resolved</button></>}{state.error&&<p className="form-error" role="alert">{state.error}</p>}{state.ok&&<p className="form-success" role="status">{state.message}</p>}</form>;
}

function ReportDialog({report,handlers,onClose}:{report:QualityReportDetail;handlers:DirectoryRow[];onClose:()=>void}){
  const dialog=useRef<HTMLDialogElement>(null);
  useEffect(()=>{dialog.current?.showModal();},[]);
  return <dialog className="action-dialog qc-report-dialog" ref={dialog} aria-labelledby="qc-report-title" aria-describedby="qc-report-description" onClose={onClose}><div className="dialog-heading"><div><p className="eyebrow">Quality-control report</p><h2 id="qc-report-title">{report.subject}</h2><p className="sr-only" id="qc-report-description">Review reporter identity, classification, assignment, and the private report description.</p></div><button type="button" onClick={()=>dialog.current?.close()} aria-label="Close report" title="Close report"><XIcon size={20}/></button></div><div className="record-dialog-body qc-report-detail"><div className="qc-report-summary"><div className="identity-cell"><div className="initials">{initials(report.reporterName)}</div><div><strong>{report.reporterName}</strong>{report.reporterEmail&&<span>{report.reporterEmail}</span>}</div></div><span className={`status-pill status-${report.status.replaceAll("_","-")}`}>{label(report.status)}</span></div><dl><div><dt>Report ID</dt><dd>{report.id}</dd></div><div><dt>Source</dt><dd>{label(report.source)}</dd></div><div><dt>Category</dt><dd>{report.category}</dd></div><div><dt>Priority</dt><dd><span className={`status-pill priority-${report.priority}`}>{label(report.priority)}</span></dd></div><div><dt>Submitted</dt><dd>{date(report.createdAt)}</dd></div><div><dt>Assigned to</dt><dd>{report.handlerName||"Unassigned"}</dd></div></dl><Assignment report={report} handlers={handlers}/><article className="qc-report-description"><h3>Report description</h3><p>{report.description}</p></article><Transitions report={report}/></div></dialog>;
}

export function QualityReportsDirectory({data}:{data:PageData}){
  const router=useRouter(),pathname=usePathname(),params=useSearchParams(),[pending,startTransition]=useTransition(),triggerLabel=useRef("");
  useEffect(()=>{if(!params.get("selected")&&triggerLabel.current){const selector=`[aria-label="${CSS.escape(triggerLabel.current)}"]`;queueMicrotask(()=>document.querySelector<HTMLElement>(selector)?.focus());}},[params]);
  const open=(row:DirectoryRow,element:HTMLElement)=>{triggerLabel.current=element.getAttribute("aria-label")||`Open report ${row.details?.subject}`;const next=new URLSearchParams(params.toString());next.set("selected",row.id);capture("qc_report_opened",{report_id:row.id,status:row.status});startTransition(()=>router.replace(`${pathname}?${next}`,{scroll:false}));};
  const close=()=>{const next=new URLSearchParams(params.toString());next.delete("selected");startTransition(()=>router.replace(`${pathname}?${next}`,{scroll:false}));};
  return <section className="directory-panel qc-reports-panel" aria-busy={pending}><div className="panel-heading"><div><h2>Submitted reports</h2><p>Click a report to review its complete authorised record.</p></div><span>{data.pagination?.total||0} reports</span></div>{data.rows.length?<><div className="table-scroll" tabIndex={0} aria-label="Scrollable quality-control reports"><table className="data-table qc-reports-table"><thead><tr><th scope="col">Report</th><th scope="col">Reporter</th><th scope="col">Source</th><th scope="col">Category</th><th scope="col">Priority</th><th scope="col">Date</th><th scope="col">Status</th></tr></thead><tbody>{data.rows.map(row=><tr key={row.id} tabIndex={0} role="button" aria-label={`Open report ${row.details?.subject}`} onClick={event=>open(row,event.currentTarget)} onKeyDown={event=>{if(event.key==="Enter"||event.key===" "){event.preventDefault();open(row,event.currentTarget);}}}><td><strong>{row.details?.subject||"Untitled report"}</strong><small>QCR-{row.id.slice(0,8).toUpperCase()}</small></td><td><div className="identity-cell"><div className="initials">{initials(row.primary)}</div><div><strong>{row.primary}</strong>{row.secondary&&<span>{row.secondary}</span>}</div></div></td><td>{label(row.details?.source||"")}</td><td>{row.details?.category||"—"}</td><td><span className={`status-pill priority-${row.details?.priority||"medium"}`}>{label(row.details?.priority||"medium")}</span></td><td>{date(row.details?.created_at||"")}</td><td><span className={`status-pill status-${row.status.replaceAll("_","-")}`}>{label(row.status)}</span></td></tr>)}</tbody></table></div>{data.pagination&&<DashboardPagination {...data.pagination} label="Quality-control reports pages"/>}</>:<div className="empty-state"><h3>No reports found</h3><p>No reports match the current authorised filters.</p></div>}{data.qualityReport&&<ReportDialog key={`${data.qualityReport.id}-${data.qualityReport.updatedAt}`} report={data.qualityReport} handlers={data.choices||[]} onClose={close}/>}</section>;
}
