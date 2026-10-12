# Task — Regionalização da conta: fuso, moeda e permissão administrativa

Data: 2026-09-19  
Branch: `fix/workspace-regional-settings-admin`  
Base: `main@5a55ec3cfe74ad66bfcc3f5b27b5402b0283bd99`  
Estado: **🟡 EM EXECUÇÃO**

## Solicitação do owner

Corrigir a configuração regional da conta MKTOn para que:
- o fuso horário possa ser trocado entre as opções já existentes, sem ficar preso em `America/Sao_Paulo`;
- a moeda possa ser trocada entre as opções já existentes, sem ficar presa em `BRL`;
- o criador/owner da conta, autenticado com o próprio e-mail e senha, seja reconhecido como administrador da própria conta para essas configurações;
- administradores legítimos do workspace também possam alterar as configurações regionais;
- nenhuma opção existente de fuso/moeda seja removida.

## Diagnóstico confirmado antes da implementação

1. `set_workspace_default_currency` valida apenas `workspace_members.role_type in ('owner','admin')`.
2. Os owners reais do runtime estão gravados majoritariamente como `role='owner'` e `role_type='funcionario'`; portanto o RPC rejeita o dono legítimo.
3. A tela de Preferências salva o fuso apenas em `localStorage`, enquanto o fuso operacional da conta continua em `workspaces.business_hours.timezone`, cujo default é `America/Sao_Paulo`.
4. A moeda da conta usa `workspaces.default_currency`, cujo default é `BRL`; a troca falha por causa do contrato de autorização acima.
5. `getSettingsBundle` não expõe um contrato explícito de “pode administrar regionalização”, e a UI tenta inferir papel por propriedades que nem sempre estão no bundle.

## Implementação prevista

- adicionar um resolvedor server-side de permissão regional que aceite:
  - `workspaces.owner_id = auth user`;
  - membership `role='owner'` ou `role='admin'`;
  - membership `role_type='owner'` ou `role_type='admin'`.
- expor `canManageRegionalSettings` no bundle.
- criar mutação dedicada para salvar o fuso da conta em `business_hours.timezone`, preservando os dias/horários.
- fazer Preferências carregar o fuso da conta, não só o default local.
- salvar fuso + moeda da conta usando o mesmo botão de preferências.
- corrigir os RPCs de moeda no banco para reconhecer owner/admin real.
- manter idioma/aparência como preferência individual.
- manter catálogos atuais de fusos e moedas.

## Fora de escopo

- alterar preços, planos, checkout ou Cora;
- alterar calendários externos;
- redefinir horários de expediente do cliente;
- alterar permissões gerais de equipe além do necessário para regionalização;
- usar chat/agente da Lovable.

## Critérios de aceite

- owner real consegue alterar moeda e fuso;
- admin legítimo consegue alterar moeda e fuso;
- usuário comum não ganha permissão administrativa por engano;
- mudança de moeda persiste em `workspaces.default_currency`;
- mudança de fuso persiste em `workspaces.business_hours.timezone`;
- dias e horários existentes do expediente não são sobrescritos ao trocar apenas o fuso;
- Preferências reabre mostrando os valores persistidos;
- nenhuma opção dos catálogos atuais desaparece;
- testes focados + build/regressão relevante aprovados;
- migration aplicada no banco operacional canônico;
- integração em `main`, publicação e smoke pós-deploy conforme AGENTS.md.


## Checkpoint 2026-09-19 — implementação concluída / validação em andamento

