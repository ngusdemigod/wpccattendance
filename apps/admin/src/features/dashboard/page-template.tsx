import { MagnifyingGlassIcon } from "@phosphor-icons/react/dist/ssr";
import Link from "next/link";
import type { DashboardPageConfig } from "./page-config";
import type { PageData } from "./queries";
import { DashboardFilters } from "./dashboard-filters";
import { PageAction } from "./page-action";
import { InteractiveDirectory } from "./interactive-directory";
import { FollowUpComposer } from "./follow-up-composer";
import { EnquiryWorkspace } from "./enquiry-workspace";
import { DepartmentGrid } from "./department-grid";
import { SessionFilter } from "./session-filter";
import { DepartmentAttachments } from "./department-attachments";
import { AnalyticsReport } from "./analytics-report";
import { DashboardPagination } from "./dashboard-pagination";
import { SoulWinningDirectory } from "./soul-winning-directory";
import { DepartmentDirectoryExport } from "./department-directory-export";
import { DepartmentDetailDirectory } from "./department-detail-directory";
import { QualityReportsDirectory } from "./quality-reports-directory";
import { QualityQueriesDirectory } from "./quality-queries-directory";
import { QualityIssuesDirectory } from "./quality-issues-directory";
import { AcademyClassesDirectory } from "./academy-classes-directory";
import { AcademyEnrolmentsDirectory } from "./academy-enrolments-directory";
import { AcademyInstructorsDirectory } from "./academy-instructors-directory";
import { BroadcastHistoryPanel } from "./broadcast-history-panel";
import { TargetsDirectory } from "./targets-directory";
import { AwardsGallery } from "./awards-gallery";
import { LiveAttendanceCard } from "./live-attendance-card";

const isNegativeMetric=(label:string)=>/queries|missed|inactive|overdue|awaiting|pending|critical|at risk|open (?:enquiries|reports|issues|queries)|needs follow-up|absent|unresolved|failed/i.test(label);
function Metrics({config,data}:{config:DashboardPageConfig;data:PageData}){return <div className="metric-grid">{config.metrics.map((label,index)=><article className={`metric-card tone-${index%5}${isNegativeMetric(label)?" negative-metric":""}`} key={label}><span>{label}</span><strong>{data.metricValues[index]||"—"}</strong><small>{data.metricSupporting?.[index]||"Current authorised scope"}</small></article>)}</div>;}
const pieColors=["#087b55","#46a57f","#78bea1","#a4d5bf","#d2eadf","#54796a","#86a89a","#bfd3ca"];
function PieVisual({title,points}:{title:string;points:Array<{label:string;value:number}>}){const total=points.reduce((sum,point)=>sum+Math.max(0,point.value),0);let offset=0;const segments=points.map((point,index)=>{const start=offset;offset+=total?point.value/total*360:0;return`${pieColors[index%pieColors.length]} ${start}deg ${offset}deg`;});return <div className="pie-chart" aria-label={title}><div className="pie-graphic" role="img" aria-label={`${title}: ${points.map(point=>`${point.label} ${point.value}`).join(", ")}`} style={{background:total?`conic-gradient(${segments.join(",")})`:"var(--surface-raised)"}}/><ul>{points.map((point,index)=><li key={point.label}><i style={{background:pieColors[index%pieColors.length]}}/><span>{point.label}</span><strong>{point.value}</strong></li>)}</ul></div>;}
function DataVisual({title,points}:{title:string;points:Array<{label:string;value:number}>}){if(title==="Membership over time")return <LiveAttendanceCard/>;const max=Math.max(1,...points.map(point=>point.value));return <article className="visual-panel"><div><h2>{title}</h2><p>Updates with the selected period and authorised branch.</p></div>{points.length?(title==="Members by department"?<PieVisual title={title} points={points}/>:<div className="bar-chart" aria-label={title}>{points.map(point=><div key={point.label}><i style={{height:`${Math.max(4,point.value/max*100)}%`}}/><span>{point.label}</span><strong>{point.value}</strong></div>)}</div>):<div className="chart-empty">No data in this period.</div>}</article>;}
function Directory({path,config,data}:{path:string;config:DashboardPageConfig;data:PageData}){return <section className="directory-panel"><div className="panel-heading"><div><h2>{config.sectionTitle}</h2><p>Authorised records from the existing Supabase project.</p></div></div>{data.loadError?<div className="empty-state error-state-inline"><div className="empty-icon"><MagnifyingGlassIcon size={24}/></div><h3>Data unavailable</h3><p>{data.loadError}</p></div>:data.rows.length||path===""?<><InteractiveDirectory path={path} rows={data.rows} choices={data.choices}/>{data.pagination&&<DashboardPagination {...data.pagination} label={path==="members"?"Member directory pages":path==="events"?"Event directory pages":"Directory pages"}/>}</>:<div className="empty-state"><div className="empty-icon"><MagnifyingGlassIcon size={24}/></div><h3>No records found</h3><p>No records match the current authorised scope and filters.</p></div>}</section>;}
function DepartmentExtras({data,departmentId}:{data:PageData;departmentId:string}){if(data.loadError)return <section className="directory-panel"><div className="empty-state error-state-inline"><div className="empty-icon"><MagnifyingGlassIcon size={24}/></div><h2>Department unavailable</h2><p>{data.loadError}</p></div></section>;return <DepartmentAttachments departmentId={departmentId} branchId={data.selectedBranch} attachments={data.attachments||[]}/>;}

