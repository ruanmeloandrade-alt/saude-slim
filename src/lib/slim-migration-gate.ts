/** Keeps workers and business handlers idle during the final database cutover. */
export function slimMigrationGate(request: Request): Response | null {
  if (process.env.SLIM_MIGRATION_MAINTENANCE !== "true") return null;
  const path = new URL(request.url).pathname;
  const headers = { "content-type": "text/html; charset=utf-8", "cache-control": "no-store", "retry-after": "60" };
  return new Response('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Saúde Slim</title><body style="font-family:system-ui;background:#09090b;color:#fff;padding:10vw"><h1>Saúde Slim</h1><p>Estamos concluindo uma atualização. Aguarde alguns instantes e atualize a página.</p></body></html>', { status: path === "/" ? 200 : 503, headers });
}
