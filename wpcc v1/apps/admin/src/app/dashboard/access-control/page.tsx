import {redirect} from 'next/navigation';
import type {SupabaseClient} from '@supabase/supabase-js';
import {createClient} from '@/lib/supabase/server';
import {can,resolveAdminContext} from '@/lib/permissions/admin-context';
import {AccessControlWorkspace} from '@/features/access-control/access-control-workspace';
export default async function AccessControlPage({searchParams}:{searchParams:Promise<Record<string,string|string[]|undefined>>}){const query=await searchParams,client=await createClient(),context=await resolveAdminContext(client);if(!context||!can(context,'administration.access_control.read'))redirect('/forbidden');const rpc=client as unknown as SupabaseClient,{data,error}=await rpc.rpc('dream_team_access_control_directory',{p_search:typeof query.q==='string'?query.q:null,p_preset:typeof query.role==='string'?query.role:null}),{data:changes}=await rpc.rpc('dream_team_access_control_recent_changes',{p_limit:50});if(error)return <div className='empty-state'><h3>Access Control unavailable</h3><p>{error.message}</p></div>;const payload=data as {administrators?:unknown[];eligible_members?:unknown[]};return <AccessControlWorkspace administrators={payload.administrators||[]} eligibleMembers={payload.eligible_members||[]} changes={Array.isArray(changes)?changes:[]} initialSelectedId={typeof query.selected==='string'?query.selected:''}/>}

