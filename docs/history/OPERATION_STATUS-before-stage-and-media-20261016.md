# Saúde Slim: checkpoint prioritário do login em 16/10/2026

**Deploy funcional confirmado:** commit `e2dabf6d8c49377f71430c33fe44d3f6c6060d34`, Railway `8220a268-065e-481c-96f8-ee9927bc8cd7` SUCCESS, healthcheck aprovado. Serviço `saude-slim-web` online com 1 réplica rodando e 0 travadas. Domínios `slimesaude.com` e `www.slimesaude.com` associados ao serviço; DNS do domínio principal propagado, certificado válido. Nenhum dado de produção foi escrito durante os testes.

| Frente | Semáforo | Evidência e limite |
|---|---|---|
| Página de login /auth | 🟢 Mitigação publicada | Renderização sem aguardar o getSession inicial bloqueado; continua exigindo autenticação para rotas internas. |
| HTTP de autenticação | 🟢 Mitigação publicada | Senha com deadline de 12s sem retry automático; refresh_token com deadline de 20s; cancelamento respeitado e erros de infraestrutura explicados sem afirmar senha inválida. |
| Testes | 🟢 10/10 | Cenários de timeout, abort, senha, escopo de requisição, persistência de sessão e rotas passaram, além do build/healthcheck. Nenhuma autenticação real executada. |
| Autenticação REAL do Supabase | 🔴 Indisponível | Após a publicação, até SELECT 1 no banco do projeto vyzvfcgpjjzvcjegzzza continua com Connection terminated due to connection timeout. Edge logs registraram HTTP 504/522 em password, refresh_token e RPCs. A interface não pode autenticar enquanto Auth/DB não responderem. |
| Saúde pública do serviço / projeto | 🟡 Contraditória | Dashboard Management retorna ACTIVE_HEALTHY, mas SQL/Auth não atendem. Status público regional operacional não equivale à saúde deste projeto específico. Plano da organização: Free. |
| Recuperação da instância gerenciada | 🔴 Depende do provedor | Conector Supabase não tem ação Restart project. Não foi executado Pause/Restore nem mudança de backend, chaves ou compute. Abrir https://supabase.com/dashboard/project/vyzvfcgpjjzvcjegzzza/settings/general para Restart project; caso falhe, abrir ticket no suporte. |
| SalesBot de gatilho no Funil | 🔴 Bloqueado anterior | A fila transacional de movimentos ainda não foi confirmada no banco; recurso permanece desabilitado com fidelidade. |
| Inbox, PDF/áudio, histórico/ERP | 🟡 Mitigações anteriores preservadas | Melhoras de timeouts e listas publicadas; atendimento real aguarda restauração do Supabase e E2E autenticado. |

**A restauração do banco não foi declarada concluída.** O site responder no Railway não prova que o Supabase Auth/PostgREST voltou a operar.

O detalhamento da ocorrência, links e instrução para suporte está em `docs/incidents/2026-10-16-supabase-login-timeout.md`. Restante do semáforo previamente aprovado e registrado abaixo.

---

# Saúde Slim | Semáforo de produção

**Checkpoint de 16/10/2026.** Projeto exclusivo `ruanmeloandrade-alt/saude-slim`, branch `restauracao/sistema-completo-20261014`, Supabase `vyzvfcgpjjzvcjegzzza`. Nenhum domínio, credencial, cliente, pedido, mensagem ou negócio externo foi alterado nesta sessão.

## Entregas verificadas nesta sessão

