import webpush from "npm:web-push@3.6.7";
import { createClient } from "jsr:@supabase/supabase-js@2";

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { "Content-Type": "application/json" },
});

const required = (name: string) => {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
};

type Delivery = { id: string; subscription_id: string | null };
type Subscription = { id: string; endpoint: string; p256dh_key: string; auth_key: string };

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const expectedSecret = Deno.env.get("PRAYER_DISPATCH_SECRET")?.trim();
  if (!expectedSecret) return json({ error: "Prayer dispatch is not configured" }, 503);
  if (req.headers.get("x-prayer-dispatch-secret") !== expectedSecret) return json({ error: "Unauthorized" }, 401);

  try {
    const supabase = createClient(required("SUPABASE_URL"), required("SUPABASE_SERVICE_ROLE_KEY"), {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    webpush.setVapidDetails(required("VAPID_SUBJECT"), required("VAPID_PUBLIC_KEY"), required("VAPID_PRIVATE_KEY"));

    const { error: materializeError } = await supabase.rpc("materialize_prayer_alert_occurrences", {});
    if (materializeError) throw materializeError;

    const { data: claimed, error: claimError } = await supabase.rpc("claim_due_prayer_alert_occurrences", { p_limit: 25 });
    if (claimError) throw claimError;

    let occurrencesProcessed = 0;
    let deliveriesSent = 0;
    let deliveriesFailed = 0;

    for (const occurrence of claimed ?? []) {
      const occurrenceId = String(occurrence.occurrence_id);
      const alertId = String(occurrence.prayer_alert_id);
      try {
        const { error: createError } = await supabase.rpc("create_prayer_alert_deliveries", { p_occurrence_id: occurrenceId });
        if (createError) throw createError;

        const [{ data: alert, error: alertError }, { data: deliveryRows, error: deliveryError }] = await Promise.all([
          supabase.from("prayer_alerts").select("id,title,push_title,push_body,duration_seconds,audio_title,vibration_enabled,snooze_minutes").eq("id", alertId).maybeSingle(),
          supabase.from("prayer_alert_deliveries").select("id,subscription_id").eq("occurrence_id", occurrenceId).in("status", ["pending", "failed"]),
        ]);
        if (alertError) throw alertError;
        if (deliveryError) throw deliveryError;
        if (!alert) throw new Error("Prayer alert not found");

        const deliveries = (deliveryRows ?? []) as Delivery[];
        const subscriptionIds = [...new Set(deliveries.map((d) => d.subscription_id).filter((v): v is string => Boolean(v)))];
        const subscriptionsById = new Map<string, Subscription>();
        if (subscriptionIds.length) {
          const { data: subscriptions, error: subscriptionError } = await supabase.from("push_subscriptions").select("id,endpoint,p256dh_key,auth_key").in("id", subscriptionIds).eq("is_active", true);
          if (subscriptionError) throw subscriptionError;
          for (const subscription of (subscriptions ?? []) as Subscription[]) subscriptionsById.set(subscription.id, subscription);
        }

        let occurrenceHadFailure = false;
        for (const delivery of deliveries) {
          if (!delivery.subscription_id) continue;
          const subscription = subscriptionsById.get(delivery.subscription_id);
          if (!subscription) {
            occurrenceHadFailure = true;
            deliveriesFailed++;
            await supabase.rpc("mark_prayer_alert_delivery_result", { p_delivery_id: delivery.id, p_status: "failed", p_provider_message_id: null, p_failure_code: "inactive_subscription" });
            continue;
          }

          const payload = JSON.stringify({
            title: alert.push_title || alert.title || "WPCC Prayer Alert",
            body: alert.push_body || "It is time to pray.",
            tag: `wpcc-prayer-${occurrenceId}`,
            vibration_enabled: alert.vibration_enabled !== false,
            snooze_minutes: alert.snooze_minutes ?? null,
            data: { path: `/prayer-alerts?occurrence=${encodeURIComponent(occurrenceId)}`, occurrence_id: occurrenceId, prayer_alert_id: alertId },
          });

          try {
            const response = await webpush.sendNotification({ endpoint: subscription.endpoint, keys: { p256dh: subscription.p256dh_key, auth: subscription.auth_key } }, payload, { TTL: 60 * 60 });
            deliveriesSent++;
            await Promise.all([
              supabase.rpc("mark_prayer_alert_delivery_result", { p_delivery_id: delivery.id, p_status: "sent", p_provider_message_id: `webpush:${response.statusCode}`, p_failure_code: null }),
              supabase.rpc("mark_push_subscription_success", { p_subscription_id: subscription.id }),
            ]);
          } catch (error) {
            occurrenceHadFailure = true;
            deliveriesFailed++;
            const statusCode = Number((error as { statusCode?: number })?.statusCode ?? 0);
            if (statusCode === 404 || statusCode === 410) await supabase.rpc("deactivate_push_subscription", { p_subscription_id: subscription.id });
            await supabase.rpc("mark_prayer_alert_delivery_result", { p_delivery_id: delivery.id, p_status: "failed", p_provider_message_id: null, p_failure_code: statusCode ? `webpush_${statusCode}` : "webpush_failed" });
          }
        }

        const complete = await supabase.rpc("mark_prayer_alert_occurrence_result", { p_occurrence_id: occurrenceId, p_success: !occurrenceHadFailure || deliveries.length === 0, p_failure_reason: occurrenceHadFailure ? "One or more Web Push deliveries failed" : null });
        if (complete.error) throw complete.error;
        occurrencesProcessed++;
      } catch (error) {
        console.error("prayer_occurrence_dispatch_failed", { occurrenceId, error });
        await supabase.rpc("mark_prayer_alert_occurrence_result", { p_occurrence_id: occurrenceId, p_success: false, p_failure_reason: "Prayer alert dispatch failed" });
      }
    }

    return json({ ok: true, occurrencesProcessed, deliveriesSent, deliveriesFailed });
  } catch (error) {
    console.error("dispatch_prayer_alerts_failed", error);
    return json({ error: "Prayer alert dispatch failed" }, 500);
  }
});
