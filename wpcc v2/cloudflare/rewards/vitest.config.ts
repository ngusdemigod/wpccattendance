import { defineConfig } from "vitest/config";
import { cloudflareTest } from "@cloudflare/vitest-pool-workers";
export default defineConfig({ plugins: [cloudflareTest({ wrangler: { configPath: "./wrangler.jsonc" }, miniflare: { bindings: { WPCC_REWARDS_WORKER_SECRET: "test-only-not-a-production-secret" } } })] });
