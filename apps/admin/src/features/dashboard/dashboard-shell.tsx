"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useEffect, useRef, useState, useTransition } from "react";
import {
  BuildingsIcon, CalendarDotsIcon, ChartLineUpIcon, ChatsCircleIcon, CrosshairIcon,
  GraduationCapIcon, ListIcon, MagnifyingGlassIcon, MoonIcon, ShieldCheckIcon,
  TargetIcon, UsersThreeIcon, XIcon,
} from "@phosphor-icons/react";
import posthog from "posthog-js";

const groups = [
  { label: "Menu", links: [
    ["Overview", "/dashboard", ChartLineUpIcon],
    ["Members", "/dashboard/members", UsersThreeIcon], ["Events", "/dashboard/events", CalendarDotsIcon],
    ["Soul winning", "/dashboard/soul-winning", CrosshairIcon], ["Departments", "/dashboard/departments", BuildingsIcon],
    ["Enquiries", "/dashboard/enquiries", ChatsCircleIcon],
  ]},
  { label: "Quality control", links: [
    ["Reports inbox", "/dashboard/quality-control/reports", ShieldCheckIcon], ["Queries", "/dashboard/quality-control/queries", ChatsCircleIcon],
    ["Issue tracker", "/dashboard/quality-control/issues", TargetIcon],
  ]},
  { label: "Academy", links: [
    ["Classes", "/dashboard/academy/classes", GraduationCapIcon], ["Enrolments", "/dashboard/academy/enrolments", UsersThreeIcon],
    ["Instructors", "/dashboard/academy/instructors", GraduationCapIcon],
  ]},
] as const;

function HeaderSearch() {
  const pathname = usePathname();
  const router = useRouter();
  const params = useSearchParams();
  const currentRef = useRef(new URLSearchParams(params.toString()));
  const [value, setValue] = useState(params.get("q") || "");
  const [pending, startTransition] = useTransition();
  useEffect(() => {
    currentRef.current = new URLSearchParams(params.toString());
    setValue(params.get("q") || "");
  }, [params]);
  useEffect(() => {
    const handle = window.setTimeout(() => {
      const next = new URLSearchParams(currentRef.current);
      const query = value.trim();
      if (query) next.set("q", query); else next.delete("q");
      next.delete("page");
      currentRef.current = next;
      if (query && posthog.has_opted_in_capturing()) {
        if (pathname === "/dashboard/members") posthog.capture("members_searched", { query_length: query.length });
        if (pathname === "/dashboard/events") posthog.capture("events_searched", { query_length: query.length });
        if (pathname === "/dashboard/departments") posthog.capture("department_searched", { query_length: query.length });
      }
      startTransition(() => router.replace(`${pathname}${next.size ? `?${next}` : ""}`, { scroll: false }));
    }, 300);
    return () => window.clearTimeout(handle);
  }, [pathname, router, value]);
  return <label className="workspace-search" aria-busy={pending}><MagnifyingGlassIcon size={15}/><input type="search" value={value} onChange={event=>setValue(event.target.value)} placeholder="Search current page..." aria-label="Search current page"/><span aria-hidden="true">⌘ F</span></label>;
}

export function DashboardShell({ children, userLabel, branchName, badges={} }: { children: React.ReactNode; userLabel: string; branchName: string; badges?:Record<string,number> }) {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);
  const close = () => setOpen(false);
  useEffect(() => {
    const stored = window.localStorage.getItem("churchmetric-theme");
    const shouldUseDark = stored === "dark" || (!stored && window.matchMedia("(prefers-color-scheme: dark)").matches);
    document.documentElement.dataset.theme = shouldUseDark ? "dark" : "light";
  }, []);
  const toggleTheme = () => {
    const next = document.documentElement.dataset.theme !== "dark";
    document.documentElement.dataset.theme = next ? "dark" : "light";
    window.localStorage.setItem("churchmetric-theme", next ? "dark" : "light");
  };
  useEffect(() => {
    if (!open) return;
    const onKeyDown = (event: KeyboardEvent) => { if (event.key === "Escape") setOpen(false); };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [open]);
  return <div className="dashboard-stage"><div className="dashboard-frame">
    <aside className={`dashboard-sidebar ${open ? "is-open" : ""}`}>
      <div className="brand-lockup"><Image src="/wpcc-logo.png" alt="WPCC" width={37} height={37}/><div><strong>Dream Team</strong><span>{branchName}</span></div><button className="mobile-close" onClick={close} aria-label="Close navigation"><XIcon size={20}/></button></div>
      <nav aria-label="Dashboard navigation">
        {groups.map(group => <div className="nav-group" key={group.label}><p>{group.label}</p>{group.links.map(([label, href, Icon]) => {
          const active = href === "/dashboard" ? pathname === href : pathname.startsWith(href);
          const badge=badges[href];return <Link className={active ? "active" : ""} href={href} onClick={close} key={href}><Icon size={18}/><span>{label}</span>{badge>0&&<span className="nav-count-badge">{badge>999?`${(badge/1000).toFixed(1)}k`:badge}</span>}</Link>;
        })}</div>)}
        <div className="nav-group operations"><p>Operations</p>
          <Link className={pathname.startsWith("/dashboard/follow-ups") ? "active" : ""} href="/dashboard/follow-ups" onClick={close}><ChatsCircleIcon size={18}/>Follow-ups</Link>
        </div>
      </nav>
    </aside>
    {open && <button className="sidebar-backdrop" onClick={close} aria-label="Close navigation"/>}
    <section className="dashboard-workspace">
      <header className="dashboard-topbar">
        <button className="mobile-menu-button" onClick={() => setOpen(true)} aria-label="Open navigation"><ListIcon size={21}/></button>
        <HeaderSearch/>
        <div className="topbar-tools">
          <button className="topbar-icon-button" type="button" onClick={toggleTheme} aria-label="Toggle color theme" title="Toggle color theme"><MoonIcon size={16}/></button>
          <div className="topbar-user"><div className="account-avatar">{userLabel.slice(0, 2).toUpperCase()}</div><div><strong>{userLabel}</strong><span>Administrator</span></div></div>
        </div>
      </header>
      <main className="dashboard-main">{children}</main>
    </section>
  </div></div>;
}
