import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import {
  Outlet,
  Link,
  createRootRouteWithContext,
  useRouter,
  useRouterState,
  HeadContent,
  Scripts,
} from "@tanstack/react-router";
import { useServerFn } from "@tanstack/react-start";
import { useEffect, useMemo, useState, type ReactNode } from "react";
import { Loader2 } from "lucide-react";
import { reportLovableError } from "../lib/lovable-error-reporting";
import { THEME_BOOTSTRAP_SCRIPT, ThemeProvider } from "../lib/theme";
import { CustomKpisProvider } from "../lib/custom-kpis";
import { ComparisonWidgetsProvider } from "../lib/comparison-widgets";
import { KpiRulesProvider } from "../lib/kpi-rules";
import { IdleLogoutGuard } from "../components/IdleLogoutGuard";
import { DeviceApprovalGate } from "../components/DeviceApprovalGate";
import { SupportRobot } from "../components/SupportRobot";
import { WorkflowSalesbotBillingEnhancer } from "../components/system/WorkflowSalesbotBillingEnhancer";
import { syncWorkspaceRegionalCache } from "../lib/workspace-currency-cache";

import appCss from "../styles.css?url";

function NotFoundComponent() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="max-w-md text-center">
        <h1 className="text-7xl font-bold text-foreground">404</h1>
        <h2 className="mt-4 text-xl font-semibold text-foreground">Página não encontrada</h2>
        <p className="mt-2 text-sm text-muted-foreground">A página que você procura não existe ou foi movida.</p>
        <div className="mt-6">
          <Link to="/" className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90">Ir para o início</Link>
        </div>
      </div>
    </div>
  );
}

function ErrorComponent({ error, reset }: { error: Error; reset: () => void }) {
  console.error(error);
  const router = useRouter();
  useEffect(() => { reportLovableError(error, { boundary: "tanstack_root_error_component" }); }, [error]);
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="max-w-md text-center">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">Não foi possível carregar esta página</h1>
        <p className="mt-2 text-sm text-muted-foreground">Ocorreu um erro ao carregar este conteúdo. Tente novamente ou volte para o início.</p>
        <div className="mt-6 flex flex-wrap justify-center gap-2">
          <button onClick={() => { router.invalidate(); reset(); }} className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90">Tentar novamente</button>
          <a href="/" className="inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium text-foreground transition-colors hover:bg-accent">Ir para o início</a>
        </div>
      </div>
    </div>
  );
}

export const Route = createRootRouteWithContext<{ queryClient: QueryClient }>()({
  head: () => ({
    meta: [
      { charSet: "utf-8" },
      { name: "viewport", content: "width=device-width, initial-scale=1" },
      { title: "Saúde Slim | Sistema interno" },
      { name: "description", content: "Sistema interno da Saúde Slim para vendas, pedidos, estoque, atendimento e automações." },
      { name: "author", content: "Saúde Slim" },
      { property: "og:title", content: "Saúde Slim | Sistema interno" },
      { property: "og:description", content: "Sistema interno da Saúde Slim para vendas, pedidos, estoque, atendimento e automações." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
      { name: "twitter:title", content: "Saúde Slim | Sistema interno" },
      { name: "twitter:description", content: "Sistema interno da Saúde Slim para vendas, pedidos, estoque, atendimento e automações." },
    ],
    links: [
      { rel: "stylesheet", href: appCss },
      { rel: "icon", href: "/favicon.ico" },
      { rel: "preconnect", href: "https://fonts.googleapis.com" },
      { rel: "preconnect", href: "https://fonts.gstatic.com", crossOrigin: "anonymous" },
      { rel: "stylesheet", href: "https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@500;600;700&family=DM+Sans:opsz,wght@9..40,400;9..40,500;9..40,600&display=swap" },
    ],
  }),
  shellComponent: RootShell,
  component: RootComponent,
  notFoundComponent: NotFoundComponent,
  errorComponent: ErrorComponent,
});

function RootShell({ children }: { children: ReactNode }) {
  return (
    <html lang="pt-BR" translate="no" className="notranslate">
      <head>
        <meta name="google" content="notranslate" />
        <script dangerouslySetInnerHTML={{ __html: THEME_BOOTSTRAP_SCRIPT }} />
        <HeadContent />
      </head>
      <body>{children}<Scripts /></body>
    </html>
  );
}

const PUBLIC_ROUTES = new Set(["/", "/login", "/privacidade", "/termos", "/data-deletion", "/documentacao", "/afiliados", "/sobre"]);

function isPublicPath(path: string) {
  return PUBLIC_ROUTES.has(path) || path === "/blog" || path.startsWith("/blog/") || path.startsWith("/l/");
}

const COPILOT_EXCLUDED_PATHS = new Set(["/contas", "/auth", "/checkout", "/checkout-retorno", "/completa", "/recuperar-acesso", "/sem-acesso"]);
const COPILOT_EXCLUDED_PREFIXES = ["/partners", "/afiliado/", "/auth/", "/convite/", "/f/", "/r/"];

export function isCopilotAllowedPath(path: string) {
  if (isPublicPath(path) || COPILOT_EXCLUDED_PATHS.has(path)) return false;
  return !COPILOT_EXCLUDED_PREFIXES.some((prefix) => path === prefix || path.startsWith(prefix));
}

function ConditionalSupportRobot() {
  const path = useRouterState({ select: (state) => state.location.pathname });
  if (!isCopilotAllowedPath(path)) return null;
  return <SupportRobot />;
}

function HomepageResourceLinks() {
  const path = useRouterState({ select: (state) => state.location.pathname });
  if (path !== "/") return null;
  return (
    <div className="border-t border-slate-200 bg-white px-4 py-4 text-[11px] text-slate-500 sm:px-5 md:px-8">
      <div className="mx-auto flex max-w-[1320px] flex-wrap items-center gap-x-5 gap-y-2">
        <span className="font-semibold text-slate-700">Recursos</span>
        <Link to="/documentacao" className="font-medium hover:text-slate-900">Documentação</Link>
        <Link to="/afiliados" className="font-medium hover:text-slate-900">Afiliados</Link>
      </div>
    </div>
  );
}

function CheckoutCompatibilityGuard({ children }: { children: ReactNode }) {
  const path = useRouterState({ select: (state) => state.location.pathname });
  const redirectTarget = useMemo(() => {
    if (typeof window === "undefined" || path !== "/checkout") return null;
    const params = new URLSearchParams(window.location.search);
    const sessionId = params.get("session_id")?.trim();
    if (sessionId) {
      const target = new URL("/checkout-retorno", window.location.origin);
      target.searchParams.set("session_id", sessionId);
      return `${target.pathname}${target.search}`;
    }
    if (params.get("plan") === "teste") return "/configuracoes";
    return null;
  }, [path]);

  useEffect(() => {
    if (redirectTarget) window.location.replace(redirectTarget);
  }, [redirectTarget]);

  if (redirectTarget) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background">
        <Loader2 className="h-7 w-7 animate-spin text-primary" />
      </div>
    );
  }
  return <>{children}</>;
}

