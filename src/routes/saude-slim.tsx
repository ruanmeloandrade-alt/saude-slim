import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { useMemo, useState } from "react";
import { BarChart3, ClipboardList, Eye, Search } from "lucide-react";
import { AppSidebar } from "@/components/dashboard/AppSidebar";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { getSaudeSlimSalesHistory, getSaudeSlimSalesProducts } from "@/lib/saude-slim-sales-client";
import type { DrilldownLead } from "@/lib/mock-dashboard";

type FilterOption = { value: string; label: string };

export const Route = createFileRoute("/saude-slim")({
  ssr: false,
  head: () => ({ meta: [{ title: "Histórico de Vendas · Saúde Slim" }, { name: "description", content: "Lista de vendas e pedidos da Saúde Slim." }] }),
  component: SalesHistoryPage,
});

function SalesHistoryPage() {
  const [query, setQuery] = useState("");
  const [dateFilter, setDateFilter] = useState("all");
  const [tagFilter, setTagFilter] = useState("all");
  const [originFilter, setOriginFilter] = useState("all");
  const [customFieldFilter, setCustomFieldFilter] = useState("all");
  const [pageSize, setPageSize] = useState(10);
  const [page, setPage] = useState(1);

  const dashboardQ = useQuery({
    queryKey: ["saude-slim", "sales-history"],
    queryFn: getSaudeSlimSalesHistory,
    retry: 1,
    staleTime: 30_000,
  });
  const productSalesQ = useQuery({
    queryKey: ["saude-slim", "sales-history-products"],
    queryFn: getSaudeSlimSalesProducts,
    retry: 1,
    staleTime: 30_000,
  });

  const productByLead = useMemo(() => {
    const map = new Map<string, string[]>();
    for (const row of productSalesQ.data?.rows ?? []) {
      for (const leadId of row.leadIds) {
        const list = map.get(leadId) ?? [];
        list.push(row.name);
        map.set(leadId, list);
      }
    }
    return map;
  }, [productSalesQ.data]);

  const rawSales = useMemo(() => (dashboardQ.data?.drilldownLeads ?? []).filter((lead) => lead.status_key === "won"), [dashboardQ.data]);

  const filterOptions = useMemo(() => {
    const dates = new Map<string, string>();
    const tags = new Set<string>();
    const origins = new Set<string>();
    const customFields = new Set<string>();

    for (const sale of rawSales) {
      const dateKey = toDateKey(sale.updated_at);
      if (dateKey) dates.set(dateKey, formatDateOnly(sale.updated_at));
      if (sale.origin) origins.add(sale.origin);
      for (const tag of sale.crm_tags) {
        if (tag) tags.add(tag);
      }
      for (const field of sale.custom_fields) {
        if (field.key || field.value) customFields.add(formatCustomFieldFilter(field));
      }
    }

    return {
      dates: [...dates.entries()].sort(([a], [b]) => b.localeCompare(a)).map(([value, label]) => ({ value, label })),
      tags: sortFilterOptions(tags),
      origins: sortFilterOptions(origins),
      customFields: sortFilterOptions(customFields),
    };
  }, [rawSales]);

  const sales = useMemo(() => {
    const rows = rawSales.filter((lead) => {
      const dateKey = toDateKey(lead.updated_at);
      const matchesDate = dateFilter === "all" || dateKey === dateFilter;
      const matchesTag = tagFilter === "all" || lead.crm_tags.includes(tagFilter);
      const matchesOrigin = originFilter === "all" || lead.origin === originFilter;
      const matchesCustomField = customFieldFilter === "all" || lead.custom_fields.some((field) => formatCustomFieldFilter(field) === customFieldFilter);
      return matchesDate && matchesTag && matchesOrigin && matchesCustomField;
    });
    const needle = query.trim().toLowerCase();
    if (!needle) return rows;
    return rows.filter((lead) => {
      const products = productByLead.get(lead.lead_id)?.join(" ") ?? "";
      const custom = lead.custom_fields.map((field) => `${field.key} ${field.value}`).join(" ");
      const haystack = [
        lead.name,
        lead.email,
        lead.phone,
        lead.origin,
        lead.stage_name,
        lead.funnel_name,
        lead.created_at,
        lead.updated_at,
        products,
        custom,
        lead.crm_tags.join(" "),
      ].join(" ").toLowerCase();
      return haystack.includes(needle);
    });
  }, [customFieldFilter, dateFilter, originFilter, productByLead, query, rawSales, tagFilter]);

  const totalPages = Math.max(1, Math.ceil(sales.length / pageSize));
  const safePage = Math.min(page, totalPages);
  const pageRows = sales.slice((safePage - 1) * pageSize, safePage * pageSize);
  const totalRevenue = sales.reduce((sum, lead) => sum + lead.value_brl, 0);
  const hasStructuredFilters = dateFilter !== "all" || tagFilter !== "all" || originFilter !== "all" || customFieldFilter !== "all";
  const resetFilters = () => {
    setQuery("");
    setDateFilter("all");
    setTagFilter("all");
    setOriginFilter("all");
    setCustomFieldFilter("all");
    setPage(1);
  };

  return (
    <div className="flex min-h-[100dvh] bg-background text-foreground md:h-screen md:overflow-hidden">
      <AppSidebar />
      <main className="flex-1 overflow-y-auto">
        <div className="mx-auto max-w-[1500px] space-y-5 px-4 py-6 lg:px-8">
          <header className="rounded-lg border border-border bg-card p-5">
            <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
              <div>
                <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-widest text-primary"><BarChart3 className="h-4 w-4" /> Módulos</div>
                <h1 className="mt-2 text-2xl font-semibold tracking-tight">Histórico de vendas</h1>
                <p className="mt-1 text-sm text-muted-foreground">Lista limpa das vendas ganhas, com busca por cliente, produto, data, tag, origem ou campo personalizado.</p>
              </div>
              <div className="grid gap-2 text-right sm:grid-cols-2 lg:min-w-[360px]">
                <Metric label="Vendas exibidas" value={sales.length.toLocaleString("pt-BR")} />
                <Metric label="Valor exibido" value={formatBRL(totalRevenue)} />
              </div>
            </div>
          </header>

          <section className="rounded-lg border border-border bg-card">
            <div className="flex flex-col gap-3 border-b border-border p-4">
              <div className="relative min-w-0 flex-1 lg:max-w-2xl">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  value={query}
                  onChange={(event) => { setQuery(event.target.value); setPage(1); }}
                  className="pl-9"
                  placeholder="Pesquisar por cliente, produto, data, tag ou campo personalizado"
                />
              </div>
              <div className="grid gap-3 xl:grid-cols-[1fr_auto] xl:items-end">
                <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-4">
                  <FilterSelect label="Data" value={dateFilter} onChange={(value) => { setDateFilter(value); setPage(1); }} options={filterOptions.dates} emptyLabel="Todas as datas" />
                  <FilterSelect label="Tag" value={tagFilter} onChange={(value) => { setTagFilter(value); setPage(1); }} options={filterOptions.tags} emptyLabel="Todas as tags" />
                  <FilterSelect label="Origem" value={originFilter} onChange={(value) => { setOriginFilter(value); setPage(1); }} options={filterOptions.origins} emptyLabel="Todas as origens" />
                  <FilterSelect label="Campo personalizado" value={customFieldFilter} onChange={(value) => { setCustomFieldFilter(value); setPage(1); }} options={filterOptions.customFields} emptyLabel="Todos os campos" />
                </div>
                <div className="flex flex-wrap items-center gap-2 xl:justify-end">
                  {(query || hasStructuredFilters) && <Button variant="outline" size="sm" onClick={resetFilters}>Limpar filtros</Button>}
                  <span className="text-xs text-muted-foreground">Por página</span>
                  <select value={pageSize} onChange={(event) => { setPageSize(Number(event.target.value)); setPage(1); }} className="h-10 rounded-md border border-input bg-background px-3 text-sm">
                    {[10, 20, 35, 50].map((size) => <option key={size} value={size}>{size}</option>)}
                  </select>
                  <Button asChild size="sm"><Link to="/pedidos"><ClipboardList className="h-4 w-4" /> Novo pedido</Link></Button>
                </div>
              </div>
            </div>

            {dashboardQ.error instanceof Error && <div className="m-4 rounded-md border border-destructive/40 bg-destructive/10 px-3 py-2 text-sm text-destructive">{dashboardQ.error.message}</div>}

            <div className="hidden md:block">
              <div className="grid grid-cols-[minmax(220px,1.2fr)_minmax(170px,1fr)_130px_140px_160px_110px] gap-3 border-b border-border bg-muted/35 px-4 py-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">
                <span>Cliente</span><span>Produto</span><span>Data</span><span>Origem/Tag</span><span>Campo personalizado</span><span className="text-right">Valor</span>
              </div>
              {pageRows.length ? pageRows.map((sale) => <SaleRow key={sale.lead_id} sale={sale} products={productByLead.get(sale.lead_id) ?? []} />) : <Empty loading={dashboardQ.isLoading || productSalesQ.isLoading} />}
            </div>

            <div className="md:hidden">
              {pageRows.length ? pageRows.map((sale) => <MobileSale key={sale.lead_id} sale={sale} products={productByLead.get(sale.lead_id) ?? []} />) : <Empty loading={dashboardQ.isLoading || productSalesQ.isLoading} />}
            </div>

            <div className="flex flex-col gap-3 border-t border-border px-4 py-3 sm:flex-row sm:items-center sm:justify-between">
              <div className="text-xs text-muted-foreground">Página {safePage} de {totalPages} · {sales.length.toLocaleString("pt-BR")} vendas</div>
              <div className="flex gap-2">
                <Button variant="outline" size="sm" disabled={safePage <= 1} onClick={() => setPage((current) => Math.max(1, current - 1))}>Anterior</Button>
                <Button variant="outline" size="sm" disabled={safePage >= totalPages} onClick={() => setPage((current) => Math.min(totalPages, current + 1))}>Próxima</Button>
              </div>
            </div>
          </section>
        </div>
      </main>
    </div>
  );
}