### Código
- 🟢 owner real reconhecido por `workspaces.owner_id` e por membership `role=owner`;
- 🟢 admin legítimo reconhecido por `role=admin` ou `role_type=admin`;
- 🟢 `getSettingsBundle` expõe `canManageRegionalSettings`;
- 🟢 fuso e moeda usam os catálogos já existentes;
- 🟢 fuso deixou de ser apenas local e passa a persistir em `workspaces.business_hours.timezone`;
- 🟢 moeda continua persistida em `workspaces.default_currency`;
- 🟢 moeda + fuso são salvos atomicamente por `set_workspace_regional_settings`;
- 🟢 alteração de fuso preserva o restante de `business_hours`;
- 🟢 cache regional sincroniza moeda + fuso no login autenticado;
- 🟢 troca de workspace ressincroniza moeda + fuso da nova conta;
- 🟢 expediente usa a mesma permissão administrativa regional, não apenas owner estrito;
- 🟢 regressão focada adicionada em `src/lib/__tests__/workspace-regional-settings-admin.test.ts`;
- 🟢 workflow path-scoped adicionado em `.github/workflows/workspace-regional-settings.yml`.

### Banco operacional
Migration aplicada via ponte SQL permitida da Lovable, sem uso de chat/agente:
`supabase/migrations/20260919193000_workspace_regional_settings_admin.sql`.

Validações executadas no runtime:
- 🟢 owner real com `role=owner` e `role_type=funcionario` conseguiu salvar EUR + Europe/Lisbon em subtransação de teste;
- 🟢 admin não-owner conseguiu salvar GBP + Europe/London em subtransação de teste;
- 🟢 membro comum sem `super_admin` foi rejeitado;
- 🟢 setter legado de moeda passou a aceitar owner real;
- 🟢 timezone inválido `Mars/Olympus` foi rejeitado;
- 🟢 todos os probes de escrita foram revertidos e os dados usados no teste permaneceram BRL + America/Sao_Paulo;
- 🟢 getter regional retorna os valores persistidos da conta.

### Pendente antes do verde final
- 🟡 executar regressão focada + build no CI da PR;
- 🟡 integrar na `main`;
- 🟡 publicar automaticamente em produção;
- 🟡 executar smoke pós-publicação.


## Fechamento — 2026-09-19

Estado: **🟢 VERDE TÉCNICO / PUBLICAÇÃO DISPARADA E PROJETO SINCRONIZADO**

### Evidência final
- PR: **#242**.
- Merge em `main`: `62add4dec71435270775ee52f316a8866fca0d15`.
- CI focado, run `35471506382`: **SUCCESS**.
  - instalação: PASS;
  - regressão regional + permissões: PASS;
  - build de produção: PASS.
- A primeira execução do CI detectou um teste legado desatualizado que procurava as abas no wrapper `src/routes/configuracoes.tsx`; o teste foi corrigido para validar a implementação real em `src/legacy/configuracoes.legacy.tsx` e a bateria inteira foi repetida até ficar verde.
- Migration aplicada no banco operacional.
- RPCs `get_workspace_regional_settings`, `set_workspace_regional_settings` e `set_workspace_default_currency` confirmados instalados.
- Owner real no estado legado `role=owner / role_type=funcionario`: alteração de moeda/fuso validada com rollback.
- Admin não-owner: alteração validada com rollback.
- Membro comum sem privilégio global: alteração negada.
- Timezone IANA inválido: negado.
- Dados dos workspaces usados nos probes foram restaurados integralmente após os testes.
- Lovable sincronizada no merge `62add4dec71435270775ee52f316a8866fca0d15`, projeto em estado `ready`.
- Deploy acionado após a sincronização; deployment ID `e7cfe22e-c724-43fb-b5dd-d3b225ccff61`.
- O conector Lovable reporta o projeto como publicado e pronto.
- Smoke HTTP externo não pôde ser executado nesta sessão porque os ambientes de fetch disponíveis não resolveram os domínios públicos; essa limitação não é registrada como PASS visual/autenticado.

### Comportamento final
- as opções existentes de moeda e fuso continuam disponíveis;
- owner/criador real da conta é reconhecido independentemente da inconsistência histórica de `role_type`;
- admins legítimos também podem alterar moeda/fuso;
- moeda persiste em `workspaces.default_currency`;
- fuso persiste em `workspaces.business_hours.timezone`;
- alteração de fuso preserva os dias e horários de expediente;
- moeda e fuso são salvos atomicamente;
- regionalização é ressincronizada ao entrar e ao trocar de workspace;
- usuário comum não recebe permissão administrativa.
