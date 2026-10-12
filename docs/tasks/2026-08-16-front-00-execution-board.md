# MKTOn — Frente 00 — Quadro Executivo de Tasks

Status geral: **🟡 EM EXECUÇÃO**
Chave canônica: `MKTON-F00-CONEXOES`
Data do checkpoint: 2026-08-21
Escopo pai: `docs/tasks/2026-08-15-front-00-connections-live-closeout.md`
Branch de retomada atual: `agent/mkton-f00-live-closeout-20260821`

## Regra de acompanhamento
Toda atualização ao owner deve informar task atual, subtarefas concluídas, bloqueio real e próximo passo objetivo. A Frente 00 homologa conexão/API/provider; frentes funcionais não devem reabrir integrações já homologadas sem bug reproduzível.

A branch histórica `agent/mkton-f00-conexoes` ficou muito atrás da `main` e não deve ser reutilizada para implementação. A retomada de 2026-08-21 parte da `main` atual para preservar todos os merges posteriores sem rebase, force-push ou reescrita de histórico.

## Resumo executivo
- 🟢 **Google OAuth base** — concluída.
- 🟡 **Google produtos/ativos** — runtime operacional confirma integração Google `connected`, sem `last_error`, com 10 produtos registrados e 14 scopes; Maps/Agenda/Gmail ainda exigem os smokes finais de uso real no navegador/conta autenticada.
- 🟢 **WhatsApp Web** — encerrado; não reabrir sem bug reproduzível.
- 🟢 **WhatsApp Oficial / Cloud API** — implementação do ciclo atual fechada; manter apenas smoke final quando necessário.
- 🟡 **TikTok** — código técnico de OAuth/Marketing API já foi entregue na #46, mas o runtime operacional não possui hoje registro `provider = 'tiktok'`; falta autorização real/app/advertiser para homologação externa.
- 🟡 **Google Ads** — API e Developer Token já documentados como configurados; revalidação de conta/campanhas reais continua pendente.
- 🟡 **Meta / Instagram / App Review** — deliberadamente por último.
- 🟢 **Microsoft** — provider aposentado e removido do runtime ativo pela PR #187; não é pendência da F00.
- 🟢 **Mapa de publicação** — atualizado em `docs/tasks/2026-08-21-f00-publication-route-tree-hotfix.md`: sincronização GitHub→Lovable está normal; `Nothing to publish` é no-op idempotente e não deve gerar `noop`, chat Lovable ou edição manual de `routeTree.gen.ts`.

## F00.1 — Google OAuth e conta base — 🟢
- [x] OAuth Client Web da MktOn criado.
- [x] Callback oficial registrado.
- [x] Client ID/Secret configurados no servidor.
- [x] Consentimento, callback e troca de authorization code por token corrigidos.
- [x] Conta real homologada e persistida no workspace.
- [x] Runtime operacional revalidado em 2026-08-21: `status = connected`, `last_error = null`, 10 produtos e 14 scopes registrados.

## F00.2 — Google produtos e ativos — 🟡 FINALIZAÇÃO
### Google Maps / Places
- [x] Browser Key entregue no ambiente efetivamente usado pelo build publicado.
- [x] Maps JavaScript API e Places APIs habilitadas no Cloud Project.
- [ ] Smoke final do mapa no runtime publicado com sessão autenticada.

### Google Agenda / Meet
- [x] Calendar API habilitada.
- [x] Evento externo criado pelo backend quando o usuário marca sincronização.
- [x] Google Meet gerado automaticamente via `conferenceData`.
- [x] Fuso do navegador preservado na criação do evento.
- [x] Falha de sync deixa de ser silenciosa.
- [x] Detalhes do evento e links externos acessíveis no calendário.
- [x] Tarefa do calendário pode ser criada também no Workflow.
- [ ] Smoke final no runtime publicado com conta real.

### Gmail
- [x] Gmail API habilitada no Cloud Project.
- [x] Conta Google e remetente Gmail persistidos como `connected` no workspace.
- [x] Chat E-mail corrigido para ocupar a largura disponível.
- [x] Inbox, enviados e envio usam Gmail API real.
- [ ] Smoke final de Inbox/Enviados/Envio no runtime com sessão autenticada.

### Google Ads
- [x] Google Ads API habilitada no Cloud Project.
- [x] Developer Token configurado.
- [ ] Revalidar contas acessíveis e campanhas reais no estado atual.

### Demais Google
- [x] Drive API habilitada.
- [x] Docs API habilitada.
- [x] Sheets API habilitada.
- [x] Calendar API habilitada.
- [x] APIs de Maps/Places habilitadas.
- [x] Gmail API habilitada.

## F00.3 — WhatsApp Web — 🟢 CONGELADA
- [x] Sessão real conectada.
- [x] Entrada real comprovada.
- [x] Saída real comprovada.
- [x] Não reabrir sem bug reproduzível.

## F00.4 — WhatsApp Oficial / Cloud API — 🟢 CÓDIGO FECHADO
- [x] Integração do ciclo atual implementada.
- [ ] Executar apenas o smoke final necessário ao fechamento global da F00.

