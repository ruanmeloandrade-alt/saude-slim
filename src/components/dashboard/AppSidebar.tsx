import {
  BarChart3,
  Bot,
  ChevronDown,
  ClipboardList,
  HeartPulse,
  History,
  Inbox,
  LogOut,
  Mail,
  Megaphone,
  Menu,
  MessageSquareText,
  Package,
  Plug,
  RotateCcw,
  Settings,
  Share2,
  ShoppingCart,
  Tags,
  Target,
  Truck,
  Users,
  X,
  type LucideIcon,
} from "lucide-react";
import { useEffect, useState, type ReactNode } from "react";
import { Link, useRouterState } from "@tanstack/react-router";
import { cn } from "@/lib/utils";
import { useSessionHeartbeat } from "@/hooks/use-session-heartbeat";

interface NavItem {
  label: string;
  icon: LucideIcon;
  to?: string;
  href?: string;
  disabled?: boolean;
  activeWhen?: (path: string) => boolean;
}

interface NavGroup {
  label: string;
  icon: LucideIcon;
  to?: string;
  defaultOpen?: boolean;
  activeWhen?: (path: string) => boolean;
  children: NavItem[];
}

const HOME_GROUP: NavGroup = {
  label: "Home",
  icon: BarChart3,
  defaultOpen: true,
  activeWhen: (path) => path === "/saude-slim" || path.startsWith("/painel"),
  children: [
    { label: "Histórico de Vendas", icon: BarChart3, to: "/saude-slim", activeWhen: (path) => path === "/saude-slim" },
    { label: "Dashboard detalhada", icon: History, to: "/painel", activeWhen: (path) => path.startsWith("/painel") },
  ],
};

const PEDIDOS_GROUP: NavGroup = {
  label: "Vendas",
  icon: ClipboardList,
  to: "/pedidos",
  defaultOpen: true,
  activeWhen: (path) => path.startsWith("/pedidos") || path.startsWith("/crm/empresas") || path.startsWith("/crm/estoque") || path.startsWith("/crm/produtos") || path.startsWith("/disparo-em-massa"),
  children: [
    { label: "Pedidos", icon: ClipboardList, to: "/pedidos", activeWhen: (path) => path.startsWith("/pedidos") },
    { label: "Fornecedores", icon: Truck, to: "/crm/empresas", activeWhen: (path) => path.startsWith("/crm/empresas") },
    { label: "Estoque", icon: Package, to: "/crm/estoque", activeWhen: (path) => path.startsWith("/crm/estoque") },
    { label: "Produtos", icon: ShoppingCart, to: "/crm/produtos", activeWhen: (path) => path.startsWith("/crm/produtos") },
    { label: "Disparo em massa", icon: Megaphone, to: "/disparo-em-massa", activeWhen: (path) => path.startsWith("/disparo-em-massa") },
  ],
};

const CRM_GROUP: NavGroup = {
  label: "CRM",
  icon: Tags,
  defaultOpen: false,
  activeWhen: (path) => path.startsWith("/crm/funis-de-venda") || path.startsWith("/crm/leads") || path.startsWith("/crm/publicos") || path.startsWith("/crm/automacoes") || path.startsWith("/crm/agente-ia") || path.startsWith("/inbox"),
  children: [
    { label: "Funil de vendas", icon: Tags, to: "/crm/funis-de-venda", activeWhen: (path) => path.startsWith("/crm/funis-de-venda") },
    { label: "Clientes", icon: Users, to: "/crm/leads", activeWhen: (path) => path.startsWith("/crm/leads") },
    { label: "Inbox", icon: Inbox, to: "/inbox/leads", activeWhen: (path) => path.startsWith("/inbox") },
    { label: "Automações", icon: RotateCcw, to: "/crm/automacoes", activeWhen: (path) => path.startsWith("/crm/automacoes") },
    { label: "Cérebro IA", icon: Bot, to: "/crm/agente-ia", activeWhen: (path) => path.startsWith("/crm/agente-ia") },
    { label: "Públicos", icon: Users, to: "/crm/publicos", activeWhen: (path) => path.startsWith("/crm/publicos") },
  ],
};

const CONFIG_GROUP: NavGroup = {
  label: "Configurações",
  icon: Settings,
  defaultOpen: false,
  activeWhen: (path) => path.startsWith("/configuracoes") || path.startsWith("/integracoes"),
  children: [
    { label: "Geral", icon: Settings, to: "/configuracoes", activeWhen: (path) => path.startsWith("/configuracoes") },
    { label: "Integrações", icon: Plug, to: "/integracoes", activeWhen: (path) => path.startsWith("/integracoes") },
  ],
};

