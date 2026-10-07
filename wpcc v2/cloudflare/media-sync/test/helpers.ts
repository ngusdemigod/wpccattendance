import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { DatabaseSync } from "node:sqlite";
import type { Env, MirrorJob, QueueMessage } from "../src/types";

const MIGRATIONS_DIR = join(import.meta.dirname, "../migrations");
/** Every migration, in order, exactly as wrangler applies them. */
const MIGRATIONS = readdirSync(MIGRATIONS_DIR).filter((name) => name.endsWith(".sql")).sort().map((name) => readFileSync(join(MIGRATIONS_DIR, name), "utf8"));

/** A D1 stand-in backed by real SQLite, so the actual SQL is exercised. */
export class FakeD1 {
  readonly sqlite = new DatabaseSync(":memory:");
  /** Rows changed by writes since the last reset: shows whether a write really happened. */
  changes = 0;

  constructor() {
    for (const migration of MIGRATIONS) this.sqlite.exec(migration);
  }
  prepare(sql: string) {
    return new FakeStatement(this, sql, []);
  }
  async batch(statements: FakeStatement[]) {
    const results = [];
    for (const statement of statements) results.push(await statement.run());
    return results;
  }
  all<T = Record<string, unknown>>(sql: string, ...args: unknown[]): T[] {
    return this.sqlite.prepare(sql).all(...(args as never[])).map((row) => ({ ...row })) as T[];
  }
  resetChanges() {
    this.changes = 0;
  }
}

class FakeStatement {
  constructor(private d1: FakeD1, private sql: string, private args: unknown[]) {}
  bind(...args: unknown[]) {
    return new FakeStatement(this.d1, this.sql, args.map((value) => (value === undefined ? null : value)));
  }
  async run() {
    const info = this.d1.sqlite.prepare(this.sql).run(...(this.args as never[]));
    const changes = Number(info.changes);
    this.d1.changes += changes;
    return { success: true, meta: { changes } };
  }
  async all<T>() {
    return { results: this.d1.sqlite.prepare(this.sql).all(...(this.args as never[])).map((row) => ({ ...row })) as T[] };
  }
  async first<T>() {
    const row = this.d1.sqlite.prepare(this.sql).get(...(this.args as never[]));
    return (row ? { ...row } : null) as T | null;
  }
}

export class FakeR2 {
  objects = new Map<string, { bytes: ArrayBuffer; contentType?: string; cacheControl?: string }>();
  putOrder: string[] = [];
  deleted: string[] = [];

  async head(key: string) {
    return this.objects.has(key) ? ({ key } as R2Object) : null;
  }
  async get(key: string) {
    const object = this.objects.get(key);
    return object ? ({ key, body: new Response(object.bytes).body } as unknown as R2ObjectBody) : null;
  }
  async put(key: string, value: ArrayBuffer, options?: R2PutOptions) {
    const meta = options?.httpMetadata as R2HTTPMetadata | undefined;
    this.objects.set(key, { bytes: value, contentType: meta?.contentType, cacheControl: meta?.cacheControl });
    this.putOrder.push(key);
    return {} as R2Object;
  }
  /** Delete calls made, one entry per call: lets tests check batching. */
  deleteCalls: string[][] = [];
  async delete(keys: string | string[]) {
    const list = Array.isArray(keys) ? keys : [keys];
    this.deleteCalls.push(list);
    for (const key of list) {
      this.deleted.push(key);
      this.objects.delete(key);
    }
  }
  async list(options: { prefix?: string; limit?: number; cursor?: string } = {}) {
    const all = [...this.objects.keys()].filter((key) => key.startsWith(options.prefix ?? "")).sort();
    const start = options.cursor ? Number(options.cursor) : 0;
    const limit = options.limit ?? 1000;
    const slice = all.slice(start, start + limit);
    const truncated = start + limit < all.length;
    return { objects: slice.map((key) => ({ key })), truncated, cursor: truncated ? String(start + limit) : undefined };
  }
}

export class FakeQueue {
  sent: QueueMessage[] = [];
  async sendBatch(messages: { body: QueueMessage }[]) {
    this.sent.push(...messages.map((message) => message.body));
  }
  get mirrorJobs() {
    return this.sent.filter((message): message is MirrorJob => message.type === "mirror");
  }
}

