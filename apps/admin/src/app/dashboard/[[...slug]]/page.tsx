import { notFound } from "next/navigation";
import { DashboardPageTemplate } from "@/features/dashboard/page-template";
import { getDashboardPage } from "@/features/dashboard/page-config";
import { loadDashboardPageData } from "@/features/dashboard/queries";

export default async function DashboardPage({ params, searchParams }: { params: Promise<{ slug?: string[] }>; searchParams:Promise<Record<string,string|string[]|undefined>> }) {
  const { slug = [] } = await params;
  const query=await searchParams;
  const config = getDashboardPage(slug.join("/"));
  if (!config) notFound();
  const data = await loadDashboardPageData(slug.join("/"),{q:typeof query.q==="string"?query.q:undefined,status:typeof query.status==="string"?query.status:undefined,source:typeof query.source==="string"?query.source:undefined,priority:typeof query.priority==="string"?query.priority:undefined,range:typeof query.range==="string"?query.range:undefined,period:typeof query.period==="string"?query.period:undefined,session:typeof query.session==="string"?query.session:undefined,branch:typeof query.branch==="string"?query.branch:undefined,from:typeof query.from==="string"?query.from:undefined,to:typeof query.to==="string"?query.to:undefined,category:typeof query.category==="string"?query.category:undefined,page:typeof query.page==="string"?query.page:undefined,selected:typeof query.selected==="string"?query.selected:undefined,filter:typeof query.filter==="string"?query.filter:undefined,sort:typeof query.sort==="string"?query.sort:undefined});
  return <DashboardPageTemplate path={slug.join("/")} config={config} data={data}/>;
}