## F00.5 — TikTok — 🟡 BLOQUEIO EXTERNO DE HOMOLOGAÇÃO
- [x] Código OAuth server-side, callback, discovery/seleção de advertiser e consumo da Marketing API já entregues na Task #46.
- [x] Estado do runtime operacional conferido em 2026-08-21: não existe registro `provider = 'tiktok'` na tabela `integrations`; não há conexão real atual para testar.
- [x] Auditoria da `main` atual: não existe endpoint ativo de webhook TikTok no produto. O HMAC existente no fluxo TikTok protege o `state` do OAuth.
- [x] Corrigir o critério antigo do quadro: não criar webhook artificial somente para marcar HMAC como concluído. Se um webhook TikTok passar a ser configurado no produto, a assinatura `TikTok-Signature` com HMAC-SHA256 e proteção contra replay torna-se critério obrigatório antes de processar eventos.
- [ ] Autorizar conta/app TikTok real no runtime e selecionar advertiser.
- [ ] Executar prova E2E disponível para Ads/Pixel/recursos efetivamente autorizados.

Bloqueio atual: **provider externo / autorização real**. Nenhum bug de código novo foi reproduzido nesta retomada.

## F00.6 — Google Ads — 🟡 APÓS OS SMOKES GOOGLE/TIKTOK DISPONÍVEIS
- [ ] Revalidar Developer Token e contas acessíveis no estado atual.
- [ ] Smoke de leitura de campanhas/conta real.
- [ ] Registrar qualquer bloqueio externo sem mascarar como falha de código.

## F00.7 — Meta / Instagram / App Review — 🟡 POR ÚLTIMO
- [x] Base OAuth/integração implementada.
- [ ] Finalizar requisitos de App Review/Advanced Access que ainda forem necessários.
- [ ] Reautorizar após aprovação quando aplicável.
- [ ] Executar smokes finais de Pages/Instagram/Ads necessários ao fechamento.

## F00.8 — Fechamento — ⬜
- [ ] Reconciliar escopo F00, quadro e `PROJECT_STATUS.md`.
- [ ] Registrar PRs/commits, smokes e bloqueios externos.
- [ ] Confirmar aceite por provider e marcar F00 🟢.

## Mapa vigente para build/publicação — 2026-08-21
- [x] Confirmar primeiro se o commit desejado chegou à Lovable. A `main` `dd7b644b` aparece como `developer_update: completed`.
- [x] Confirmar preview do commit desejado. O preview atual referencia `dd7b644b`.
- [x] Confirmar que o projeto segue publicado: catálogo Lovable retorna `is_published = true` e URL pública `https://mkton.lovable.app`.
- [x] Preservar `bun.lock` como lock canônico; `package-lock.json` stale continua removido desde a PR #188.
- [x] Preservar a remoção do resíduo Microsoft fonte fechada pela PR #189.
- [x] Não editar `src/routeTree.gen.ts` manualmente como tentativa de destrave; a auditoria F06 registra que ele deve ser regenerado pelo build TanStack/Vite a partir das rotas fonte.
- [x] Não usar chat/agente Lovable nem gerar commit `noop` para forçar publicação; a F06 registra explicitamente que esse caminho foi abandonado depois do incidente `noop`.
- [x] Classificar resposta `Nothing to publish` como **no-op / nada novo para promover**, não como bug de código.
- [ ] Quando houver um novo estado realmente publicável, disparar publicação somente com autorização explícita do owner para aquela ação e validar o runtime depois.

Runbook desta ocorrência: `docs/tasks/2026-08-21-f00-publication-route-tree-hotfix.md`.

## Evidência da retomada — 2026-08-21
- `main` atual usada como base da nova branch; a branch histórica da F00 não foi rebased nem forçada.
- Runtime operacional consultado passivamente: Google presente e conectado, TikTok ausente.
- Task #46 relida: TikTok OAuth + Marketing API já estão tecnicamente entregues; o smoke real depende de app/permissões/advertiser.
- Diretório de rotas públicas e Edge Functions da `main` conferido: nenhum webhook TikTok ativo encontrado.
- Documentação atual do TikTok confirma que, quando um webhook é configurado, o servidor deve validar `TikTok-Signature` usando o timestamp + corpo bruto com HMAC-SHA256 e deve tratar replay/duplicidade. Isso não transforma webhook em requisito quando o produto não possui um callback de eventos TikTok em uso.
- Lovable consultada passivamente: sync da `main` atual está `completed`, preview gerado e projeto permanece marcado como publicado.
- Nenhuma alteração funcional foi feita sem bug reproduzível.

## Próximo passo operacional
1. Executar os smokes finais Google com sessão real: Maps, Agenda/Meet e Gmail.
2. Autorizar/conectar TikTok real e executar advertiser/Ads/Pixel conforme permissões disponíveis.
3. Revalidar Google Ads em conta/campanhas reais.
4. Executar o smoke final do WhatsApp Cloud somente se ainda necessário para o aceite global.
5. Finalizar Meta/App Review por último.
6. Reconciliar F00.8 e marcar a frente verde somente com as evidências reais ou bloqueios externos explicitamente classificados.
7. Em publicação futura, usar o mapa acima e não repetir `noop`, chat Lovable ou edição manual de artefato gerado.
