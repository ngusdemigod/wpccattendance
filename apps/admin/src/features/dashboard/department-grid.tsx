"use client";
import Link from "next/link";
import { UsersThreeIcon } from "@phosphor-icons/react";
import posthog from "posthog-js";
import type { DirectoryRow } from "./queries";

export function DepartmentGrid({rows}:{rows:DirectoryRow[]}){return rows.length?<section className="department-card-grid">{rows.map(row=><Link href={`/dashboard/departments/${row.id}`} aria-label={`Open ${row.primary} department`} onClick={()=>{if(posthog.has_opted_in_capturing())posthog.capture("department_opened",{department_id:row.id});}} key={row.id}><div className="department-card-icon"><UsersThreeIcon size={21}/></div><h2>{row.primary}</h2></Link>)}</section>:<section className="empty-state"><h3>No departments found</h3><p>No departments match the current authorised search.</p></section>;}
