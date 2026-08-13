"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { BroadcastIcon } from "@phosphor-icons/react";
import { createClient } from "@/lib/supabase/client";

type LiveEvent={id:string;title:string;starts_at:string;ends_at:string};
type ClockIn={id:string;member_code:string;first_name:string;clocked_in_at:string};
type LivePayload={event:LiveEvent|null;rows:ClockIn[]};

const remaining=(endsAt:string)=>Math.max(0,new Date(endsAt).valueOf()-Date.now());
const clock=(milliseconds:number)=>{const seconds=Math.floor(milliseconds/1000),hours=Math.floor(seconds/3600),minutes=Math.floor(seconds%3600/60);return`${String(hours).padStart(2,"0")}:${String(minutes).padStart(2,"0")}:${String(seconds%60).padStart(2,"0")}`;};
const time=(value:string)=>{const parsed=new Date(/(?:Z|[+-]\d\d:\d\d)$/.test(value)?value:`${value}Z`);return Number.isNaN(parsed.valueOf())?"—":parsed.toLocaleTimeString("en-NG",{hour:"2-digit",minute:"2-digit"});};

export function LiveAttendanceCard(){
  const [payload,setPayload]=useState<LivePayload>({event:null,rows:[]});
  const [loading,setLoading]=useState(true);
  const [error,setError]=useState("");
  const [milliseconds,setMilliseconds]=useState(0);
  const supabase=useMemo(()=>createClient(),[]);
  const refresh=useCallback(async()=>{try{const response=await fetch("/api/overview/live-attendance",{cache:"no-store"}),next=await response.json();if(!response.ok)throw new Error(next.error||"Live attendance could not be loaded");setPayload(next);setError("");}catch(reason){setError(reason instanceof Error?reason.message:"Live attendance could not be loaded");}finally{setLoading(false);}},[]);

  useEffect(()=>{void refresh();},[refresh]);
  useEffect(()=>{if(!payload.event){setMilliseconds(0);return;}const update=()=>setMilliseconds(remaining(payload.event!.ends_at));update();const timer=window.setInterval(update,1000);return()=>window.clearInterval(timer);},[payload.event]);
  useEffect(()=>{if(!payload.event)return;const channel=supabase.channel(`overview-attendance-${payload.event.id}`).on("postgres_changes",{event:"INSERT",schema:"public",table:"attendance",filter:`event_id=eq.${payload.event.id}`},()=>void refresh()).subscribe();return()=>{void supabase.removeChannel(channel);};},[payload.event,supabase,refresh]);

  const ended=Boolean(payload.event)&&milliseconds<=0;
  return <article className="visual-panel live-attendance-panel" aria-live="polite">
    <div className="live-attendance-heading"><div><h2>Service Check-in</h2><p>{payload.event?.title||"Live attendance session"}</p></div><span className={payload.event&&!ended?"live":""}><i/>{payload.event&&!ended?"Live":"Waiting"}</span></div>
    {loading?<div className="live-attendance-empty">Loading live session…</div>:error?<div className="live-attendance-empty" role="alert">{error}</div>:payload.event?<div className="live-attendance-card">
      <section className="live-timer"><div className="live-pattern" aria-hidden="true"/><span>{ended?"Session ended":"Ends in"}</span><strong>{clock(milliseconds)}</strong><div className="live-event-time"><BroadcastIcon size={17}/><span>{payload.rows.length} checked in</span></div></section>
      <section className="live-clockins"><header><h3>Live clock-ins</h3><span>{payload.rows.length}</span></header><div className="live-clockin-list" tabIndex={0}>{payload.rows.length?<table><thead><tr><th>Member code</th><th>First name</th><th>Clock-in</th></tr></thead><tbody>{payload.rows.map(row=><tr key={row.id}><td>{row.member_code}</td><td>{row.first_name}</td><td>{time(row.clocked_in_at)}</td></tr>)}</tbody></table>:<p>No members have clocked in yet.</p>}</div></section>
    </div>:<div className="live-attendance-empty">No attendance session is live right now.</div>}
  </article>;
}
