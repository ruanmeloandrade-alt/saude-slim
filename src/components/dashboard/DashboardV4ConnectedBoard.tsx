import { useQuery } from "@tanstack/react-query";
import { useServerFn } from "@tanstack/react-start";
import type { ComponentProps } from "react";
import { DashboardV4ConfigurableBoard } from "@/components/dashboard/DashboardV4ConfigurableBoard";
import { getActiveWorkspace } from "@/lib/workspace.functions";

type Props = Omit<ComponentProps<typeof DashboardV4ConfigurableBoard>, "workspaceId">;

/**
 * Active Dashboard V4 composition.
 *
 * Keeps the historical export used by /painel while restoring the configurable
 * widget layer. Workspace identity is resolved here so preferences stay scoped
 * correctly without making the route duplicate workspace plumbing.
 */
export function DashboardV4ConnectedBoard(props: Props) {
  const loadWorkspace = useServerFn(getActiveWorkspace);
  const workspaceQuery = useQuery({
    queryKey: ["active-workspace", "dashboard-v4-widget-settings"],
    queryFn: () => loadWorkspace(),
    staleTime: 5 * 60_000,
  });

  return <DashboardV4ConfigurableBoard {...props} workspaceId={workspaceQuery.data?.id} />;
}
