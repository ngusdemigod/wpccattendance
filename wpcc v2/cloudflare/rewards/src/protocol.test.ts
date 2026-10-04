import { describe, it, expect } from "vitest";
import { connectedInterval, signature, verifyTicket, pointsFor } from "./protocol";
describe("reward authentication and participation", () => {
 it("never credits missing, replayed, or disconnected time", () => {
  expect(connectedInterval(null,100000,0,200000)).toBe(0);
  expect(connectedInterval(50000,50000,0,200000)).toBe(0);
  expect(connectedInterval(10000,100001,0,200000)).toBe(0);
  expect(connectedInterval(10000,40000,0,200000)).toBe(30000);
  expect(connectedInterval(10000,40000,20000,30000)).toBe(10000);
 });
 it("rejects tampered, expired, and cross-purpose tickets", async () => {
  const secret="test-secret";
  const body=btoa(JSON.stringify({user:"10000000-0000-0000-0000-000000000001",occurrence:"20000000-0000-0000-0000-000000000001",start:0,end:10000,exp:9000,threshold:1}));
  const token=body+"."+await signature(secret,"prayer:"+body);
  expect(await verifyTicket(secret,token,1000)).not.toBeNull();
  expect(await verifyTicket(secret,token,9000)).toBeNull();
  expect(await verifyTicket("wrong-secret",token,1000)).toBeNull();
  expect(await verifyTicket(secret,body+"."+await signature(secret,body),1000)).toBeNull();
  expect(await verifyTicket(secret,"broken",1000)).toBeNull();
 });
 it("awards the same giving points regardless of amount",()=>{
  expect(pointsFor("giving")).toBe(30);
  expect(pointsFor("attendance")).toBe(30);
  expect(pointsFor("prayer")).toBe(30);
  expect(pointsFor("profile")).toBe(15);
 });
});
