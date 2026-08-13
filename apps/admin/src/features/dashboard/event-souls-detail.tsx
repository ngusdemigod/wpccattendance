"use client";
import { MagnifyingGlassIcon } from "@phosphor-icons/react";
import posthog from "posthog-js";
import { useActionState,useCallback,useEffect,useState } from "react";
import { transitionSoul } from "./mutations";
type Soul={id:string;full_name:string;email:string|null;phone:string|null;location:string|null;evangelist_name:string|null;status:string};
type Payload={rows:Soul[];total:number;page:number;page_size:number};

function SoulAction({row,onChanged}:{row:Soul;onChanged:()=>void}){
  const next:Record<string,string>={awaiting_contact:"contacted",contacted:"integrating",integrating:"integrated"},value=next[row.status];
  const [state,action,pending]=useActionState(transitionSoul,{});
  useEffect(()=>{if(state.ok){if(posthog.has_opted_in_capturing())posthog.capture("soul_status_changed",{soul_id:row.id,to_status:value});onChanged();}},[state.ok,onChanged,row.id,value]);
  if(!value)return null;
  return <form action={action} className="record-action-form"><input type="hidden" name="soul_id" value={row.id}/><input type="hidden" name="next_status" value={value}/><label>Follow-up notes<textarea name="notes" rows={2}/></label><button className="primary-action" disabled={pending}>{pending?"Updating…":`Move to ${value.replaceAll("_"," ")}`}</button>{state.error&&<p className="form-error" role="alert">{state.error}</p>}</form>;
}

export function EventSoulsDetail({eventId}:{eventId:string}){
  const [query,setQuery]=useState(""),[debounced,setDebounced]=useState(""),[page,setPage]=useState(1),[payload,setPayload]=useState<Payload|null>(null),[loading,setLoading]=useState(true),[error,setError]=useState("");
  useEffect(()=>{const handle=setTimeout(()=>{setDebounced(query.trim());setPage(1);},300);return()=>clearTimeout(handle);},[query]);
  const load=useCallback(async()=>{setLoading(true);setError("");try{const params=new URLSearchParams({page:String(page)});if(debounced)params.set("q",debounced);const response=await fetch(`/api/evangelism-events/${encodeURIComponent(eventId)}/souls?${params}`,{cache:"no-store"}),data=await response.json();if(!response.ok||!Array.isArray(data.rows))throw new Error(data.error||"Souls directory could not be loaded");setPayload(data);}catch(reason){setError(reason instanceof Error?reason.message:"Souls directory could not be loaded");}finally{setLoading(false);}},[eventId,page,debounced]);
  useEffect(()=>{const handle=setTimeout(()=>void load(),0);return()=>clearTimeout(handle);},[load]);
  const changed=useCallback(()=>void load(),[load]),rows=payload?.rows||[],total=payload?.total||0,size=payload?.page_size||50,pages=Math.max(1,Math.ceil(total/size));
  return <section className="related-directory" aria-busy={loading}><div className="related-directory-heading"><h3>Souls directory</h3><span>{total} souls</span></div><label className="filter-search"><MagnifyingGlassIcon size={16}/><input value={query} onChange={event=>setQuery(event.target.value)} placeholder="Search name, phone, evangelist or location" aria-label="Search souls directory"/></label>{loading?<div className="member-detail-state" role="status">Loading souls…</div>:error?<div className="member-detail-state" role="alert"><p>{error}</p><button type="button" className="secondary-action" onClick={()=>void load()}>Try again</button></div>:<><div className="table-scroll" tabIndex={0} aria-label="Scrollable souls directory"><table className="data-table"><thead><tr><th scope="col">Name</th><th scope="col">Phone</th><th scope="col">Evangelist</th><th scope="col">Location</th><th scope="col">Status</th><th scope="col">Follow-up</th></tr></thead><tbody>{rows.map(row=><tr key={row.id}><td><div className="identity-cell"><div className="initials">{row.full_name.split(/\s+/).slice(0,2).map(word=>word[0]).join("").toUpperCase()}</div><div><strong>{row.full_name}</strong>{row.email&&<span>{row.email}</span>}</div></div></td><td>{row.phone||"—"}</td><td>{row.evangelist_name||"Unassigned"}</td><td>{row.location||"—"}</td><td><span className="status-pill">{row.status.replaceAll("_"," ")}</span></td><td><SoulAction row={row} onChanged={changed}/></td></tr>)}</tbody></table></div>{!rows.length&&<p className="modal-empty">{debounced?"No souls match this search.":"No souls are assigned to this event."}</p>}{pages>1&&<nav className="directory-pagination" aria-label="Souls directory pages"><span>Page {page} of {pages}</span><div><button type="button" disabled={page<=1} onClick={()=>setPage(value=>value-1)}>Previous</button><button type="button" disabled={page>=pages} onClick={()=>setPage(value=>value+1)}>Next</button></div></nav>}</>}</section>;
}
