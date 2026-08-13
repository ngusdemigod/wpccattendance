"use client";

import { useEffect, useRef, useState } from "react";
import { EyeIcon, EyeSlashIcon, LockSimpleIcon, PaperPlaneTiltIcon, TrashIcon, XIcon } from "@phosphor-icons/react";
import { useRouter } from "next/navigation";
import { createPortal } from "react-dom";
import posthog from "posthog-js";
import type { DirectoryRow } from "./queries";
import { MemberDetailsEditor } from "./member-details-editor";

const date=(value?:string)=>{if(!value)return"—";const parsed=new Date(value);return Number.isNaN(parsed.valueOf())?"—":parsed.toLocaleDateString("en-NG",{day:"2-digit",month:"short",year:"numeric"});};
const relative=(value?:string)=>{if(!value)return"Never";const then=new Date(value).valueOf();if(!Number.isFinite(then))return"Never";const days=Math.floor((Date.now()-then)/86400000);if(days<=0)return"Today";if(days===1)return"Yesterday";if(days<7)return`${days} days ago`;return new Date(then).toLocaleDateString("en-NG",{month:"short",day:"numeric"});};
const initials=(name:string)=>name.split(/\s+/).slice(0,2).map(part=>part[0]).join("").toUpperCase();

export function MembersDirectory({rows,departments}:{rows:DirectoryRow[];departments:DirectoryRow[]}) {
  const router=useRouter();
  const [selected,setSelected]=useState<DirectoryRow|null>(null);
  const [seenNew,setSeenNew]=useState<Set<string>>(new Set()),[removedId,setRemovedId]=useState("");
  const [loading,setLoading]=useState(false);
  const [error,setError]=useState("");
  const dialog=useRef<HTMLDialogElement>(null);
  const trigger=useRef<HTMLElement|null>(null);
  const [deleting,setDeleting]=useState<DirectoryRow|null>(null),[method,setMethod]=useState<"password"|"otp">("password"),[password,setPassword]=useState(""),[showPassword,setShowPassword]=useState(false),[otp,setOtp]=useState(""),[deleteError,setDeleteError]=useState(""),[operationError,setOperationError]=useState(""),[deleteBusy,setDeleteBusy]=useState(false),[cooldown,setCooldown]=useState(0),[countdown,setCountdown]=useState(0),[deletionToken,setDeletionToken]=useState("");
  const [mounted,setMounted]=useState(false);
  useEffect(()=>{setMounted(true);try{setSeenNew(new Set(JSON.parse(localStorage.getItem("wpcc-seen-new-members")||"[]") as string[]));}catch{}},[]);
  useEffect(()=>{if(cooldown<=0)return;const timer=window.setInterval(()=>setCooldown(value=>Math.max(0,value-1)),1000);return()=>window.clearInterval(timer);},[cooldown]);
  useEffect(()=>{if(!deletionToken||countdown<=0)return;const timer=window.setTimeout(async()=>{if(countdown>1){setCountdown(value=>value-1);return;}setDeleteBusy(true);try{await memberRequest(deleting!.id,{action:"execute_delete",deletion_token:deletionToken});setOperationError("");setRemovedId(deleting!.id);window.setTimeout(()=>router.refresh(),360);}catch(reason){setOperationError(reason instanceof Error?reason.message:"Member could not be deleted");}finally{setDeletionToken("");setCountdown(0);setDeleting(null);setDeleteBusy(false);}},1000);return()=>window.clearTimeout(timer);},[countdown,deletionToken,deleting,router]);
  const memberRequest=async(id:string,body:Record<string,unknown>)=>{const response=await fetch(`/api/members/${encodeURIComponent(id)}`,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(body)}),payload=await response.json();if(!response.ok){if(Number(payload.retry_after)>0)setCooldown(Number(payload.retry_after));throw new Error(payload.error||"The request could not be completed");}return payload;};
  const sendDeleteOtp=async()=>{if(!deleting)return;setDeleteBusy(true);setDeleteError("");try{const payload=await memberRequest(deleting.id,{action:"request_delete_otp"});setCooldown(Number(payload.cooldown_seconds)||60);}catch(reason){setDeleteError(reason instanceof Error?reason.message:"Code could not be sent");}finally{setDeleteBusy(false);}};
  const authorizeDelete=async()=>{if(!deleting)return;setDeleteBusy(true);setDeleteError("");try{const payload=await memberRequest(deleting.id,{action:"authorize_delete",verification_method:method,password:method==="password"?password:undefined,otp:method==="otp"?otp:undefined});setDeletionToken(payload.deletion_token);setCountdown(5);setPassword("");setOtp("");}catch(reason){setDeleteError(reason instanceof Error?reason.message:"Deletion could not be authorized");}finally{setDeleteBusy(false);}};
  const undoDelete=()=>{setDeletionToken("");setCountdown(0);setDeleting(null);setDeleteError("");};

  const load=async(id:string)=>{setLoading(true);setError("");try{const response=await fetch(`/api/members/${encodeURIComponent(id)}`),payload=await response.json();if(!response.ok||!payload.member)throw new Error(payload.error||"Member profile could not be loaded.");setSelected(payload.member);}catch(reason){setError(reason instanceof Error?reason.message:"Member profile could not be loaded.");}finally{setLoading(false);}};
  const open=(row:DirectoryRow,element:HTMLElement)=>{trigger.current=element;setSelected(row);if(isNew(row)){setSeenNew(current=>{const next=new Set(current).add(row.id);localStorage.setItem("wpcc-seen-new-members",JSON.stringify([...next]));return next;});}void load(row.id);if(posthog.has_opted_in_capturing())posthog.capture("member_profile_opened",{member_id:row.id});queueMicrotask(()=>dialog.current?.showModal());};
  const close=()=>dialog.current?.close();
  const closed=()=>{setSelected(null);setError("");queueMicrotask(()=>trigger.current?.focus());};
  const beginDelete=(member:DirectoryRow)=>{setDeleting(member);setDeleteError("");setPassword("");setOtp("");close();};
  const isNew=(row:DirectoryRow)=>{const created=new Date(row.details?.date_joined||row.details?.created_at||"").valueOf();return Number.isFinite(created)&&created>=Date.now()-30*24*60*60*1000&&!seenNew.has(row.id);};

  return <>
    <div className="member-table-scroll" tabIndex={0}>
      <table className="v11-members-table">
        <thead><tr><th>Member code</th><th>Member</th><th>Phone</th><th>Department</th><th>Date joined</th><th>Last seen</th><th>Status</th><th aria-label="Action"/></tr></thead>
        <tbody>{rows.map(row=><tr className={`${isNew(row)?"new-member-row":""} ${removedId===row.id?"member-row-removing":""}`} key={row.id} role="button" aria-label={`View member details for ${row.primary}`} tabIndex={0} onClick={event=>open(row,event.currentTarget)} onKeyDown={event=>{if(event.key==="Enter"||event.key===" "){event.preventDefault();open(row,event.currentTarget);}}}>
          <td className="member-code">{row.details?.membership_code||"—"}</td>
          <td><div className="v11-member-identity"><span className="v11-avatar">{initials(row.primary)}</span><span><strong>{row.primary}</strong><small>{row.secondary}</small></span></div></td>
          <td>{row.details?.phone||"—"}</td><td>{row.details?.department_name||"Unassigned"}</td><td>{date(row.details?.date_joined||row.details?.created_at)}</td><td>{relative(row.details?.last_seen_at)}</td>
          <td><span className={`member-status ${row.status==="active"?"active":"follow-up"}`}>{row.status==="active"?"Active":"Follow-up"}</span></td>
          <td><button type="button" className="member-view" onClick={event=>{event.stopPropagation();open(row,event.currentTarget);}}>View</button></td>
        </tr>)}</tbody>
      </table>
    </div>
    <dialog className="member-profile-dialog" ref={dialog} onClose={closed} aria-labelledby="member-profile-title">
      {selected&&<>{loading?<div className="member-profile-state"><span className="detail-spinner"/>Loading member profile…</div>:error?<div className="member-profile-state"><p>{error}</p><button onClick={()=>void load(selected.id)}>Try again</button></div>:<MemberProfile member={selected} departments={departments} reload={()=>load(selected.id)} close={close} deleteMember={()=>beginDelete(selected)}/>}</>}
    </dialog>
    {mounted&&deleting&&!deletionToken&&createPortal(<div className="authorization-layer" role="dialog" aria-modal="true" aria-labelledby="delete-member-title"><section className="authorization-dialog delete-authorization"><header><div><h2 id="delete-member-title">Delete member</h2><p>Authorize deletion of {deleting.primary}</p></div><button type="button" onClick={()=>setDeleting(null)} aria-label="Close deletion authorization"><XIcon size={19}/></button></header><p className="delete-warning">This permanently removes the member account and related profile data.</p><div className="authorization-tabs"><button type="button" className={method==="password"?"active":""} onClick={()=>{setMethod("password");setDeleteError("");}}>Password</button><button type="button" className={method==="otp"?"active":""} onClick={()=>{setMethod("otp");setDeleteError("");}}>One-time code</button></div>{method==="password"?<label className="authorization-field"><span>Admin password</span><div><input type={showPassword?"text":"password"} value={password} onChange={event=>{setPassword(event.target.value);setDeleteError("");}} autoComplete="current-password"/><button type="button" onClick={()=>setShowPassword(value=>!value)} aria-label={showPassword?"Hide password":"Show password"}>{showPassword?<EyeSlashIcon size={17}/>:<EyeIcon size={17}/>}</button></div></label>:<label className="authorization-field"><span>One-time code</span><div className="otp-entry"><input inputMode="numeric" maxLength={6} value={otp} onChange={event=>{setOtp(event.target.value.replace(/\D/g,""));setDeleteError("");}} placeholder="000000"/><button type="button" disabled={deleteBusy||cooldown>0} onClick={()=>void sendDeleteOtp()}><PaperPlaneTiltIcon size={16}/>{cooldown?`Resend in ${cooldown}s`:"Send code"}</button></div><small>The code is sent to the currently signed-in administrator&apos;s email.</small></label>}{deleteError&&<p className="form-error" role="alert">{deleteError}</p>}<footer><button type="button" onClick={()=>setDeleting(null)}>Cancel</button><button type="button" className="danger-action" disabled={deleteBusy||(method==="password"?!password:otp.length!==6)} onClick={()=>void authorizeDelete()}><LockSimpleIcon size={16}/>{deleteBusy?"Authorizing…":"Authorize deletion"}</button></footer></section></div>,document.body)}
    {mounted&&deleting&&deletionToken&&createPortal(<div className="member-delete-snackbar" role="status" aria-live="polite"><span>Deleting {deleting.primary} in {countdown}s</span><button type="button" onClick={undoDelete} disabled={deleteBusy}>Undo</button></div>,document.body)}
    {mounted&&operationError&&createPortal(<div className="member-delete-snackbar delete-failure-snackbar" role="alert"><span>{operationError}</span><button type="button" onClick={()=>setOperationError("")}>Dismiss</button></div>,document.body)}
  </>;
}

