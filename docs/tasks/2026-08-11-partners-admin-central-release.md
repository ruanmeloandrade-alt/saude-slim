# Central Partners administrativa — 2026-08-11

## Objetivo
Substituir o front visual antigo/placeholder da Central Partners por uma superfície administrativa mínima e real para lançamento.

## Escopo deste bloco — 3/3
1. Dashboard e participantes reais — concluído.
2. Aprovação/bloqueio de Affiliate e Partner — concluído.
3. Financeiro manual + auditoria + atalho de super admin — concluído.

## Implementado
- rota `/partners/admin` protegida por `partner_program_is_admin`;
- dashboard via `partner_program_admin_dashboard`;
- lista real de Affiliate e Partner com dados do perfil;
- aprovação, rejeição e bloqueio via `partner_program_set_role_status`;
- solicitações de payout reais;
- aprovação, rejeição e marcação de pagamento via `partner_program_set_payout_status`;
- auditoria recente do programa;
- atalho `Central Partners` no seletor `/contas` somente para super admin.

## Mantido fora desta entrega
- payout automático continua fora da Fase 2;
- marketplace continua fora da Fase 2;
- editor avançado de override de comissão e vínculo manual Partner↔cliente pode ser adicionado em bloco posterior, embora o backend já exista.

## Regressão
`src/lib/partners-admin-central-release.test.ts`.

## Próximo passo
Após publicação, auditar o que ainda resta da PR visual antiga #90. Não portar marketplace. Prioridade seguinte: editor administrativo de overrides/vínculos, se ainda necessário para o lançamento, e fechamento de pendências operacionais/CI.
