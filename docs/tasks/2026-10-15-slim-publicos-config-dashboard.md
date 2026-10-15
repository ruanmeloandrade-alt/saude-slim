# Saúde Slim: Públicos, Disparos, Automações e Configurações

Checkpoint: código preparado; verificar build e publicação antes de declarar publicado. Base 5151b45, branch fix/slim-publicos-config-20261015. Destino restauracao/sistema-completo-20261014, somente ruanmeloandrade-alt/saude-slim e banco vyzvfcgpjjzvcjegzzza.

## Ordem solicitada

1. Públicos, Disparos e automações avançadas.
2. Configurações gerais.
3. No final da fila: corrigir as fontes da Dashboard (Envios de formulários, Campos personalizados, Valores dos campos, Sites de tracking, Indicadores de tracking). Não esconder o aviso nem inventar métricas.

## Banco realmente aplicado

- 20261015115919: crm_lead_audiences, lead_custom_fields, lead_custom_field_values, tasks, crm_stage_automations, crm_automation_jobs; índices, RLS por workspace, operador versus visualizador, validação de vínculos e substituição atômica das ações de etapa.
- 20261015120218: campanhas/destinatários persistentes, identificação de requisição, deduplicação de destinatários, cancelamento e reserva exclusiva de execução; resultados incertos não são reenviados automaticamente. Apenas serviço pode reservar/alterar resultado de envio. Nenhum segredo fica nessas tabelas.
- As duas migrations acima foram lidas no histórico e versionadas neste repositório. Não reaplicadas por scripts de build.

## Código preparado

Públicos: tags JSON em strings/objetos, combinação any/all/none, filtros falsos, campos/produtos/tarefas, paginação sem corte antes dos filtros, falhas de fonte não tratadas como ausência de contatos, erro explícito ao atualizar contagem. O limite de segurança é 100 mil registros por fonte, não leitura ilimitada.

Disparos/reativação: troca do loop prolongado dentro da requisição por fila persistente, mesmo requestId durante uma repetição após falha e novo ID após confirmação, progresso na tela, encerramento dos pendentes, checagem de sessão/empresa, bloqueios de contato, mudança de telefone, timeout e resultados incertos. SalesBot iniciado não é contado como mensagem WhatsApp entregue. Agente diferente ativo não é substituído silenciosamente; atualização é condicionada à versão e rechecagem antes do envio. O encerramento não desfaz envio já iniciado ou bot já iniciado no Inbox.

Automações de etapa: execução imediata/agendada compartilha reserva atômica, consulta definição ainda habilitada, servidor processa pendências e operadores sem permissão de escrita são rejeitados antes do uso de cliente privilegiado. Recursos de grupos, workflow e integrações Meta continuam dependentes de contratos não restaurados nesta entrega.

Configurações: leitura/gravação de segurança e verificação de convite deixam de esconder falhas como sucesso ou convite inexistente. Não declarar proteção contra senhas vazadas ativa por valor padrão. Isso não resolve o backend ausente de segurança/convites.

## Testes efetivamente executados antes do build

- 13/13 testes locais da seleção de Públicos, usando código real com transporte simulado.
- 16/16 testes locais da orquestração de entrega, incluindo cancelamento, isolamento, opt-out, telefone alterado, agente concorrente, resultado sem recibo, falha de persistência e timeout. Não fazem chamada a WhatsApp/OpenAI.
- A sonda SQL da primeira migration executou CRUD de público, campos/valores/tarefas, preservação após falha da substituição atômica, referências inválidas e isolamento; retornou sem erro e reverteu os registros.
- O teste SQL da fila inicialmente falhou por local_id obrigatório no bot temporário. A transação foi abortada. O teste corrigido foi bloqueado pela segurança da ferramenta e NÃO passou/não executou. Não reexecutado por outro meio.
- Consulta somente leitura posterior: zero campanhas, destinatários, públicos e ações de teste; nenhuma tabela pública com RLS desabilitada.

## Bloqueio explícito: Configurações

A ferramenta bloqueou a migration slim_restore_settings_security_and_invitations. Ela NÃO foi aplicada. Consulta posterior confirmou workspace_security_settings inexistente. Não houve tentativa de contornar o bloqueio por outra identidade, serviço ou implantação. Esse pacote não foi colocado em um caminho de execução automática.

Permanecem pendentes: segurança, dispositivos, MFA/passkeys/recovery, políticas de equipe e convites. Salvamento de preferência não comprova aplicação da proteção; o middleware global de proteção herdado permanece desativado e precisa de correção própria.

## Dashboard no fim da fila

Campos e valores deixaram de ser tabelas ausentes porque também são dependências de Públicos e foram restaurados na primeira migration. Isso ainda não é homologação da tela. Envios de formulários e tracking continuam aguardando implementação/validação. Não marcar o pedido das cinco fontes como concluído.

## Limites e semáforo

Atualizar docs/OPERATION_STATUS.md após obter o resultado real do build. Testes novos de integração do código e autorização serão executados no prebuild com as regressões anteriores; não contabilizá-los como passados antes dos logs.
Nenhuma mensagem foi enviada durante testes; não foi criada conta real, lida chave de cliente nem modificada a conexão Evolution. Não houve navegador autenticado/E2E. As rotinas de envio real e a fila de banco ainda precisam de homologação; não declarar os dois blocos integralmente concluídos.
Não alterar main, DNS, Harpia, MCP, MktOn original, Pedidos ou GitHub Actions. Não usar Lovable.
