# Recuperação em Revisar Lead e bloqueio de automação

Pedido do proprietário: recuperar contatos e mensagens realmente persistidos na Evolution mas ausentes do CRM; leads recuperados devem permanecer em Revisar Lead sem bot nem agente IA. WhatsApp é prioridade operacional máxima.

Branch isolada: fix/slim-recovery-review-20261105, base de produção 68940b9. Banco atual yztwbybcznyukrgaiqoc; workspace exclusivo c49945db-1960-461a-9339-a43b8403bdd9. Não modificar main nem o checkout de outro chat.

Inspeção de 6.306 registros das duas sessões que possuem histórico recente: 348 inbound diretos únicos após 2026-11-03T14:36:43Z; 86 mensagens ausentes, 7 contatos novos e 6 existentes. Confirmar novamente sob transação antes de gravar. Originais e snapshot de leads ficam privados fora do Git. Sem replay no webhook, sem chamada de envio, sem criação de eventos CRM.

Barreira aditiva no banco: marcador recovery_review_required=true combinado com a etapa Revisar Lead impede criar/retomar SalesBot, enfileirar/executar ação de etapa e vincular IA. Liberação ocorre quando operador retira o card da etapa de revisão. Gravação de mensagens e atividades continua permitida. Recuperação idempotente por ID real de mensagem, em transação, com pausa de IA e cancelamento de automações pendentes exclusivamente dos contatos recuperados. Não alterar dados de outras empresas.

Diagnóstico do fluxo atual continua: Evolution sem inbound novo após 04/11 18:53; erros repetidos de processamento offline com mensagem @bot e Unknown message type. Isto é evidência de falha no conector, não prova de que todo o incidente se reduz a essa mensagem. Não declarar operação normalizada por status open ou HTTP 200.

## Resultado e validação

Recuperação transacional aplicada: 86 eventos originais (82 mensagens e 4 reações), em 13 contatos (7 novos e 6 existentes). Todos em Revisar Lead, IA pausada, zero SalesBot e zero job pendente. Reações não são apresentadas como mensagens vazias; um alvo de reação foi localizado e os demais eventos permanecem preservados na tabela de mensagens com seu raw original. Não houve chamada de envio ou evento de automação. Snapshots privados fora do Git.

Duas migrations aplicadas e registradas no histórico. Testes transacionais com rollback confirmaram bloqueio de bot/job/IA, gravação de histórico, liberação por mudança manual de etapa e classificação de entrada atrasada versus entrada futura. Advisors executados: nenhum alerta citou as funções novas; não se declara o banco inteiro livre de dívida anterior.

Falha causal localizada no Baileys 7.0.0-rc.9: makeOfflineNodeProcessor deixa isProcessing=true quando nodeProcessor lança erro. O mesmo erro Unknown message type para @bot aparece nos ciclos do conector real. Patch de isolamento por item no runtime existente, sem trocar versão/dependência, autenticação, descriptografia, ACK ou volume. O build recusa layout upstream diferente. Reproduzido o travamento original e aprovados 4 testes de continuidade/ordem/duplicidade/idempotência sobre código oficial do pacote NPM. Comando: BAILEYS_QUEUE_FIXTURE apontando para lib/Socket/messages-recv.js, node --test services/whatsapp-connector/test-offline-queue.cjs.

Webhook não dispara histórico já suprimido nem cards retidos em revisão. Lifecycle 7/7; npm run build completo (prebuild, cliente, SSR, Nitro) aprovado. Contratos textuais evolution-e2e-contract têm divergências herdadas com o transformador do build: na fonte original falha a expectativa de ausência de phone_normalized; após geração falham expectativas do antigo bloco literal de criação. Não tratados como teste funcional verde e não alterados para ocultar divergência. Transformações geradas removidas do diff autoral.

Uma janela explícita nos metadados da sessão atual classifica novas mensagens atrasadas para revisão antes de qualquer dispatch, inclusive o acúmulo que ainda não chegou à Evolution. Fora da janela, o fluxo usual permanece. Publicação e evidência end-to-end ainda pendentes.

Arquivos autorais: CODEX_STATUS.md; este escopo; services/whatsapp-connector/Dockerfile, patch-offline-queue.cjs e test-offline-queue.cjs; src/lib/evolution-inbound-lifecycle.ts e seu teste; src/routes/api/public/evolution/webhook.$secret.ts; duas migrations 20261105122857 e 20261105123536. Nenhuma dependência, .env ou segredo alterado/versionado.
