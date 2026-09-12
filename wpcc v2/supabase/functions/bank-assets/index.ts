import {
  getPrivateR2Config,
  presignR2,
  putPrivateObject,
} from "../_shared/private-r2.ts";

const assets: Record<string, { domain: string; key: string }> = {
  "gtbank": { domain: "gtbank.com", key: "assets/banks/gtbank.png" },
  "access-bank": { domain: "accessbankplc.com", key: "assets/banks/access-bank.png" },
  "opay": { domain: "opayweb.com", key: "assets/banks/opay.png" },
  "zenith-bank": { domain: "zenithbank.com", key: "assets/banks/zenith-bank.png" },
  "firstbank": { domain: "firstbankgroup.com", key: "assets/banks/firstbank.png" },
};

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Cache-Control": "public, max-age=86400, s-maxage=604800",
  "Content-Type": "image/png",
  "X-Content-Type-Options": "nosniff",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers });
  if (req.method !== "GET") return new Response("Method not allowed", { status: 405 });
  const asset = assets[new URL(req.url).searchParams.get("bank") || ""];
  if (!asset) return new Response("Unknown bank", { status: 404 });

  try {
    const r2 = getPrivateR2Config();
    let stored = await fetch(await presignR2(r2, "GET", asset.key));
    if (stored.status === 404) {
      const source = await fetch(`https://www.google.com/s2/favicons?domain=${asset.domain}&sz=128`);
      if (!source.ok) throw new Error("Bank logo source failed");
      await putPrivateObject(r2, asset.key, "image/png", new Uint8Array(await source.arrayBuffer()));
      stored = await fetch(await presignR2(r2, "GET", asset.key));
    }
    if (!stored.ok) throw new Error("Bank logo read failed");
    return new Response(stored.body, { status: 200, headers });
  } catch (error) {
    console.error("bank_asset_failed", error);
    return new Response("Asset unavailable", { status: 503 });
  }
});
