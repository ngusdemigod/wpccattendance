interface Env {
  WPCC_PROJECT_URL: string;
  WPCC_GIVING_WORKER_SECRET: string;
}

async function processAutoGive(env: Env, scheduledAt: number): Promise<void> {
  const endpoint = `${env.WPCC_PROJECT_URL.replace(/\/$/, '')}/functions/v1/process-auto-give`;
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-worker-secret': env.WPCC_GIVING_WORKER_SECRET,
    },
    body: JSON.stringify({ scheduled_at: new Date(scheduledAt).toISOString() }),
  });

  if (!response.ok) {
    const detail = (await response.text()).slice(0, 500);
    throw new Error(`Auto Give processing failed (${response.status}): ${detail}`);
  }
}

export default {
  async scheduled(controller: ScheduledController, env: Env, ctx: ExecutionContext) {
    ctx.waitUntil(processAutoGive(env, controller.scheduledTime));
  },
} satisfies ExportedHandler<Env>;