const SAUDE_SLIM_MIGRATED_PATHS = new Set([
  "/auth", "/saude-slim", "/pedidos", "/crm/estoque", "/crm/produtos", "/crm/leads",
]);
function RootComponent() {
  const { queryClient } = Route.useRouteContext();
  const path = useRouterState({ select: (state) => state.location.pathname });
  const migratedRoute = SAUDE_SLIM_MIGRATED_PATHS.has(path);
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider><CustomKpisProvider><ComparisonWidgetsProvider><KpiRulesProvider>
        <IdleLogoutGuard />
        {!migratedRoute && <DeviceApprovalGate />}
        {!migratedRoute && <ConditionalSupportRobot />}
        {!migratedRoute && <WorkflowSalesbotBillingEnhancer />}
        <CheckoutCompatibilityGuard><AuthGate><Outlet /><HomepageResourceLinks /></AuthGate></CheckoutCompatibilityGuard>
      </KpiRulesProvider></ComparisonWidgetsProvider></CustomKpisProvider></ThemeProvider>
    </QueryClientProvider>
  );
}

function AuthGate({ children }: { children: ReactNode }) {
  const router = useRouter();
  const path = useRouterState({ select: (state) => state.location.pathname });
  const isPublicRoute = isPublicPath(path);
  const [initializing, setInitializing] = useState(true);

  useEffect(() => {
    if (typeof window === "undefined") return;

    let isMounted = true;
    let unsubscribeAuth: (() => void) | undefined;

    void import("@/integrations/supabase/client").then(({ supabase }) => {
      if (!isMounted) return;

      const check = async () => {
        try {
          const { data, error } = await supabase.auth.getSession();
          if (!isMounted) return;
          const currentPath = window.location.pathname;
          const isAuthRoute = currentPath === "/auth" || currentPath.startsWith("/auth/");
          const currentIsPublic = isPublicPath(currentPath);
          if (error) {
            console.error("AuthGate session error:", error);
            if (!isAuthRoute && !currentIsPublic) window.location.replace("/auth");
          } else if (!data.session && !isAuthRoute && !currentIsPublic) {
            window.location.replace("/auth");
          } else if (data.session && isAuthRoute) {
            window.location.replace("/saude-slim");
          } else if (data.session && !currentIsPublic) {
            try {
              await syncWorkspaceRegionalCache();
            } catch (regionalError) {
              console.error("Saúde Slim regional settings sync:", regionalError);
            }

          }
        } catch (err) {
          console.error("AuthGate check failed:", err);
        } finally {
          if (isMounted) setInitializing(false);
        }
      };

      void check();
      const { data: sub } = supabase.auth.onAuthStateChange((event) => {
        if (!isMounted) return;
        if (event === "SIGNED_OUT" && window.location.pathname !== "/") window.location.replace("/auth");
        if (event === "SIGNED_IN" || event === "INITIAL_SESSION") {
          router.invalidate();
          if (event === "SIGNED_IN") {
            void (async () => {
              try {
                const [{ recordSecurityEvent }, { getDeviceKey }] = await Promise.all([
                  import("@/lib/security-settings.functions"),
                  import("@/hooks/use-session-heartbeat"),
                ]);
                await recordSecurityEvent({ data: { type: "login", device_key: getDeviceKey() } });
              } catch { /* silencioso */ }
            })();
          }
        }
      });
      unsubscribeAuth = () => sub.subscription.unsubscribe();
    });

    return () => {
      isMounted = false;
      unsubscribeAuth?.();
    };
  }, [router]);

  if (isPublicRoute) return <>{children}</>;
  if (initializing) return <div className="flex min-h-screen items-center justify-center bg-background"><Loader2 className="h-7 w-7 animate-spin text-primary" /></div>;
  return <>{children}</>;
}
