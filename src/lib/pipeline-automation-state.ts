type ScopedAction = { id: string; stageIds?: string[] };

/** Keep each pipeline's values, including pending drafts, under its own key. */
export function updatePipelineAutomationState<T>(
  state: Record<string, T>,
  pipelineId: string,
  update: T | ((previous: T) => T),
  fallback: T,
): Record<string, T> {
  if (!pipelineId) return state;
  const previous = state[pipelineId] ?? fallback;
  const next = typeof update === "function" ? (update as (previous: T) => T)(previous) : update;
  return { ...state, [pipelineId]: next };
}

/** Reject foreign stages before showing or saving a recovered draft. */
export function scopePipelineAutomations<T extends ScopedAction>(
  value: unknown,
  stageIds: readonly string[],
): Record<string, T[]> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("O rascunho de gatilhos está inválido.");
  }
  const allowed = new Set(stageIds);
  const result: Record<string, T[]> = {};
  for (const [stageId, actions] of Object.entries(value)) {
    if (!Array.isArray(actions)) throw new Error("A lista de gatilhos está inválida.");
    if (!allowed.has(stageId)) {
      if (actions.length > 0) throw new Error("O rascunho contém etapas de outro funil.");
      continue;
    }
    for (const action of actions) {
      if (!action || typeof action !== "object" || typeof action.id !== "string" || !action.id) {
        throw new Error("O rascunho contém um gatilho inválido.");
      }
      if (
        action.stageIds !== undefined &&
        (!Array.isArray(action.stageIds) ||
          action.stageIds.some((id: unknown) => typeof id !== "string" || !allowed.has(id)))
      )
        throw new Error("Um gatilho cobre etapas de outro funil.");
    }
    result[stageId] = structuredClone(actions) as T[];
  }
  return result;
}