| Frente | Estado | Evidência / limite |
|---|---|---|
| Histórico de Vendas | 🟢 Página única | Rota `/saude-slim` carrega apenas `SlimErpWorkspace mode=history`, preservando dados antigos sem renderizar a segunda lista. |
| Anexos e áudio no Inbox | 🟡 Proteções publicadas anteriormente | Limites e deadline, sem repetição automática de envio incerto ou reinício de WhatsApp. Não houve entrega real de mídia E2E nesta sessão. |
| Lista de contatos sob timeout | 🟢 Mitigação publicada | Preview limitada a 160 atividades/4 s, lista permanece visível e leitura incerta fica identificada. Código `70c62aa`, 7 testes focados; deploy `2a5bca4b` SUCCESS. |
| Trabalho automático durante falha SQL | 🟢 Proteção publicada | Inbox SalesBots, disparos e verificação de automações usam cooldown compartilhado que aumenta até 5 minutos sob falhas de conexão; não descarta jobs; pool saudável retorna ao ritmo normal. Poll de disparos normal passou de 1 s para 5 s. Código `1da7460`, 8 testes focados; deploy `4e602d58` SUCCESS. Log de produção confirmou circuito atuando e leitura posterior registrou quatro erros dos dois verificadores em janela de sete minutos, contra centenas na janela anterior. |
| Mover lead no Funil | 🟢 Correção delimitada publicada | Apenas o lead selecionado é atualizado; não altera `last_message_from`; confirma linha atualizada antes de declarar sucesso. Código `d22507c`, 8 testes; deploy `3b011046` SUCCESS, healthcheck e 1 réplica online. |
| Gatilho SalesBot ao mover lead | 🔴 Ainda bloqueado | A movimentação pelo caminho legado **não dispara** gatilhos. Migração `20261016153000_slim_stage_move_outbox.sql`, RPC e worker preparados mas sem instalação/validação. `scripts/slim-stage-move-release.json` permanece `enabled:false`. Não habilitar silenciosamente. |
| Supabase SQL e autenticação | 🔴 Indisponibilidade comprovada | `execute_sql` falha até em `SELECT 1`, `list_migrations` e advisors por timeout. `get_project` relata `ACTIVE_HEALTHY`, mas logs `edge_logs` registram 522/504 em RPCs de filas e 504 em autenticação/refresh_token. Não afirmar estabilidade do banco porque o Railway está online. |
| Navegação Funil → Inbox e envio real | 🟡 Teste autenticado pendente | A mitigação é de código e de fila, não demonstra navegação ou entrega WhatsApp real, nem cura o serviço SQL. |

**Railway web:** deploy funcional mais recente `3b011046-68db-4ecb-9a64-07e83af58368` SUCCESS, uma réplica online, nenhuma réplica travada, sem trabalho pendente na verificação após deploy. As falhas antigas continuam no histórico de deploy, mas a versão mais recente está operante.

## Backlog previamente autorizado e preservado

| Área | Estado | Restante |
|---|---|---|
| Pedidos e ERP | 🟡/🔴 | Checkout com endereço/frete, validação ponta a ponta de estoque/Dashboard; Editar/Excluir pedidos bloqueados por migração anterior. |
| Copiloto | 🟡 | Presença global anterior; autonomia com aprovação prévia no servidor não concluída. |
| CRM/Funil/Clientes | 🟡 | Identidade operacional corrigida anteriormente; ficha lateral e mini-Inbox ainda em WIP não publicado. |
| Inbox | 🟡 | Correções de etiquetas, áudio, transcrição, mídias e indicadores publicadas previamente; envio real e histórico integral precisam de homologação após recuperação do banco. |
| IA individual | 🟡 | Prompt-only e prevenção de resposta duplicada anteriores; E2E com provedor não concluído. |
| Grupos WhatsApp e IA | 🟡/🔴 | Cadastro de agente por prompt publicado anteriormente, atendimento automático e telemetria de grupo ainda pendentes. |
| Disparos, acompanhamento, tracking | 🟡 | Módulos corrigidos parcialmente, entrega real e cenários finais pendentes. |
| Segurança/convites, unicidade global de contatos | 🔴 | Migrações anteriores recusadas não aplicadas por outra via. |
| Emissão fiscal | 🔴 | O PDF atual é documento comercial, não NF autorizada. |
| Interface/brand, fornecedores, catálogo | 🟡 | Correções anteriores preservadas; homologação visual/funcional completa pendente. |

## Restrições, retomada e rastreabilidade

Não foi disparado SalesBot, enviado WhatsApp, movimentado lead real nem alterada venda para fins de teste. Testes de código com dados controlados não equivalem a E2E. A instalação do outbox de etapa só deverá ocorrer quando leituras/migrações SQL voltarem a operar, e o código novo somente poderá ser habilitado após verificar a instalação, os acessos e a fila. Não trocar por um gatilho não transacional de efeito duplicável.

Relatório da investigação anterior: `docs/tasks/2026-10-16-slim-inbox-timeout-recovery.md`. Semáforo detalhado anterior arquivado em `docs/history/OPERATION_STATUS-before-db-incident-20261016.md`. Histórico integral de commits foi preservado. Nenhuma das demandas aprovadas foi retirada do escopo.
