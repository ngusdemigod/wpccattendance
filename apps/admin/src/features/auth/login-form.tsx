"use client";

import Image from "next/image";
import { EnvelopeSimpleIcon, EyeIcon, EyeSlashIcon, IdentificationCardIcon, LockSimpleIcon } from "@phosphor-icons/react";
import { useActionState, useEffect, useState } from "react";
import { login, requestMemberCodeLink } from "./actions";
import { BusyLabel } from "@/components/loading-spinner";

const carouselImages = [
  "722430729_18378692893204822_1936766637906389977_n.jpg",
  "742619752_18382887613204822_6903666339252187234_n.jpg",
  "744740438_18382887646204822_5845935576561635847_n.jpg",
  "745341846_18382887622204822_6199576186820083669_n.jpg",
  "746823908_18382887673204822_5939168766328640174_n.jpg",
  "749377968_1537063924786050_8524010914227496773_n.jpg",
  "752290685_1349831533332933_1885952496830871840_n.jpg",
];

export function LoginForm({ notice, error }: { notice?: string; error?: string }) {
  const [method, setMethod] = useState<"code" | "email">("code");
  const [showPassword, setShowPassword] = useState(false);
  const [snackbar, setSnackbar] = useState(
    notice === "unauthorized"
      ? "Administrator access is required. Please sign in with an authorised account."
      : error === "invalid_link"
        ? "That sign-in link is invalid or has expired. Please request a new one."
        : "",
  );
  const [emailState, emailAction, emailPending] = useActionState(login, {});
  const [codeState, codeAction, codePending] = useActionState(requestMemberCodeLink, {});

  useEffect(() => {
    if (!snackbar) return;
    const timer = window.setTimeout(() => setSnackbar(""), 5000);
    return () => window.clearTimeout(timer);
  }, [snackbar]);

  return <main className="auth-page">
    {snackbar && <div className="auth-snackbar" role="status" aria-live="polite"><span>{snackbar}</span><button type="button" onClick={() => setSnackbar("")} aria-label="Dismiss notification">×</button></div>}
    <section className="auth-card">
      <div className="auth-intro">
        <div className="auth-carousel" aria-hidden="true">{carouselImages.map((src,index)=><Image key={src} src={`/carousel/${src}`} alt="" fill sizes="(max-width: 760px) 0px, 50vw" priority={index===0}/>)}</div>
        <div className="auth-brand"><Image src="/wpcc-logo.png" alt="WPCC" width={58} height={58} priority/><div><strong>Dream Team</strong><span>Church Workforce Management</span></div></div>
      </div>
      <div className="auth-form-panel">
        <p className="eyebrow">Welcome back</p><h2>Sign in to Dream Team</h2><p>Access your church workforce management workspace.</p>
        <div className="auth-method-tabs" role="tablist" aria-label="Sign-in method">
          <button type="button" role="tab" aria-selected={method === "code"} onClick={() => setMethod("code")}>Member code</button>
          <button type="button" role="tab" aria-selected={method === "email"} onClick={() => setMethod("email")}>Email</button>
        </div>
        {method === "email" ? <form action={emailAction}>
          <label>Email address<span className="auth-input"><EnvelopeSimpleIcon size={19}/><input name="email" type="email" autoComplete="email" placeholder="Enter your email address" required/></span></label>
          <label>Password<span className="auth-input"><LockSimpleIcon size={19}/><input name="password" type={showPassword?"text":"password"} autoComplete="current-password" placeholder="Enter your password" required/><button type="button" onClick={()=>setShowPassword(value=>!value)} aria-label={showPassword?"Hide password":"Show password"}>{showPassword?<EyeSlashIcon size={19}/>:<EyeIcon size={19}/>}</button></span></label>
          {emailState.error && <p className="form-error" role="alert">{emailState.error}</p>}
          {emailState.message && <p className="form-success" role="status">{emailState.message}</p>}
          <button className="primary-action" disabled={emailPending} aria-busy={emailPending}>{emailPending ? <BusyLabel label="Signing in"/> : "Sign in to workspace"}</button>
        </form> : <form action={codeAction}>
          <label>Membership code<span className="auth-input"><IdentificationCardIcon size={20}/><input name="membership_code" autoComplete="one-time-code" placeholder="Enter your membership code" maxLength={64} required/></span></label>
          <p className="auth-helper">We’ll email the secure sign-in link connected to your membership code.</p>
          {codeState.error && <p className="form-error" role="alert">{codeState.error}</p>}
          {codeState.message && <p className="form-success" role="status">{codeState.message}</p>}
          <button className="primary-action" disabled={codePending} aria-busy={codePending}>{codePending ? <BusyLabel label="Sending"/> : "Email sign-in link"}</button>
        </form>}
      </div>
    </section>
  </main>;
}
