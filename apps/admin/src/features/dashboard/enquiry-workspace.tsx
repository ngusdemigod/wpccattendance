"use client";

import { useActionState, useEffect, useRef, useTransition } from "react";
import { ArrowLeftIcon, EnvelopeSimpleIcon } from "@phosphor-icons/react";
import { useRouter, useSearchParams } from "next/navigation";
import posthog from "posthog-js";
import type { DirectoryRow, EnquiryThread, PageData } from "./queries";
import { assignEnquiry, replyToEnquiry, setEnquiryStatus } from "./mutations";
import { DashboardPagination } from "./dashboard-pagination";

const capture=(event:string,properties:Record<string,string|number|boolean>)=>{if(posthog.has_opted_in_capturing())posthog.capture(event,properties);};
const date=(value:string)=>{const parsed=new Date(value);return Number.isNaN(parsed.valueOf())?"—":new Intl.DateTimeFormat("en-NG",{day:"2-digit",month:"short",year:"numeric",hour:"2-digit",minute:"2-digit"}).format(parsed);};
const initials=(name:string)=>name.split(/\s+/).filter(Boolean).slice(0,2).map(part=>part[0]?.toUpperCase()).join("")||"EC";
const displayStatus=(status:string,priority="")=>priority==="high"||priority==="critical"?"Urgent":status==="in_progress"?"In review":["resolved","closed"].includes(status)?"Closed":"Open";

function Feedback({state}:{state:{error?:string;message?:string;ok?:boolean}}){return <>{state.error&&<p className="form-error" role="alert">{state.error}</p>}{state.ok&&<p className="form-success" role="status">{state.message||"Changes saved."}</p>}</>;}

function ReplyForm({thread}:{thread:EnquiryThread}){
  const [state,action,pending]=useActionState(replyToEnquiry,{}),form=useRef<HTMLFormElement>(null),router=useRouter();
  useEffect(()=>{if(state.ok){capture("enquiry_response_sent",{enquiry_id:thread.id,delivery_queued:state.message?.includes("queued")||false});form.current?.reset();router.replace(`/dashboard/enquiries?selected=${thread.id}`,{scroll:false});}},[state.ok,state.message,thread.id,router]);
  return <form action={action} className="reply-form" ref={form}><input type="hidden" name="enquiry_id" value={thread.id}/><label htmlFor="enquiry-reply">Write a response<textarea id="enquiry-reply" name="body" rows={5} maxLength={4000} required placeholder="Write a response"/></label><div className="reply-form-footer"><span>Responses are appended to the conversation and sent by email when an address is available.</span><button className="primary-action" disabled={pending}>{pending?"Sending…":"Send response"}</button></div><Feedback state={state}/></form>;
}

function StatusForm({thread}:{thread:EnquiryThread}){
  const [state,action,pending]=useActionState(setEnquiryStatus,{}),router=useRouter(),closed=["resolved","closed"].includes(thread.status);
  useEffect(()=>{if(state.ok){capture("enquiry_status_changed",{enquiry_id:thread.id,to_status:closed?"open":"resolved"});router.replace(`/dashboard/enquiries?selected=${thread.id}`,{scroll:false});}},[state.ok,thread.id,closed,router]);
  return <form action={action} className="enquiry-status-form"><input type="hidden" name="enquiry_id" value={thread.id}/><input type="hidden" name="status" value={closed?"open":"resolved"}/><button className="secondary-action" disabled={pending}>{pending?"Saving…":closed?"Reopen enquiry":"Mark resolved"}</button><Feedback state={state}/></form>;
}

function AssignmentForm({thread,handlers}:{thread:EnquiryThread;handlers:DirectoryRow[]}){
  const [state,action,pending]=useActionState(assignEnquiry,{}),router=useRouter();
  useEffect(()=>{if(state.ok)router.replace(`/dashboard/enquiries?selected=${thread.id}`,{scroll:false});},[state.ok,thread.id,router]);
  return <form action={action} className="enquiry-assignment"><input type="hidden" name="enquiry_id" value={thread.id}/><label>Assigned handler<select name="handler_id" defaultValue={thread.assignedTo}><option value="">Unassigned</option>{handlers.map(handler=><option value={handler.id} key={handler.id}>{handler.primary}</option>)}</select></label><button className="secondary-action" disabled={pending}>{pending?"Assigning…":"Assign"}</button><Feedback state={state}/></form>;
}