function MemberProfile({member,departments,reload,close,deleteMember}:{member:DirectoryRow;departments:DirectoryRow[];reload:()=>Promise<void>;close:()=>void;deleteMember:()=>void}) {
  const [tab,setTab]=useState("Personal details");
  const details=member.sections?.["Personal details"]?.[0]?.details||{};
  const assigned=member.sections?.Departments||[];
  return <>
    <header className="member-profile-heading"><div><h2 id="member-profile-title">Member details</h2></div><button type="button" onClick={close} aria-label="Close member details"><XIcon size={20}/></button></header>
    <div className="member-profile-body">
      <section className="member-profile-person"><span className="member-profile-avatar">{initials(member.primary)}</span><div><h3>{member.primary}</h3><p>{details.membership_code||"—"} · {member.secondary}</p><div><span className="member-status active">{member.status}</span>{assigned.map(item=><span className="member-profile-chip" key={item.id}>{item.primary}</span>)}</div></div></section>
      <div className="member-profile-metrics">{["Queries","Missed services","Attendance rate","Souls won","Classes completed"].map((label,index)=><article className={index<2?"negative":""} key={label}><span>{label}</span><strong>{member.metrics?.[index]||"0"}</strong></article>)}</div>
      <nav className="member-profile-tabs" aria-label="Member profile sections">{["Personal details","Departments","Souls","Classes"].map(value=><button type="button" aria-current={tab===value?"page":undefined} onClick={()=>setTab(value)} key={value}>{value}</button>)}</nav>
      {tab==="Personal details"?<section className="member-personal-panel"><header><div><h4>Personal details</h4><p>Click any editable detail to make changes inline.</p></div></header><MemberDetailsEditor row={member} departments={departments} onSaved={reload}/></section>:<section className="member-related-panel"><h4>{tab}</h4>{(member.sections?.[tab]||[]).length?<ul>{(member.sections?.[tab]||[]).map(item=><li key={item.id}><strong>{item.primary}</strong><span>{item.secondary||item.status}</span></li>)}</ul>:<p>No {tab.toLowerCase()} records are available.</p>}</section>}
      <section className="member-danger-zone"><div><h4>Delete member</h4><p>Permanently remove this member account and its profile data.</p></div><button type="button" onClick={deleteMember}><TrashIcon size={16}/>Delete member</button></section>
    </div>
  </>;
}
