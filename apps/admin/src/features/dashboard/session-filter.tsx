"use client";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import posthog from "posthog-js";
import type { DirectoryRow } from "./queries";
export function SessionFilter({sessions}:{sessions:DirectoryRow[]}){const router=useRouter(),pathname=usePathname(),params=useSearchParams();const update=(value:string)=>{const next=new URLSearchParams(params.toString());if(value)next.set("session",value);else next.delete("session");if(posthog.has_opted_in_capturing())posthog.capture("academy_instructor_session_changed",{session_id:value||"all"});router.replace(`${pathname}?${next}`,{scroll:false});};return <label className="session-filter">Academy session<select value={params.get("session")||""} onChange={event=>update(event.target.value)}><option value="">All academy sessions</option>{sessions.map(session=><option value={session.id} key={session.id}>{session.primary}</option>)}</select></label>;}
