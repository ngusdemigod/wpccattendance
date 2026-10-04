import { it, expect, vi, afterEach } from "vitest";
import { createMessageBatch, getQueueResult, createExecutionContext, waitOnExecutionContext } from "cloudflare:test";
import { env } from "cloudflare:workers";
import worker from "./index";
import type { RewardEvent } from "./protocol";
const event: RewardEvent={id:"10000000-0000-0000-0000-000000000001",lease_token:"20000000-0000-0000-0000-000000000001",revision:1,kind:"giving"};
afterEach(()=>vi.restoreAllMocks());
it("does not acknowledge an award when the backend fails",async()=>{
 vi.spyOn(globalThis,"fetch").mockResolvedValue(new Response("unavailable",{status:503}));
 const batch=createMessageBatch<RewardEvent>("wpcc-rewards",[{id:"message",timestamp:new Date(),body:event,attempts:1}]);
 const ctx=createExecutionContext();
 await worker.queue(batch,env);
 const result=await getQueueResult(batch,ctx);
 expect(result.retryBatch.retry).toBe(true);
 expect(result.ackAll).toBe(false);
});
it("acknowledges only after successful settlement",async()=>{
 const fetch=vi.spyOn(globalThis,"fetch").mockResolvedValue(Response.json({data:[{status:"duplicate"}]}));
 const batch=createMessageBatch<RewardEvent>("wpcc-rewards",[{id:"message",timestamp:new Date(),body:event,attempts:2}]);
 const ctx=createExecutionContext();
 await worker.queue(batch,env);
 const result=await getQueueResult(batch,ctx);
 expect(result.ackAll).toBe(true);
 expect(JSON.parse(fetch.mock.calls[0][1]!.body as string).events[0].points).toBe(30);
});
it("offers no public HTTP trigger for awards",async()=>{
 expect((await worker.fetch(new Request("https://example.com/claim",{method:"POST"}),env)).status).toBe(404);
 expect((await worker.fetch(new Request("https://example.com/prayer",{method:"POST"}),env)).status).toBe(401);
});

it("cron claims work and sends the claim without settling it",async()=>{
 const fetch=vi.spyOn(globalThis,"fetch").mockResolvedValue(Response.json({data:[event]}));
 const send=vi.spyOn(env.REWARDS_QUEUE,"sendBatch").mockResolvedValue({metadata:{metrics:{backlogCount:0,backlogBytes:0}}});
 await worker.scheduled({scheduledTime:Date.UTC(2026,8,24,10,1),cron:"* * * * *",noRetry(){}},env);
 expect(send).toHaveBeenCalledWith([{body:event,contentType:"json"}]);
 expect(fetch).toHaveBeenCalledTimes(1);
 expect(JSON.parse(fetch.mock.calls[0][1]!.body as string).action).toBe("claim");
});
it("a queue send failure leaves the claim recoverable through its lease",async()=>{
 vi.spyOn(globalThis,"fetch").mockResolvedValue(Response.json({data:[event]}));
 vi.spyOn(env.REWARDS_QUEUE,"sendBatch").mockRejectedValue(new Error("queue unavailable"));
 await expect(worker.scheduled({scheduledTime:Date.UTC(2026,8,24,10,1),cron:"* * * * *",noRetry(){}},env)).rejects.toThrow("queue unavailable");
});
