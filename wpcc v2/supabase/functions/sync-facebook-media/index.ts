import { createClient } from "npm:@supabase/supabase-js@2";
import { getSupabaseServiceKey, getRequiredEnv } from "../_shared/mail.ts";

const reply = (body: object, status = 200) => new Response(JSON.stringify(body), {
  status, headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
});

type Photo = { id: string; name?: string; created_time?: string; link?: string;
  images?: { source: string }[] };

Deno.serve(async (request) => {
  if (request.method !== "POST") return reply({error: "Method not allowed"}, 405);
  const secret = Deno.env.get("FACEBOOK_SYNC_SECRET");
  if (!secret || request.headers.get("x-sync-secret") !== secret) return reply({error: "Unauthorized"}, 401);
  try {
    const token = getRequiredEnv("FACEBOOK_PAGE_ACCESS_TOKEN");
    const page = getRequiredEnv("FACEBOOK_PAGE_ID");
    const version = getRequiredEnv("FACEBOOK_GRAPH_VERSION");
    if (!/^v[0-9]+\.[0-9]+$/.test(version) || !/^[0-9]+$/.test(page)) throw new Error("Invalid configuration");
    const client = createClient(getRequiredEnv("SUPABASE_URL"), getSupabaseServiceKey(), {
      auth: {persistSession: false, autoRefreshToken: false},
    });
    let after: string | undefined;
    let count = 0;
    // Bounded incremental sync. No token or upstream next URL is stored in the feed.
    for (let batch = 0; batch < 10; batch++) {
      const url = new URL(`https://graph.facebook.com/${version}/${page}/photos`);
      url.searchParams.set("type", "uploaded");
      url.searchParams.set("fields", "id,name,created_time,images,link");
      url.searchParams.set("limit", "100");
      if (after) url.searchParams.set("after", after);
      const response = await fetch(url, {headers: {Authorization: `Bearer ${token}`}, signal: AbortSignal.timeout(20000)});
      if (!response.ok) return reply({error: "Facebook sync failed; check Page permissions and token"}, 502);
      const payload = await response.json() as {data: Photo[]; paging?: {next?: string; cursors?: {after?: string}}};
      if (!Array.isArray(payload.data)) throw new Error("Invalid Facebook response");
      const rows = payload.data.filter(photo => photo.images?.length && photo.link).map(photo => ({
        source_id: photo.id, page_id: page, caption: photo.name ?? '',
        image_url: photo.images![0].source, permalink: photo.link!,
        published_at: photo.created_time ?? null, synced_at: new Date().toISOString(), is_active: true,
      }));
      if (rows.some(row => !row.image_url.startsWith('https://') || !row.permalink.startsWith('https://'))) throw new Error('Invalid media URL');
      if (rows.length) {
        const {error} = await client.from('community_media_feed').upsert(rows, {onConflict: 'source_id'});
        if (error) throw new Error('Feed write failed');
        count += rows.length;
      }
      after = payload.paging?.next ? payload.paging?.cursors?.after : undefined;
      if (!after) break;
    }
    return reply({synced: count, has_more: Boolean(after)});
  } catch {
    return reply({error: "Media sync unavailable; check server configuration"}, 503);
  }
});