const PHASE_TWO_GROUP: NavGroup = {
  label: "Fase 2",
  icon: Target,
  defaultOpen: false,
  activeWhen: () => false,
  children: [
    { label: "Tracking avançado", icon: Target, disabled: true },
    { label: "E-mail Marketing", icon: Mail, disabled: true },
    { label: "Sms Marketing", icon: MessageSquareText, disabled: true },
    { label: "Redes Sociais", icon: Share2, disabled: true },
  ],
};

const OPERATION_GROUPS = [
  HOME_GROUP,
  PEDIDOS_GROUP,
  CRM_GROUP,
  CONFIG_GROUP,
  PHASE_TWO_GROUP,
];

async function handleLogout() {
  try {
    const { supabase } = await import("@/integrations/supabase/client");
    await supabase.auth.signOut();
  } catch {
    // ignore
  } finally {
    try {
      window.localStorage.clear();
      window.sessionStorage.clear();
    } catch {
      // ignore
    }
    window.location.assign("/auth");
  }
}

export function AppSidebar() {
  useSessionHeartbeat();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [openGroups, setOpenGroups] = useState<Record<string, boolean>>(() =>
    Object.fromEntries(OPERATION_GROUPS.map((group) => [group.label, group.defaultOpen !== false])),
  );
  const currentPath = useRouterState({ select: (state) => state.location.pathname });

  useEffect(() => {
    document.body.dataset.appShell = "1";
    return () => {
      delete document.body.dataset.appShell;
    };
  }, []);

  return (
    <>
      <button
        type="button"
        onClick={() => setMobileOpen(true)}
        className="fixed left-3 top-3 z-[70] grid h-9 w-9 place-items-center rounded-lg border border-slate-200 bg-white shadow-sm md:hidden"
        aria-label="Abrir menu"
      >
        <Menu className="h-4 w-4" />
      </button>

      {mobileOpen && (
        <button
          type="button"
          className="fixed inset-0 z-[79] bg-black/50 md:hidden"
          onClick={() => setMobileOpen(false)}
          aria-label="Fechar menu"
        />
      )}

      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-[80] flex h-screen w-[272px] flex-col border-r border-emerald-300/10 bg-[#0f172a] text-slate-100 shadow-xl transition-transform duration-200",
          "md:translate-x-0",
          mobileOpen ? "translate-x-0" : "-translate-x-full md:translate-x-0",
        )}
      >
        <div className="flex h-16 shrink-0 items-center gap-3 border-b border-white/10 px-5">
          <span className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-emerald-400 text-emerald-950">
            <HeartPulse className="h-5 w-5" />
          </span>
          <div className="min-w-0">
            <div className="truncate text-base font-black tracking-tight text-white">Saúde Slim</div>
            <div className="mt-0.5 text-[11px] font-medium text-slate-400">Sistema interno</div>
          </div>
          <button
            type="button"
            className="ml-auto rounded-lg p-1.5 text-slate-400 hover:bg-white/10 hover:text-white md:hidden"
            onClick={() => setMobileOpen(false)}
            aria-label="Fechar menu"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="border-b border-white/10 px-5 py-4">
          <div className="rounded-xl border border-emerald-300/15 bg-white/[0.06] px-3 py-3">
            <div className="text-xs font-bold text-white">Operação Saúde Slim</div>
            <div className="mt-1 text-[11px] leading-4 text-slate-400">Vendas, pedidos, estoque e recuperação.</div>
          </div>
        </div>

        <nav className="flex-1 overflow-y-auto overflow-x-hidden px-3 py-4">
          <div className="px-2 pb-2 text-[10px] font-black uppercase tracking-widest text-slate-500">Módulos</div>
          <div className="grid gap-1">
            {OPERATION_GROUPS.map((group) => (
              <SidebarGroup
                key={group.label}
                group={group}
                currentPath={currentPath}
                open={openGroups[group.label] ?? true}
                onToggle={() => setOpenGroups((current) => ({ ...current, [group.label]: !(current[group.label] ?? true) }))}
                onNavigate={() => setMobileOpen(false)}
              />
            ))}
          </div>
        </nav>

        <div className="border-t border-white/10 p-3">
          <button
            type="button"
            onClick={handleLogout}
            className="flex min-h-10 w-full items-center gap-3 rounded-lg px-3 text-sm font-semibold text-slate-400 transition-colors hover:bg-white/10 hover:text-white"
          >
            <LogOut className="h-4 w-4 shrink-0" />
            <span>Sair</span>
          </button>
        </div>
      </aside>

      <div className="hidden w-[272px] shrink-0 md:block" aria-hidden="true" />
    </>
  );
}

