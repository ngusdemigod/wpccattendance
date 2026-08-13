"use client";

import { usePathname } from "next/navigation";
import posthog from "posthog-js";
import { useEffect, useState } from "react";

export function AnalyticsConsent() {
  const pathname=usePathname(); const [choice,setChoice]=useState<boolean|null>(null);
  useEffect(()=>{queueMicrotask(()=>{if(!process.env.NEXT_PUBLIC_POSTHOG_KEY){setChoice(false);return;}setChoice(posthog.has_opted_in_capturing()?true:posthog.has_opted_out_capturing()?false:null);});},[]);
  useEffect(()=>{if(choice===true)posthog.capture("dashboard_page_viewed",{route:pathname});},[choice,pathname]);
  if(choice!==null||!process.env.NEXT_PUBLIC_POSTHOG_KEY)return null;
  const decide=(accepted:boolean)=>{if(accepted){posthog.opt_in_capturing();posthog.capture("analytics_consent_granted");}else{posthog.opt_out_capturing();}setChoice(accepted);};
  return <aside className="consent-banner" aria-label="Analytics consent"><p>Allow privacy-safe product analytics to help improve this admin dashboard?</p><div><button onClick={()=>decide(false)}>Decline</button><button className="accept" onClick={()=>decide(true)}>Allow analytics</button></div></aside>;
}
