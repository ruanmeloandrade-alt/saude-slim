import { useQuery } from "@tanstack/react-query";
import { useServerFn } from "@tanstack/react-start";
import { getCurrentUserRoles } from "@/lib/auth.functions";

export function useIsAdmin() {
  const fn = useServerFn(getCurrentUserRoles);
  const q = useQuery({
    queryKey: ["auth", "roles"],
    queryFn: () => fn({}),
    staleTime: 5 * 60_000,
    retry: false,
  });
  return { isAdmin: !!q.data?.isAdmin, loaded: !q.isLoading };
}

export function useIsSuperAdmin() {
  const fn = useServerFn(getCurrentUserRoles);
  const q = useQuery({
    queryKey: ["auth", "roles"],
    queryFn: () => fn({}),
    staleTime: 5 * 60_000,
    retry: false,
  });
  const roles = q.data?.roles ?? [];
  return { isSuperAdmin: roles.includes("super_admin"), loaded: !q.isLoading };
}
