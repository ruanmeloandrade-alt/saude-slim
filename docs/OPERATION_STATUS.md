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
