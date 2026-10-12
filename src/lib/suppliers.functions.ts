import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";

type AnySb = { from: (t: string) => any };

async function activeWorkspace(sb: AnySb, userId: string): Promise<string> {
  const { data } = await sb.from("profiles").select("current_workspace_id").eq("id", userId).maybeSingle();
  const id = (data as { current_workspace_id?: string } | null)?.current_workspace_id;
  if (!id) throw new Error("Workspace ativo não encontrado.");
  return id;
}

export type SupplierProductCost = {
  id: string;
  supplierId: string;
  productId: string;
  productName: string;
  productSku: string;
  salePrice: number;
  cost: number;
  minQuantity: number;
  leadTimeDays: number | null;
  notes: string | null;
  active: boolean;
};

const SupplierIdSchema = z.object({ supplierId: z.string().uuid() });

export const listSupplierProductCosts = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => SupplierIdSchema.parse(d))
  .handler(async ({ data, context }): Promise<{ rows: SupplierProductCost[]; setupRequired?: boolean }> => {
    const sb = context.supabase as unknown as AnySb;
    const wsId = await activeWorkspace(sb, context.userId);
    const { data: rows, error } = await sb
      .from("supplier_product_costs")
      .select("id, supplier_id, product_id, cost, min_quantity, lead_time_days, notes, active, products(name, sku, price, promo_price)")
      .eq("workspace_id", wsId)
      .eq("supplier_id", data.supplierId)
      .order("created_at", { ascending: false });

    if (error) {
      if (String(error.message ?? "").includes("supplier_product_costs")) return { rows: [], setupRequired: true };
      throw new Error(error.message);
    }

    return {
      rows: ((rows ?? []) as any[]).map((row) => ({
        id: row.id,
        supplierId: row.supplier_id,
        productId: row.product_id,
        productName: row.products?.name ?? "Produto",
        productSku: row.products?.sku ?? "",
        salePrice: Number(row.products?.promo_price ?? row.products?.price ?? 0),
        cost: Number(row.cost ?? 0),
        minQuantity: Number(row.min_quantity ?? 1),
        leadTimeDays: row.lead_time_days == null ? null : Number(row.lead_time_days),
        notes: row.notes ?? null,
        active: row.active !== false,
      })),
    };
  });

const SaveSupplierProductCostSchema = z.object({
  id: z.string().uuid().optional(),
  supplierId: z.string().uuid(),
  productId: z.string().uuid(),
  cost: z.number().min(0),
  minQuantity: z.number().int().min(1).default(1),
  leadTimeDays: z.number().int().min(0).nullable().optional(),
  notes: z.string().max(1000).nullable().optional(),
  active: z.boolean().default(true),
});

export const saveSupplierProductCost = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => SaveSupplierProductCostSchema.parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as AnySb;
    const wsId = await activeWorkspace(sb, context.userId);
    const patch = {
      workspace_id: wsId,
      supplier_id: data.supplierId,
      product_id: data.productId,
      cost: data.cost,
      min_quantity: data.minQuantity,
      lead_time_days: data.leadTimeDays ?? null,
      notes: data.notes || null,
      active: data.active,
    };

    if (data.id) {
      const { error } = await sb
        .from("supplier_product_costs")
        .update(patch)
        .eq("id", data.id)
        .eq("workspace_id", wsId);
      if (error) throw new Error(error.message);
      return { id: data.id };
    }

    const { data: row, error } = await sb
      .from("supplier_product_costs")
      .upsert(patch, { onConflict: "workspace_id,supplier_id,product_id" })
      .select("id")
      .single();
    if (error) throw new Error(error.message);
    return { id: (row as { id: string }).id };
  });

export const deleteSupplierProductCost = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((d: unknown) => z.object({ id: z.string().uuid() }).parse(d))
  .handler(async ({ data, context }) => {
    const sb = context.supabase as unknown as AnySb;
    const wsId = await activeWorkspace(sb, context.userId);
    const { error } = await sb.from("supplier_product_costs").delete().eq("id", data.id).eq("workspace_id", wsId);
    if (error) throw new Error(error.message);
    return { ok: true };
  });
