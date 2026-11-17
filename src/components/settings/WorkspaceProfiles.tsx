import { useState, type FormEvent } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { useServerFn } from "@tanstack/react-start";
import { Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { createWorkspaceProfile, listWorkspaceProfiles, switchWorkspaceProfile } from "@/lib/workspace-profiles.functions";

export function WorkspaceProfiles({ activeId, activeName, canCreate }: {
  activeId: string;
  activeName: string;
  canCreate: boolean;
}) {
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");
  const list = useServerFn(listWorkspaceProfiles);
  const create = useServerFn(createWorkspaceProfile);
  const switchProfile = useServerFn(switchWorkspaceProfile);
  const profiles = useQuery({
    queryKey: ["workspace-profiles", activeId],
    queryFn: () => list(),
  });

  function reloadSettings() {
    window.history.replaceState(window.history.state, "", "/configuracoes#empresa");
    window.location.reload();
  }

  const creation = useMutation({
    mutationFn: () => create({ data: { name } }),
    onSuccess: reloadSettings,
  });
  const selection = useMutation({
    mutationFn: (workspaceId: string) => switchProfile({ data: { workspaceId } }),
    onSuccess: reloadSettings,
  });
  const busy = creation.isPending || selection.isPending || creation.isSuccess || selection.isSuccess;
  const items = [
    { id: activeId, name: activeName },
    ...(profiles.data ?? []).filter((profile) => profile.id !== activeId),
  ];

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!busy && name.trim().length >= 2) creation.mutate();
  }

  return (
    <div className="space-y-2 rounded-lg border border-border bg-card p-3">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <nav aria-label="Perfis de workspace" className="flex flex-wrap gap-2">
          {items.map((profile) => (
            <Button key={profile.id} type="button" size="sm"
              variant={profile.id === activeId ? "secondary" : "ghost"}
              aria-current={profile.id === activeId ? "true" : undefined}
              disabled={busy}
              onClick={() => { if (profile.id !== activeId) selection.mutate(profile.id); }}>
              {profile.name}
            </Button>
          ))}
        </nav>
        {canCreate && (
          <Button type="button" size="sm" disabled={busy} onClick={() => setOpen(true)}>
            <Plus className="mr-1 size-4" aria-hidden="true" /> Adicionar perfil
          </Button>
        )}
      </div>
      {profiles.isError && <p role="alert" className="text-sm text-destructive">Não foi possível carregar os perfis.</p>}
      {selection.isError && <p role="alert" className="text-sm text-destructive">{selection.error.message}</p>}
      <Dialog open={open} onOpenChange={(next) => {
        if (busy) return;
        if (!next) { setName(""); creation.reset(); }
        setOpen(next);
      }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Adicionar perfil</DialogTitle>
            <DialogDescription>Crie um workspace com configurações próprias.</DialogDescription>
          </DialogHeader>
          <form className="space-y-4" onSubmit={submit}>
            <div className="space-y-1">
              <label htmlFor="workspace-profile-name" className="text-sm font-medium">Nome do workspace</label>
              <Input id="workspace-profile-name" value={name} maxLength={100} required autoFocus
                disabled={busy} onChange={(event) => setName(event.target.value)} />
            </div>
            {creation.isError && <p role="alert" className="text-sm text-destructive">{creation.error.message}</p>}
            <Button type="submit" disabled={busy || name.trim().length < 2}>
              {busy ? "Criando…" : "Criar workspace"}
            </Button>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
