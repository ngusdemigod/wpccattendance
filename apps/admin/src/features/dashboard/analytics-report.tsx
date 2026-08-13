import type { AnalyticsReport as AnalyticsReportData } from "./queries";

const title=(value:string)=>value==="care_qc"?"Care and QC":value.charAt(0).toUpperCase()+value.slice(1);
const number=new Intl.NumberFormat("en-NG");
const changeLabel=(value:number|null,current:number)=>value==null?(current>0?"New":"0%"):`${value>0?"↑ ":value<0?"↓ ":""}${Math.abs(value)}%`;

export function AnalyticsReport({report}:{report:AnalyticsReportData}){
  return <>
    <div className="analytics-panels">
      <section className="analytics-panel" aria-labelledby="performance-trend-title">
        <header><h2 id="performance-trend-title">Performance trend</h2><p>Current period compared with the immediately preceding period.</p></header>
        <div className="analytics-bars">{report.trend.length?report.trend.map(point=><div key={point.label}><span>{title(point.label)}</span><div className="analytics-track"><i style={{width:`${Math.max(0,Math.min(100,point.value))}%`}}/></div><strong>{point.value}%</strong></div>):<p className="analytics-empty">No trend indicators are available.</p>}</div>
      </section>
      <section className="analytics-panel" aria-labelledby="department-performance-title">
        <header><h2 id="department-performance-title">Department performance</h2><p>Attendance rate, team size and current leader.</p></header>
        <div className="department-ranking">{report.departments.length?report.departments.map(department=><article key={department.id}><div><strong>{department.name}</strong><span>{number.format(department.memberCount)} members · {department.leader}</span></div><div><strong>{department.attendanceRate}%</strong><span className={`status-pill ${department.attendanceRate<70?"needs-attention":""}`}>{department.attendanceRate>=85?"High":department.attendanceRate>=70?"Stable":"Needs attention"}</span></div></article>):<p className="analytics-empty">No departments have members in this scope.</p>}</div>
      </section>
    </div>
    <section className="directory-panel analytics-table-panel" aria-labelledby="performance-report-title">
      <div className="panel-heading"><div><h2 id="performance-report-title">Performance report</h2><p>The exported CSV contains these same {report.indicators.length} filtered indicators.</p></div><span className="indicator-count">{report.indicators.length} indicators</span></div>
      <div className="table-scroll" tabIndex={0} aria-label="Scrollable analytics report"><table className="data-table analytics-table"><thead><tr><th scope="col">Category</th><th scope="col">Indicator</th><th scope="col">Current</th><th scope="col">Previous</th><th scope="col">Change</th><th scope="col">Status</th></tr></thead><tbody>{report.indicators.map(indicator=><tr key={`${indicator.category}-${indicator.indicator}`}><td>{title(indicator.category)}</td><td>{indicator.indicator}</td><td>{number.format(indicator.current)}</td><td>{number.format(indicator.previous)}</td><td className={indicator.change!=null&&indicator.change<0?"change-negative":"change-positive"}>{changeLabel(indicator.change,indicator.current)}</td><td><span className={`status-pill ${indicator.status==="Needs attention"?"needs-attention":""}`}>{indicator.status}</span></td></tr>)}</tbody></table></div>
    </section>
  </>;
}
