export const INTEGRATION_VAULT_UNAVAILABLE_MESSAGE =
  "Cofre de integrações indisponível. A configuração segura do ambiente precisa ser corrigida pelo administrador da MKTOn.";

export function integrationVaultFailure(scope: string, detail?: unknown): Error {
  if (typeof console !== "undefined") {
    console.error(`[integration-vault] ${scope}`, detail ?? "sem detalhe");
  }
  return new Error(INTEGRATION_VAULT_UNAVAILABLE_MESSAGE);
}
