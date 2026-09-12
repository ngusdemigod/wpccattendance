import { createClient } from "npm:@supabase/supabase-js@2";

type SpotifyConfig = {
  client_id?: string;
  client_secret?: string;
  show_id?: string;
  sync_secret?: string;
};

type SpotifyEpisode = {
  id: string;
  name: string;
  description?: string;
  html_description?: string;
  duration_ms?: number;
  explicit?: boolean;
  release_date?: string;
  images?: Array<{ url?: string }>;
  external_urls?: { spotify?: string };
};

const jsonHeaders = {
  "Content-Type": "application/json",
  "Cache-Control": "no-store",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: jsonHeaders });
  }

  if (request.method !== "POST") {
    return response({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return response({ error: "Supabase runtime configuration is unavailable" }, 503);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data, error: configError } = await supabase.rpc(
    "media_spotify_sync_config",
  );
  const config = (data ?? {}) as SpotifyConfig;

  if (configError) {
    return response({ error: "Unable to load Spotify configuration" }, 503);
  }

  if (
    !config.client_id ||
    !config.client_secret ||
    !config.show_id ||
    !config.sync_secret
  ) {
    return response({ error: "Spotify configuration is incomplete" }, 503);
  }

  if (request.headers.get("x-sync-secret") !== config.sync_secret) {
    return response({ error: "Unauthorized" }, 401);
  }

  try {
    const accessToken = await getAccessToken(
      config.client_id,
      config.client_secret,
    );
    const episodes = await fetchAllEpisodes(
      config.show_id,
      accessToken,
      "NG",
    );
    const syncedAt = new Date().toISOString();

    const rows = episodes.map((episode) => ({
      provider: "spotify",
      provider_content_type: "episode",
      external_id: episode.id,
      collection_external_id: config.show_id,
      title: episode.name,
      description: episode.description ?? null,
      description_html: episode.html_description ?? null,
      duration_ms: episode.duration_ms ?? null,
      explicit: episode.explicit ?? false,
      source_published_at: normalizeReleaseDate(episode.release_date),
      artwork_url: episode.images?.[0]?.url ?? null,
      provider_url: episode.external_urls?.spotify ??
        `https://open.spotify.com/episode/${episode.id}`,
      embed_url: `https://open.spotify.com/embed/episode/${episode.id}?utm_source=generator`,
      status: "published",
      last_synced_at: syncedAt,
      raw_payload: episode,
      updated_at: syncedAt,
    }));

    if (rows.length > 0) {
      const { error: upsertError } = await supabase
        .from("media_sermons")
        .upsert(rows, { onConflict: "provider,external_id" });
      if (upsertError) throw upsertError;
    }

    const { error: stateError } = await supabase
      .from("media_sync_state")
      .upsert({
        provider: "spotify",
        collection_id: config.show_id,
        last_offset: episodes.length,
        last_synced_at: syncedAt,
        last_success_at: syncedAt,
        last_error: null,
        updated_at: syncedAt,
      }, { onConflict: "provider,collection_id" });
    if (stateError) throw stateError;

    return response({ ok: true, synced: episodes.length });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    await supabase.from("media_sync_state").upsert({
      provider: "spotify",
      collection_id: config.show_id,
      last_synced_at: new Date().toISOString(),
      last_error: message.slice(0, 1000),
      updated_at: new Date().toISOString(),
    }, { onConflict: "provider,collection_id" });

    console.error("Spotify sync failed", message);
    return response({ error: "Spotify synchronization failed" }, 502);
  }
});

async function getAccessToken(
  clientId: string,
  clientSecret: string,
): Promise<string> {
  const credentials = btoa(`${clientId}:${clientSecret}`);
  const tokenResponse = await fetch(
    "https://accounts.spotify.com/api/token",
    {
      method: "POST",
      headers: {
        Authorization: `Basic ${credentials}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: "grant_type=client_credentials",
    },
  );

  if (!tokenResponse.ok) {
    throw new Error(`Spotify token request failed (${tokenResponse.status})`);
  }

  const tokenData = await tokenResponse.json();
  if (!tokenData.access_token) {
    throw new Error("Spotify token response did not include an access token");
  }
  return tokenData.access_token as string;
}

async function fetchAllEpisodes(
  showId: string,
  accessToken: string,
  market: string,
): Promise<SpotifyEpisode[]> {
  const episodes: SpotifyEpisode[] = [];
  let nextUrl: string | null =
    `https://api.spotify.com/v1/shows/${encodeURIComponent(showId)}/episodes?market=${market}&limit=50&offset=0`;

  while (nextUrl) {
    const episodeResponse = await fetch(nextUrl, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!episodeResponse.ok) {
      throw new Error(
        `Spotify episodes request failed (${episodeResponse.status})`,
      );
    }

    const page = await episodeResponse.json();
    const items = Array.isArray(page.items)
      ? page.items.filter((item: SpotifyEpisode | null) => item?.id)
      : [];
    episodes.push(...items);
    nextUrl = typeof page.next === "string" ? page.next : null;

    if (episodes.length >= 1000) {
      nextUrl = null;
    }
  }

  return episodes;
}

function normalizeReleaseDate(value?: string): string | null {
  if (!value) return null;
  if (/^\d{4}$/.test(value)) return `${value}-01-01`;
  if (/^\d{4}-\d{2}$/.test(value)) return `${value}-01`;
  return /^\d{4}-\d{2}-\d{2}$/.test(value) ? value : null;
}

function response(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), { status, headers: jsonHeaders });
}

