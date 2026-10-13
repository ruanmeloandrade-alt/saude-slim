// @lovable.dev/vite-tanstack-config already includes the following — do NOT add them manually
// or the app will break with duplicate plugins:
//   - tanstackStart, viteReact, tailwindcss, tsConfigPaths, nitro (build-only using cloudflare as a default target),
//     componentTagger (dev-only), VITE_* env injection, @ path alias, React/TanStack dedupe,
//     error logger plugins, and sandbox detection (port/host/strictPort).
// You can pass additional config via defineConfig({ vite: { ... }, etc... }) if needed.
import { defineConfig } from "@lovable.dev/vite-tanstack-config";
import { mcpPlugin } from "@lovable.dev/mcp-js/stacks/tanstack/vite";
import { applySalesbotBuilderTransform } from "./scripts/salesbot-save-feedback-transform";
import { applySalesbotFlowLineUxTransform } from "./scripts/salesbot-flow-line-ux-transform";

const salesbotSaveFeedbackPlugin = {
  name: "mkton-salesbot-save-feedback",
  enforce: "pre" as const,
  transform(code: string, id: string) {
    const cleanId = id.replace(/\\/g, "/").split("?", 1)[0];
    if (cleanId?.endsWith("/src/components/automations/SalesbotBuilder.tsx")) {
      return {
        code: applySalesbotFlowLineUxTransform(applySalesbotBuilderTransform(code)),
        map: null,
      };
    }
    return null;
  },
};

const mcpPlugins = process.platform === "win32" ? [] : [mcpPlugin()];

export default defineConfig({
  // Saúde Slim: gerar servidor Node executável em hospedagem externa.
  // Github é a fonte do código; Nitro executa SSR/rotas/API no runtime Node.
  nitro: { preset: "node-server" },
  tanstackStart: {
    // Redirect TanStack Start's bundled server entry to src/server.ts (our SSR error wrapper).
    // nitro/vite builds from this
    server: { entry: "server" },
  },
  vite: {
    plugins: [salesbotSaveFeedbackPlugin, ...mcpPlugins],
  },
});