function SaleRow({ sale, products }: { sale: DrilldownLead; products: string[] }) {
  return (
    <div className="grid grid-cols-[minmax(220px,1.2fr)_minmax(170px,1fr)_130px_140px_160px_110px] items-center gap-3 border-b border-border px-4 py-3 text-sm last:border-b-0">
      <div className="min-w-0"><div className="truncate font-semibold">{sale.name}</div><div className="truncate text-xs text-muted-foreground">{sale.phone || sale.email || "Sem contato"}</div></div>
      <div className="truncate text-muted-foreground">{products.join(", ") || "Produto não vinculado"}</div>
      <div className="text-xs text-muted-foreground">{formatDate(sale.updated_at)}</div>
      <div className="min-w-0 text-xs"><div className="truncate">{sale.origin || "Origem não informada"}</div><div className="truncate text-muted-foreground">{sale.crm_tags[0] ?? "Sem tag"}</div></div>
      <div className="truncate text-xs text-muted-foreground">{sale.custom_fields[0] ? `${sale.custom_fields[0].key}: ${sale.custom_fields[0].value}` : "Sem campo"}</div>
      <div className="text-right font-semibold tabular-nums">{formatBRL(sale.value_brl)}</div>
    </div>
  );
}

function MobileSale({ sale, products }: { sale: DrilldownLead; products: string[] }) {
  return (
    <div className="border-b border-border p-4 last:border-b-0">
      <div className="flex items-start justify-between gap-3"><div className="min-w-0"><div className="truncate font-semibold">{sale.name}</div><div className="mt-1 text-xs text-muted-foreground">{products.join(", ") || "Produto não vinculado"}</div></div><div className="font-semibold">{formatBRL(sale.value_brl)}</div></div>
      <div className="mt-3 flex flex-wrap gap-2 text-[11px] text-muted-foreground"><span>{formatDate(sale.updated_at)}</span><span>{sale.origin || "Sem origem"}</span><span>{sale.crm_tags[0] ?? "Sem tag"}</span></div>
    </div>
  );
}

