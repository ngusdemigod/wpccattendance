"use client";
import { useEffect } from "react";
import { TrophyIcon } from "@phosphor-icons/react";
import posthog from "posthog-js";
import type { DirectoryRow } from "./queries";
export function TargetTrophyStrip({trophies}:{trophies:DirectoryRow[]}){useEffect(()=>{if(trophies.length&&posthog.has_opted_in_capturing())posthog.capture("trophy_viewed",{trophy_count:trophies.length});},[trophies.length]);return <div className="trophy-strip" aria-label="Target trophies" tabIndex={0}>{trophies.length?trophies.map(item=><article key={item.id}><div className="trophy-badge"><TrophyIcon size={21} weight="duotone"/></div><span>{item.details?.period_label||item.details?.period_type||"Achieved"}</span><strong>{item.primary}</strong><small>{item.meta}</small></article>):<p>No trophies earned yet.</p>}</div>}
