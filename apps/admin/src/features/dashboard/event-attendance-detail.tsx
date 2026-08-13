"use client";

import { MagnifyingGlassIcon } from "@phosphor-icons/react";
import { useCallback, useEffect, useState } from "react";

type AttendanceRow={id:string;full_name:string;email:string|null;department_name:string|null;membership_code:string|null;created_at:string|null};
type AttendancePayload={rows:AttendanceRow[];total:number;page:number;page_size:number};
const time=(value:string|null)=>{if(!value)return "—";const date=new Date(value);return Number.isNaN(date.valueOf())?"—":date.toLocaleTimeString("en-NG",{hour:"2-digit",minute:"2-digit"});};

export function EventAttendanceDetail({eventId}:{eventId:string}){
  const [query,setQuery]=useState("");
  const [debounced,setDebounced]=useState("");
  const [page,setPage]=useState(1);
  const [payload,setPayload]=useState<AttendancePayload|null>(null);
  const [loading,setLoading]=useState(true);
  const [error,setError]=useState("");
  useEffect(()=>{const handle=setTimeout(()=>{setDebounced(query.trim());setPage(1);},300);return()=>clearTimeout(handle);},[query]);
  const load=useCallback(async()=>{
    setLoading(true);setError("");
    try{
      const params=new URLSearchParams({page:String(page)});if(debounced)params.set("q",debounced);
      const response=await fetch(`/api/events/${encodeURIComponent(eventId)}/attendance?${params}`,{cache:"no-store"});const data=await response.json();
      if(!response.ok||!Array.isArray(data.rows))throw new Error(data.error||"Attendance register could not be loaded");setPayload(data);
    }catch(reason){setError(reason instanceof Error?reason.message:"Attendance register could not be loaded");}finally{setLoading(false);}
  },[eventId,page,debounced]);
  useEffect(()=>{const handle=setTimeout(()=>void load(),0);return()=>clearTimeout(handle);},[load]);
  const rows=payload?.rows||[],total=payload?.total||0,pageSize=payload?.page_size||50,pages=Math.max(1,Math.ceil(total/pageSize));
  return <section className="related-directory" aria-busy={loading}>
    <div className="related-directory-heading"><h3>Attendance register</h3><span>{total} attendees</span></div>
    <label className="filter-search"><MagnifyingGlassIcon size={16}/><input value={query} onChange={event=>setQuery(event.target.value)} placeholder="Search attendance register" aria-label="Search attendance register"/></label>
    {loading?<div className="member-detail-state" role="status"><span className="detail-spinner"/>Loading attendance…</div>:error?<div className="member-detail-state" role="alert"><p>{error}</p><button className="secondary-action" type="button" onClick={()=>void load()}>Try again</button></div>:<>
      <div className="table-scroll" tabIndex={0} aria-label="Scrollable attendance register"><table className="data-table"><thead><tr><th scope="col">Name</th><th scope="col">Department</th><th scope="col">Membership code</th><th scope="col">Time</th></tr></thead><tbody>{rows.map(row=><tr key={row.id}><td><div className="identity-cell"><div className="initials">{row.full_name.split(/\s+/).slice(0,2).map(word=>word[0]).join("").toUpperCase()}</div><div><strong>{row.full_name}</strong>{row.email&&<span>{row.email}</span>}</div></div></td><td>{row.department_name||"Unassigned"}</td><td>{row.membership_code||"—"}</td><td>{time(row.created_at)}</td></tr>)}</tbody></table></div>
      {!rows.length&&<p className="modal-empty">{debounced?"No attendees match this search.":"No attendance has been recorded for this event."}</p>}
      {pages>1&&<nav className="directory-pagination" aria-label="Attendance register pages"><span>Page {page} of {pages}</span><div><button type="button" disabled={page<=1} onClick={()=>setPage(value=>value-1)}>Previous</button><button type="button" disabled={page>=pages} onClick={()=>setPage(value=>value+1)}>Next</button></div></nav>}
    </>}
  </section>;
}
