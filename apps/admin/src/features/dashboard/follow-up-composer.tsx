"use client";

import { useActionState, useState } from "react";
import { XIcon } from "@phosphor-icons/react";
import posthog from "posthog-js";
import { createCampaign } from "./mutations";
import type { DirectoryRow } from "./queries";

const capture=(event:string,properties?:Record<string,string|number>)=>{if(posthog.has_opted_in_capturing())posthog.capture(event,properties);};

export function FollowUpComposer({branches=[]}:{branches?:DirectoryRow[]}){
  const [state,action,pending]=useActionState(createCampaign,{});
  const [draft,setDraft]=useState("");
  const [recipients,setRecipients]=useState<string[]>([]);
  const [audience,setAudience]=useState("individuals");
  const addRecipients=()=>{const additions=draft.split(/[;,\s]+/).map(value=>value.trim().toLowerCase()).filter(Boolean);setRecipients(current=>Array.from(new Set([...current,...additions])));setDraft("");};
  return <section className="composer-panel"><div><h2>Create broadcast</h2><p>Email delivery is enabled. Other channels require approved providers.</p></div><form action={action} onSubmit={()=>capture("broadcast_submitted",{channel:"email",recipient_count:recipients.length})}>
    <div className="channel-grid" aria-label="Delivery channel"><label className="channel-choice active"><input name="channel" type="radio" value="email" defaultChecked onChange={()=>capture("broadcast_channel_selected",{channel:"email"})}/><span>Email</span></label>{["WhatsApp","SMS","Calls"].map(channel=><button type="button" disabled title="Provider not configured" key={channel}>{channel}</button>)}</div>
    {branches.length>0&&<label>Branch<select name="branch_id" required><option value="">Select branch</option>{branches.map(branch=><option value={branch.id} key={branch.id}>{branch.primary}</option>)}</select></label>}
    <label>Audience category<select name="audience" value={audience} onChange={event=>{const category=event.target.value;setAudience(category);if(category!=="individuals"){setRecipients([]);setDraft("");}capture("broadcast_audience_category_selected",{category});}}><option value="individuals">Individuals</option><option value="all">All members</option><option value="departments">All department members</option><option value="souls">Souls with email</option><option value="leaders">Active leaders</option></select></label>
    <label>Campaign name<input name="name" required/></label>
    <label>Email subject<input name="subject" required/></label>
    {audience==="individuals"?<label>Recipients<div className="tag-input">{recipients.map(recipient=><span key={recipient}>{recipient}<button type="button" aria-label={`Remove ${recipient}`} onClick={()=>setRecipients(current=>current.filter(item=>item!==recipient))}><XIcon size={12}/></button><input type="hidden" name="destination" value={recipient}/></span>)}<input type="email" value={draft} onChange={event=>setDraft(event.target.value)} onBlur={addRecipients} onKeyDown={event=>{if(event.key==="Enter"||event.key===","){event.preventDefault();addRecipients();}}} placeholder="name@example.com"/></div></label>:<p className="field-help">The selected all-category audience replaces individual tags. Addresses are resolved server-side, branch-scoped, and deduplicated.</p>}
    <label>Message<textarea name="body" rows={6} required/></label>
    <label>Schedule for later<input name="scheduled_at" type="datetime-local"/></label>
    {state.error&&<p className="form-error" role="alert">{state.error}</p>}{state.ok&&<p className="form-success" role="status">Campaign queued for asynchronous delivery.</p>}
    <button className="primary-action" disabled={pending||(audience==="individuals"&&!recipients.length)}>{pending?"Queueing…":"Queue email campaign"}</button>
  </form></section>;
}
