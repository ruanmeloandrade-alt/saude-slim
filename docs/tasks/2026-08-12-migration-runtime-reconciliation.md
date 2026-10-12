# Reconciliação de migrations e runtime — 2026-08-12

Status: **CONCLUÍDA PARA TASK 3 / SEM SQL NOVO APLICADO**

Banco operacional auditado: projeto Lovable MKTOn `47369245-434e-4f46-a9b5-ee1cec604309` (stack Supabase).

## Regra de segurança

- Não usar o Supabase legado `xmoiyffwmolwmjzeuqjf` para migrations atuais.
- Não reaplicar migrations só porque o ledger não contém a versão.
- Confirmar o objeto real no schema antes de qualquer DDL.
- As 15 migrations-base históricas de Partners da PR #99 permanecem snapshots não executáveis.

## Estado do ledger

`supabase_migrations.schema_migrations` possui 184 linhas, de `20260628025335` até `20260809005929`.

Consulta por versões `>= 20260811000000` retornou **0 linhas**.

Conclusão: o banco operacional possui alterações recentes materializadas no schema que não estão representadas no ledger Supabase. Nesta reconciliação isso é tratado como **runtime aplicado / ledger não reconciliado**, e não como autorização para reaplicar SQL.

## Matriz de verificação

| Frente | Migration GitHub | Ledger recente | Runtime verificado | Estado |
|---|---|---:|---|---|
| Reação WhatsApp / PR #144 | `20260811201000_fix_partner_sandbox_whatsapp_message_trigger.sql` | não | função corrigida + trigger ativo + novos inserts | runtime aplicado |
| Social Media / PR #123 | `20260811210500_social_post_automations.sql` | não | `social_post_automations` e `social_post_automation_runs` existem | runtime aplicado |
| Gestor de Tráfego / Task 8 | `20260811143000_meta_creative_deterministic_attribution.sql` | não | 5 colunas + 2 índices + trigger existem | runtime aplicado |
| Partners pending access / PR #156 | `20260812143000_partner_program_pending_access.sql` | não | funções de Comunidade/Faculdade aceitam `pending` | runtime aplicado |
| Partners Fase 2 histórica / PR #99 | 15 snapshots históricos | não aplicável | não reaplicar | reconciliado documentalmente |

## Reação WhatsApp — evidência detalhada

Função ativa em produção:
`public.partner_program_enforce_sandbox_message_limit()`.

A definição atual:
- cria `v_new jsonb := to_jsonb(new)`;
- para `channel_messages`, lê `v_new ->> 'direction'`;
- para `whatsapp_web_messages`, lê `v_new ->> 'from_me'`;
- portanto não dereferencia coluna inexistente diretamente.

Trigger ativo:
`trg_partner_sandbox_whatsapp_web_message_limit BEFORE INSERT ON whatsapp_web_messages`.

Evidência de recuperação de INSERT:
- 66 linhas em `whatsapp_web_messages` criadas depois do merge da PR #144;
- 49 linhas desde 2026-08-12 00:00 UTC;
- linha mais recente observada: `2026-08-12 14:08:42.023081+00`.

A consulta pesada para provar exaustivamente que não existe nenhuma mensagem histórica elegível ainda faltando foi cancelada novamente com HTTP 499. Por isso:
- **não reaplicar a migration**;
- considerar o bloqueio estrutural de INSERT corrigido;
- deixar smoke real de reação e eventual verificação residual de backfill para Task 6.

## Social Media — evidência

Objetos verificados no banco operacional:
- `public.social_post_automations` existe;
- `public.social_post_automation_runs` existe.

Isso confirma a materialização do núcleo da migration da PR #123.

## Gestor de Tráfego — evidência

Em `public.meta_creative_uploads` existem:
- `meta_creative_id`;
- `meta_ad_id`;
- `meta_adset_id`;
- `meta_campaign_id`;
- `linked_at`.

Índices:
- `idx_meta_creative_uploads_meta_ad_id`;
- `idx_meta_creative_uploads_meta_campaign_id`.

Trigger:
- `trg_link_meta_creative_upload_from_operation` ativo em `meta_campaign_operations`.

## Partners pending access — evidência

As funções atuais no banco operacional contêm a regra `status in ('pending','approved')`:
- `partner_program_join_community`;
- `partner_program_my_academy_progress`.

Isso confirma que a regra principal da migration da PR #156 está materializada.

## Decisão final da Task 3

Nenhum DDL/SQL de escrita foi necessário nesta reconciliação.

Motivo: os objetos de produção já estão no estado esperado. Reaplicar migrations baseando-se somente no ledger vazio criaria risco de duplicação/conflito.

Pendência residual movida para Task 6:
- smoke real de reação WhatsApp;
- se necessário, verificação mais estreita de mensagens históricas faltantes sem consulta pesada global.