export function DashboardPageTemplate({path,config,data}:{path:string;config:DashboardPageConfig;data:PageData}){return <div className="dashboard-page">
  <section className="page-title-block">{path.startsWith("departments/")&&<Link className="back-link" href="/dashboard/departments">← Back to departments</Link>}<p className="eyebrow">Church operations</p><h1>{data.pageTitle||config.title}</h1><p>{data.pageDescription||config.description}</p>{path.startsWith("departments/")&&<div className="page-actions"><DepartmentDirectoryExport departmentId={path.split("/")[1]}/></div>}{(config.secondaryAction||config.action)&&<div className="page-actions">{config.secondaryAction&&<PageAction path={path} label={config.secondaryAction} rows={data.rows} choices={data.choices} branches={data.branches}/>} {config.action&&<PageAction path={path} label={config.action} rows={data.rows} choices={data.choices} branches={data.branches}/>}</div>}</section>
  {!!config.metrics.length&&<Metrics config={config} data={data}/>} 
  <DashboardFilters pagePath={path} branches={data.branches}/>
  {path==="academy/instructors"&&data.sessions&&<SessionFilter sessions={data.sessions}/>}
  {path===""&&<div className="visual-grid">{(data.visuals||[]).map(visual=><DataVisual key={visual.title} {...visual}/>)}</div>}
  {path==="analytics"&&(data.analytics?<AnalyticsReport report={data.analytics}/>:<section className="directory-panel"><div className="empty-state error-state-inline"><div className="empty-icon"><MagnifyingGlassIcon size={24}/></div><h3>Report unavailable</h3><p>{data.loadError||"The authorised analytics report could not be loaded."}</p></div></section>)} 
  {path.startsWith("departments/")&&<DepartmentExtras data={data} departmentId={path.split("/")[1]}/>} 
  {path==="analytics"?null:path.startsWith("departments/")?(data.loadError?null:<DepartmentDetailDirectory data={data}/>):path==="soul-winning"?<SoulWinningDirectory data={data}/>:path==="enquiries"?<EnquiryWorkspace data={data}/>:path==="quality-control/reports"?(data.loadError?<Directory path={path} config={config} data={data}/>:<QualityReportsDirectory data={data}/>):path==="quality-control/queries"?(data.loadError?<Directory path={path} config={config} data={data}/>:<QualityQueriesDirectory data={data}/>):path==="quality-control/issues"?(data.loadError?<Directory path={path} config={config} data={data}/>:<QualityIssuesDirectory data={data}/>):path==="academy/classes"?(data.loadError?<Directory path={path} config={config} data={data}/>:<AcademyClassesDirectory data={data}/>):path==="academy/enrolments"?(data.loadError?<Directory path={path} config={config} data={data}/>:<AcademyEnrolmentsDirectory data={data}/>):path==="academy/instructors"?(data.loadError?<Directory path={path} config={config} data={data}/>:<AcademyInstructorsDirectory data={data}/>):path==="follow-ups"?<div className="composer-layout"><FollowUpComposer branches={data.branches}/><BroadcastHistoryPanel data={data}/></div>:path==="targets"?<TargetsDirectory data={data}/>:path==="awards"?<AwardsGallery data={data}/>:path==="departments"?<DepartmentGrid rows={data.rows}/>:<Directory path={path} config={config} data={data}/>} 
</div>;}