function Metric({ label, value }: { label: string; value: string }) {
  return <div className="rounded-md border border-border bg-background px-3 py-2"><div className="text-[11px] text-muted-foreground">{label}</div><div className="text-lg font-semibold tabular-nums">{value}</div></div>;
}

function FilterSelect({ label, value, onChange, options, emptyLabel }: { label: string; value: string; onChange: (value: string) => void; options: FilterOption[]; emptyLabel: string }) {
  return (
    <label className="grid gap-1 text-xs font-medium text-muted-foreground">
      <span>{label}</span>
      <select
        value={value}
        onChange={(event) => onChange(event.target.value)}
        className="h-10 min-w-0 rounded-md border border-input bg-background px-3 text-sm text-foreground"
      >
        <option value="all">{emptyLabel}</option>
        {options.map((option) => <option key={`${label}-${option.value}`} value={option.value}>{option.label}</option>)}
      </select>
    </label>
  );
}

function Empty({ loading }: { loading: boolean }) {
  return <div className="flex flex-col items-center justify-center gap-2 px-4 py-12 text-center text-sm text-muted-foreground"><Eye className="h-5 w-5" />{loading ? "Carregando vendas..." : "Nenhuma venda encontrada."}</div>;
}

function formatBRL(value: number): string {
  return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(value || 0);
}

function formatDate(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "Data não informada";
  return new Intl.DateTimeFormat("pt-BR", { dateStyle: "short", timeStyle: "short" }).format(date);
}

function formatDateOnly(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "Data não informada";
  return new Intl.DateTimeFormat("pt-BR", { dateStyle: "short" }).format(date);
}

function toDateKey(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function formatCustomFieldFilter(field: { key: string; value: string }): string {
  const key = field.key?.trim();
  const value = String(field.value ?? "").trim();
  if (key && value) return `${key}: ${value}`;
  return key || value;
}

function sortFilterOptions(values: Set<string>): FilterOption[] {
  return [...values]
    .filter(Boolean)
    .sort((a, b) => a.localeCompare(b, "pt-BR"))
    .map((value) => ({ value, label: value }));
}