function EnquiryList({rows,selectedId,onSelect,pagination}:{rows:DirectoryRow[];selectedId:string;onSelect:(row:DirectoryRow)=>void;pagination?:PageData["pagination"]}){
  const options=useRef<Array<HTMLButtonElement|null>>([]);
  return <section className="directory-panel enquiry-list" aria-label="Enquiry inbox"><div className="panel-heading"><div><h2>Enquiry inbox</h2><p>{rows.length} conversations on this page</p></div></div>{rows.length?<><div role="listbox" aria-label="Enquiries">{rows.map((row,index)=>{const priority=row.details?.priority||"",label=displayStatus(row.status,priority);return <button ref={element=>{options.current[index]=element;}} type="button" role="option" aria-selected={selectedId===row.id} onClick={()=>onSelect(row)} onKeyDown={event=>{if(event.key==="ArrowDown"||event.key==="ArrowUp"){event.preventDefault();const offset=event.key==="ArrowDown"?1:-1;options.current[(index+offset+rows.length)%rows.length]?.focus();}}} key={row.id}><span className="person-avatar" aria-hidden="true">{initials(row.primary)}</span><span className="enquiry-list-copy"><strong>{row.primary}</strong><span>{row.secondary||"No email address"}</span><small>{row.details?.subject||"Untitled enquiry"} · {row.details?.category||"General"}</small></span><span className={`status-pill status-${label.toLowerCase().replaceAll(" ","-")}`}>{label}</span><time dateTime={row.details?.created_at}>{date(row.details?.created_at||"")}</time></button>;})}</div>{pagination&&<DashboardPagination {...pagination} label="Enquiry inbox pages"/>}</>:<div className="empty-state"><EnvelopeSimpleIcon size={25}/><h3>No enquiries found</h3><p>No conversations match the current authorised filters.</p></div>}</section>;
}

function EnquiryDetail({thread,handlers,onBack}:{thread:EnquiryThread;handlers:DirectoryRow[];onBack:()=>void}){const label=displayStatus(thread.status,thread.priority);return <section className="message-detail" aria-labelledby="enquiry-detail-title"><button type="button" className="mobile-enquiry-back" onClick={onBack}><ArrowLeftIcon size={16}/>Back to inbox</button><header><div><div className="enquiry-detail-person"><span className="person-avatar" aria-hidden="true">{initials(thread.senderName)}</span><div><p className="eyebrow">{thread.category||"Enquiry"}</p><h2 id="enquiry-detail-title">{thread.subject}</h2><p>From {thread.senderName}{thread.senderEmail?` · ${thread.senderEmail}`:""} · {date(thread.createdAt)}</p></div></div><span className={`status-pill status-${label.toLowerCase().replaceAll(" ","-")}`}>{label}</span></div><StatusForm thread={thread}/></header><AssignmentForm thread={thread} handlers={handlers}/><article className="enquiry-original"><h3>Original message</h3><p>{thread.body}</p></article><section className="message-history" aria-label="Conversation history" aria-live="polite"><h3>Conversation history</h3>{thread.messages.length?thread.messages.map(message=><article key={message.id}><div><strong>Administrator response</strong><span className={`delivery-state delivery-${message.deliveryStatus}`}>{message.deliveryStatus}</span></div><p>{message.body}</p><time dateTime={message.createdAt}>{date(message.createdAt)}</time></article>):<p className="empty-thread">No responses have been sent yet.</p>}</section><ReplyForm thread={thread}/></section>}

export function EnquiryWorkspace({data}:{data:PageData}){
  const router=useRouter(),params=useSearchParams(),[pending,startTransition]=useTransition();
  const select=(row:DirectoryRow)=>{const next=new URLSearchParams(params.toString());next.set("selected",row.id);capture("enquiry_opened",{enquiry_id:row.id,status:row.status,urgent:["high","critical"].includes(row.details?.priority||"")});startTransition(()=>router.replace(`/dashboard/enquiries?${next}`,{scroll:false}));};
  const back=()=>{const next=new URLSearchParams(params.toString());next.delete("selected");startTransition(()=>router.replace(`/dashboard/enquiries?${next}`,{scroll:false}));};
  if(data.loadError)return <section className="directory-panel"><div className="empty-state error-state-inline" role="alert"><h2>Enquiries unavailable</h2><p>{data.loadError}</p></div></section>;
  return <div className={`inbox-layout${params.get("selected")?" drill-in":""}`} aria-busy={pending}><EnquiryList rows={data.rows} selectedId={data.selectedId||""} onSelect={select} pagination={data.pagination}/>{data.enquiryThread?<EnquiryDetail key={data.enquiryThread.id} thread={data.enquiryThread} handlers={data.choices||[]} onBack={back}/>:<section className="message-detail"><div className="empty-state"><EnvelopeSimpleIcon size={25}/><h2>Select an enquiry</h2><p>Choose an authorised conversation from the inbox.</p></div></section>}</div>;
}
