# Remover transform de QR da Evolution do build

Status: 🟢 VERDE TÉCNICO / PRONTO PARA INTEGRAÇÃO

## Incidente
A publicação continuava falhando no plugin Vite `mkton-evolution-stale-qr-recovery`, mesmo após tornar o transform independente de `SbQrLookup`. O build não pode depender de reescrita textual de `src/lib/evolution.functions.ts`.

## Solução aplicada
- Removido de `vite.config.ts` o plugin `evolutionStaleQrPlugin` e a importação de `applyEvolutionStaleQrTransform`.
- `src/lib/evolution.functions.ts` agora implementa diretamente a validade do QR salvo.
- `SbQrLookup` lê `last_qr`, `metadata.qr_generated_at` e `updated_at`.
- `readSavedQr` aceita QR somente quando o timestamp é válido e a idade é de até 45 segundos.
- O build não executa mais `scripts/evolution-stale-qr-transform.ts`, portanto os erros `tipo SbQrLookup não encontrado` e `readSavedQr não encontrado` deixaram de existir no caminho de compilação.

## Regras preservadas
- QR salvo só é aceito quando possui timestamp válido e idade de até 45 segundos.
- Timestamp preferencial: `metadata.qr_generated_at`; fallback: `updated_at`.
- Nenhuma alteração em banco, sessões existentes, workspaces, credenciais ou Cora.
- Lovable chat/agent não foi utilizado.

## Validação técnica
- `vite.config.ts` atual não contém `mkton-evolution-stale-qr-recovery`, `evolutionStaleQrPlugin` nem `applyEvolutionStaleQrTransform`.
- Comparação da branch com `main`: somente `src/lib/evolution.functions.ts` foi alterado nesta segunda etapa, com 29 adições e 3 remoções funcionais.
- O trecho atualizado consulta `.select("last_qr, metadata, updated_at")` e usa `isSavedQrFresh` com limite `45_000` ms.
- Branch está 1 commit à frente e 0 atrás da `main` antes da atualização deste documento.

## Publicação
Após merge validado em `main`, publicar automaticamente pela Lovable e só declarar concluído quando houver evidência concreta da publicação da versão nova.