export function fakeImages(options: { fail?: boolean; width?: number; height?: number } = {}) {
  return {
    async info() {
      return { format: "image/jpeg", fileSize: 10, width: options.width ?? 1200, height: options.height ?? 800 };
    },
    input() {
      return {
        transform: () => ({
          output: async () => {
            if (options.fail) throw new Error("transform unavailable");
            return { response: () => new Response(new Uint8Array([9, 9, 9]), { headers: { "content-type": "image/webp" } }) };
          },
        }),
      };
    },
  } as unknown as ImagesBinding;
}

export class FakeLimiter {
  allow = true;
  throws = false;
  keys: string[] = [];
  async limit({ key }: { key: string }) {
    this.keys.push(key);
    if (this.throws) throw new Error("limiter down");
    return { success: this.allow };
  }
}

export class FakeCache {
  store = new Map<string, Response>();
  async match(request: Request) {
    return this.store.get(request.url)?.clone();
  }
  async put(request: Request, response: Response) {
    this.store.set(request.url, response.clone());
  }
}

export function makeEnv(overrides: Partial<Env> = {}) {
  const db = new FakeD1();
  const media = new FakeR2();
  const queue = new FakeQueue();
  const limiter = new FakeLimiter();
  const env = {
    DB: db as unknown as D1Database,
    MEDIA: media as unknown as R2Bucket,
    IMAGES: fakeImages(),
    QUEUE: queue as unknown as Queue<QueueMessage>,
    API_LIMITER: limiter as unknown as RateLimit,
    MEDIA_PREFIX: "media-sync",
    ALLOWED_ORIGINS: "https://my.example.test,http://localhost:8801",
    FACEBOOK_PAGE_ID: "555000111",
    FACEBOOK_GRAPH_VERSION: "v24.0",
    YOUTUBE_CHANNEL_ID: "UCabcdefghijklmnopqrstuv",
    MAX_PHOTOS: "50",
    MAX_VIDEOS: "50",
    FACEBOOK_PAGE_ACCESS_TOKEN: "fb-token-secret",
    YOUTUBE_API_KEY: "yt-key-secret",
    ...overrides,
  } satisfies Env;
  return { env, db, media, queue, limiter };
}

export const photoJob = (overrides: Partial<MirrorJob> = {}): MirrorJob => ({
  type: "mirror",
  table: "photos",
  id: "100200300",
  source_url: "https://scontent-lhr8-1.xx.fbcdn.net/v/t39/photo.jpg?sig=abc",
  key: "media-sync/fb/photo-100200300",
  ...overrides,
});

export type Call = { url: string; method: string; headers: Record<string, string>; body?: string };

/** Replaces global fetch with a router; returns the recorded calls. */
export function mockFetch(route: (call: Call) => Response | Promise<Response>) {
  const calls: Call[] = [];
  const original = globalThis.fetch;
  globalThis.fetch = (async (input: RequestInfo | URL, init?: RequestInit) => {
    const call: Call = {
      url: String(input),
      method: init?.method ?? "GET",
      headers: Object.fromEntries(Object.entries((init?.headers as Record<string, string>) ?? {})),
      body: typeof init?.body === "string" ? init.body : undefined,
    };
    calls.push(call);
    return route(call);
  }) as typeof fetch;
  return { calls, restore: () => (globalThis.fetch = original) };
}

export const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

export const imageResponse = (type = "image/jpeg", status = 200) =>
  new Response(new Uint8Array([1, 2, 3, 4]), { status, headers: { "content-type": type } });

/** Facebook Graph photo fixture. */
export const fbPhoto = (id: string, createdTime = "2026-09-01T10:00:00+0000", extra: Record<string, unknown> = {}) => ({
  id,
  name: `Caption ${id}`,
  created_time: createdTime,
  link: `https://www.facebook.com/photo/?fbid=${id}`,
  images: [{ source: `https://scontent.xx.fbcdn.net/${id}.jpg?sig=1`, width: 1200, height: 800 }],
  ...extra,
});
