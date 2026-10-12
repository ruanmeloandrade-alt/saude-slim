# MktOn — publicação preview Afiliados + Partners

Data: 2026-08-11
Branch: `agent/partners-public-preview`
PR: `#106`
Status: pronto para publicação preview solicitada pelo usuário; homologação completa pendente.

## Objetivo
Trazer para uma branch criada da `main` atual as rotas mínimas funcionais de Afiliados + Partners, evitando merge da PR #99 antiga (95 commits atrás da main).

## Publicado nesta frente
- `/partners`: cadastro público real com escolha Affiliate ou Partner.
- `POST /api/public/partners/register`: convite via Supabase Auth e provisionamento do programa.
- `/partners/ativar`: definição de senha pelo convite recebido por e-mail.
- `/partners/afiliado`: painel mínimo ligado ao RPC real do Affiliate.
- `/partners/parceiro`: painel mínimo ligado ao RPC real do Partner e atalho para `/contas`.
- `/r/{codigo}`: referral real com visita, tracking e passagem ao signup existente.

## Regra Partner — conta principal + clientes
O Partner mantém o workspace principal criado no cadastro. Não apagamos mais a conta própria do Partner.

Quando uma indicação Partner recebe `client_workspace_id`, a migration `20260811172000_affiliates_partners_phase2_partner_technical_access.sql` usa a tabela canônica `workspace_members` e registra o Partner como:
- `role = member`
- `role_type = partner`
- `is_partner = true`

Isso torna o workspace do cliente elegível no seletor de contas existente sem promover o Partner a owner/admin.

## Segurança / compatibilidade
- branch nasceu da `main` atual;
- nenhum código foi enviado pela Lovable;
- Lovable foi usada somente para leitura do schema;
- acessos às tabelas `partner_program_*` usam runtime server-side enquanto `Database` types ainda não foram regenerados na main;
- Partner nasce `pending`, portanto referral/painel operacional dependem de aprovação administrativa;
- Affiliate nasce aprovado conforme regra da Fase 2.

## Build
A PR #106 disparou GitHub Actions, mas o job `validate` encerrou antes de qualquer step (`steps: null`), o mesmo bloqueio externo de runner/billing já registrado no projeto. Não há erro de build identificado porque nenhum step de build executou.

## Limitações conhecidas do preview
- migration de acesso técnico Partner ainda não estava aplicada no Supabase na última leitura; deve entrar pelo processo normal de deploy/migrations da main;
- a página legada `/afiliados` continua existindo; o novo cadastro funcional desta publicação é `/partners`;
- homologação E2E real com e-mail novo + aprovação Partner + cliente indicado deve ser executada após publicação;
- `PARTNER_PROGRAM_ENCRYPTION_KEY` continua necessária apenas para o fluxo de dados de pagamento da Fase 2, não para visualizar/cadastrar este preview.

## Critério para considerar publicado
Merge da PR #106 na `main` e publicação do build da main pelo fluxo normal do projeto.
