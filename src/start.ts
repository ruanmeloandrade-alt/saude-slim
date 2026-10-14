import { createStart } from "@tanstack/react-start";
import { renderErrorPage } from "./lib/error-page";

// The TanStack/Vite/Nitro build can lose the transitive
// createMiddleware named export. Use the factory exposed by createStart
// instead, preserving our function and request middleware.
export const startInstance = createStart(() => ({
  defaultSsr: false,
  functionMiddleware: [attachSupabaseAuth],
  requestMiddleware: [errorMiddleware],
}));

const attachSupabaseAuth = startInstance.createMiddleware({ type: "function" }).client(
  async ({ next }) => {
    let token: string | undefined;
    try {
      const { supabase } = await import("./integrations/supabase/client");
      const { data } = await supabase.auth.getSession();
      token = data.session?.access_token;
    } catch {
      token = undefined;
    }
    return next({
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    });
  },
);

const errorMiddleware = startInstance.createMiddleware().server(
  async ({ next, request }) => {
    const url = new URL(request.url);
    if (url.pathname.startsWith("/lovable/")) return next();
    try {
      return await next();
    } catch (error) {
      if (error != null && typeof error === "object" && "statusCode" in error) {
        throw error;
      }
      console.error(error);
      return new Response(renderErrorPage(), {
        status: 500,
        headers: { "content-type": "text/html; charset=utf-8" },
      });
    }
  },
);
