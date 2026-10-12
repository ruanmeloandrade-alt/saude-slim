# Partners — regras e vínculos administrativos — 2026-08-11

## Objetivo
Fechar o último bloco funcional da Fase 2 que ainda não tinha superfície administrativa real: override individual de comissão e vínculo formal Partner ↔ cliente.

## Escopo — 2/2 concluído
1. Override individual de comissão — concluído.
2. Vínculo formal Partner ↔ cliente — concluído.

## Override
- rota `/partners/admin/regras`;
- acesso exclusivo de super admin;
- seleciona Affiliate ou Partner aprovado;
- define primeira venda ou recorrência;
- define percentual em basis points;
- exige motivo;
- usa `partner_program_set_commission_override` com vigência a partir do momento da alteração;
- preserva o histórico anterior conforme backend.

## Vínculo Partner ↔ cliente
- seleciona Partner aprovado;
- seleciona workspace/cliente;
- exige motivo;
- usa `partner_program_link_customer`;
- o backend sincroniza acesso técnico Partner no `workspace_members`;
- futuras recorrências passam a seguir a regra formal do vínculo; comissão inicial histórica do Affiliate não é desfeita.

## Navegação
A Central Partners `/partners/admin` aponta diretamente para `Regras e vínculos`.

## Fora da Fase 2
- marketplace;
- payout automático/Stripe Connect;
- thresholds/tier superiores inventados sem configuração administrativa.

## Regressão
`src/lib/partners-admin-rules-release.test.ts`.

## Estado do ecossistema após este bloco
O desenvolvimento funcional da Fase 2 fica fechado em código. Pendências restantes são homologação/ambiente: execução real de CI/build, configuração de `PARTNER_PROGRAM_ENCRYPTION_KEY` e conteúdo real da Faculdade Partners.
