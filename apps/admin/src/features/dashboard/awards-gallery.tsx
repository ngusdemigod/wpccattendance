"use client";

import { ArrowRightIcon, StarIcon, XIcon } from "@phosphor-icons/react";
import { useEffect, useRef, useState } from "react";
import posthog from "posthog-js";
import type { DirectoryRow, PageData } from "./queries";

function AwardDialog({award,onClose}:{award:DirectoryRow;onClose:()=>void}){
  const dialog=useRef<HTMLDialogElement>(null);
  useEffect(()=>{dialog.current?.showModal();},[]);
  const details=award.details||{};
  return <dialog ref={dialog} className="record-dialog award-dialog" aria-labelledby="award-dialog-title" aria-describedby="award-dialog-description" onClose={onClose}>
    <div className="dialog-heading"><div><p className="eyebrow">{details.metric||"Achievement"}</p><h2 id="award-dialog-title">{award.primary}</h2><p className="sr-only" id="award-dialog-description">Award achievement details.</p></div><button type="button" onClick={()=>dialog.current?.close()} aria-label="Close award details"><XIcon size={20}/></button></div>
    <div className="record-dialog-body award-dialog-body">
      <div className="award-dialog-hero award-symbol" aria-hidden="true"><StarIcon size={72} weight="fill"/></div>
      <section><span className="award-kicker">Achievement</span><h3>{award.primary}</h3>{award.secondary&&<p>{award.secondary}</p>}</section>
      <dl><div><dt>Period</dt><dd>{details.period_label||"—"}</dd></div><div><dt>Achieved</dt><dd>{award.meta}</dd></div><div><dt>Metric</dt><dd>{details.metric||"—"}</dd></div><div><dt>Goal</dt><dd>{details.goal_value||"—"}</dd></div></dl>
    </div>
  </dialog>;
}

export function AwardsGallery({data}:{data:PageData}){
  const[selected,setSelected]=useState<DirectoryRow|null>(null);
  const open=(award:DirectoryRow)=>{setSelected(award);if(posthog.has_opted_in_capturing())posthog.capture("award_opened",{award_id:award.id,metric:award.details?.metric});};
  if(data.loadError)return <section className="directory-panel"><div className="empty-state error-state-inline"><h2>Awards unavailable</h2><p>{data.loadError}</p></div></section>;
  if(!data.rows.length)return <section className="directory-panel awards-empty"><div className="empty-state"><div className="empty-icon"><StarIcon size={24}/></div><h2>No awards yet</h2><p>Completed milestones and notable accomplishments will appear here.</p></div></section>;
  return <><section className="award-grid" aria-label="Awards earned">{data.rows.map((award,index)=><article className="award-card" key={award.id}>
    <div className="award-copy"><div className="award-badges">{award.details?.period_label&&<span>{award.details.period_label}</span>}{award.details?.metric&&<span>{award.details.metric}</span>}<i className={`award-star award-star-${index%5}`}><StarIcon size={13} weight="fill"/></i></div><h2>{award.primary}</h2>{award.secondary&&<p>{award.secondary}</p>}</div>
    <div className="award-image award-symbol"><StarIcon size={56} weight="fill" aria-hidden="true"/><button type="button" className="award-read" onClick={()=>open(award)}>View award <span><ArrowRightIcon size={12}/></span></button></div>
  </article>)}</section><p className="award-page-note">Awards are generated from completed or exceptional targets and represent meaningful churchwide or ministry accomplishments.</p>{selected&&<AwardDialog award={selected} onClose={()=>setSelected(null)}/>}</>;
}