function SidebarGroup({
  group,
  currentPath,
  open,
  onToggle,
  onNavigate,
}: {
  group: NavGroup;
  currentPath: string;
  open: boolean;
  onToggle: () => void;
  onNavigate: () => void;
}) {
  const active = group.activeWhen?.(currentPath) ?? false;
  const expanded = open || active;
  const Icon = group.icon;

  return (
    <div className="grid gap-1">
      <div className="flex items-center gap-1">
        {group.to ? (
          <Link
            to={group.to as never}
            onClick={onNavigate}
            className={cn(
              "flex min-h-10 flex-1 items-center gap-3 rounded-lg px-3 text-sm font-semibold transition-colors",
              active ? "bg-emerald-400 text-slate-950 shadow-sm" : "text-slate-100 hover:bg-white/12 hover:text-white",
            )}
          >
            <Icon className={cn("h-4 w-4 shrink-0", active ? "text-slate-950" : "text-slate-200")} />
            <span className="truncate">{group.label}</span>
          </Link>
        ) : (
          <button
            type="button"
            onClick={onToggle}
            className={cn(
              "flex min-h-10 flex-1 items-center gap-3 rounded-lg px-3 text-left text-sm font-semibold transition-colors",
              active ? "bg-emerald-400 text-slate-950 shadow-sm" : "text-slate-100 hover:bg-white/12 hover:text-white",
            )}
          >
            <Icon className={cn("h-4 w-4 shrink-0", active ? "text-slate-950" : "text-slate-200")} />
            <span className="truncate">{group.label}</span>
          </button>
        )}
        <button
          type="button"
          onClick={onToggle}
          className="grid h-10 w-9 shrink-0 place-items-center rounded-lg text-slate-200 transition-colors hover:bg-white/12 hover:text-white"
          aria-label={expanded ? `Recolher ${group.label}` : `Expandir ${group.label}`}
        >
          <ChevronDown className={cn("h-4 w-4 transition-transform", expanded ? "rotate-180" : "rotate-0")} />
        </button>
      </div>

      {expanded && (
        <div className="ml-4 grid gap-1 border-l border-white/10 pl-2">
          {group.children.map((item) => (
            <SidebarLink key={`${group.label}-${item.label}-${item.to ?? "disabled"}`} item={item} currentPath={currentPath} onNavigate={onNavigate} compact />
          ))}
        </div>
      )}
    </div>
  );
}

function SidebarLink({
  item,
  currentPath,
  onNavigate,
  compact = false,
}: {
  item: NavItem;
  currentPath: string;
  onNavigate: () => void;
  compact?: boolean;
}) {
  const active = item.disabled ? false : item.activeWhen ? item.activeWhen(currentPath) : Boolean(item.to) && (currentPath === item.to || currentPath.startsWith(`${item.to}/`));
  const Icon = item.icon;

  return (
    <SidebarAnchor
      item={item}
      active={active}
      compact={compact}
      onNavigate={onNavigate}
    >
      <Icon className={cn(compact ? "h-3.5 w-3.5" : "h-4 w-4", "shrink-0", item.disabled ? "text-slate-500" : active ? "text-slate-950" : "text-slate-200")} />
      <span className="truncate">{item.label}</span>
    </SidebarAnchor>
  );
}

function SidebarAnchor({
  item,
  active,
  compact,
  onNavigate,
  children,
}: {
  item: NavItem;
  active: boolean;
  compact: boolean;
  onNavigate: () => void;
  children: ReactNode;
}) {
  const className = cn(
    "flex items-center gap-3 rounded-lg px-3 font-semibold transition-colors",
    compact ? "min-h-9 text-xs" : "min-h-10 text-sm",
    item.disabled
      ? "cursor-not-allowed text-slate-500 opacity-75"
      : active
        ? "bg-emerald-400 text-slate-950 shadow-sm"
        : "text-slate-100 hover:bg-white/12 hover:text-white",
  );

  if (item.disabled || !item.to) {
    return (
      <button type="button" disabled className={className} title="Disponível na Fase 2">
        {children}
      </button>
    );
  }

  if (item.href) {
    return (
      <a href={item.href} onClick={onNavigate} className={className}>
        {children}
      </a>
    );
  }

  return (
    <Link to={item.to as never} onClick={onNavigate} className={className}>
      {children}
    </Link>
  );
}
