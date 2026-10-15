# Saúde Slim: Públicos, Disparos, Automações e Configurações

Atualização de 15/10/2026: a implementação 022d6ce foi publicada com baf3993, deployment e81d14d0-6712-4adb-b86f-218c8ea30cb7 SUCCESS e healthcheck aprovado. As correções seguintes de Configurações e fontes da Dashboard estão em docs/tasks/2026-10-15-slim-settings-dashboard-continuation.md. O status canônico atual é docs/OPERATION_STATUS.md.

Destino exclusivo: ruanmeloandrade-alt/saude-slim, branch restauracao/sistema-completo-20261014, banco vyzvfcgpjjzvcjegzzza. Não usar o projeto original.

## Ordem solicitada

Públicos, Disparos e automações avançadas; depois Configurações gerais; por último as cinco fontes da Dashboard. Não esconder aviso ou inventar métrica para declarar conclusão.

## Banco aplicado nesta frente

20261015115919: crm_lead_audiences, lead_custom_fields, lead_custom_field_values, tasks, crm_stage_automations e crm_automation_jobs; índices, RLS por workspace, validação de vínculos e substituição atômica das ações de etapa.

20261015120218: campanhas/destinatários persistentes, identidade da requisição, deduplicação, cancelamento e reserva de execução. Apenas o serviço pode reservar/alterar o resultado de entrega. As duas migrations foram conferidas no histórico e versionadas, não executadas por scripts de build.

## Código publicado

Públicos: filtros combinados, tags JSON de strings/objetos, filtros falsos, campos/produtos/tarefas, paginação sem cortar antes de filtrar e falha explícita de fonte/atualização de contagem. O limite de segurança é 100 mil registros por fonte. O filtro herdado de silêncio continua baseado em updated_at do lead e não foi homologado como histórico real de mensagens.

Disparos/reativação: fila persistente em vez de loop demorado dentro da requisição; identificador preservado durante repetição após erro ambíguo e renovado após confirmação; progresso e encerramento de pendências na tela; checagens de sessão/empresa, contato bloqueado, telefone alterado, timeout e resultado incerto. Não há reenvio automático de resultado incerto. Iniciar SalesBot não comprova entrega WhatsApp. Agente diferente ativo não é substituído silenciosamente. Cancelamento não desfaz mensagem já enviada nem encerra um bot já iniciado no Inbox.

Automações de etapa: persistência, reserva compartilhada entre execução imediata/agendada, rechecagem da definição habilitada, processamento pelo servidor e rejeição de operador sem permissão antes de usar o cliente privilegiado. Grupos, workflow e integrações Meta ainda possuem dependências não homologadas.

## Validação efetivamente realizada

46 verificações desta frente passaram no build: 13 de filtros, 16 de orquestração, 11 do contrato de integração e seis de autorização. Lógica real com transporte simulado e inspeção de fontes; não são testes de envio real.

A sonda da primeira migration executou CRUD de público, campos/valores/tarefas, preservação após falha na substituição atômica, referências inválidas e isolamento. Registros revertidos.

A sonda SQL da fila inicialmente falhou pelo local_id obrigatório no bot temporário, com transação abortada. A tentativa corrigida foi bloqueada pela ferramenta e não executada. A fila não foi declarada homologada com base nos testes locais. Consulta posterior daquela etapa confirmou zero registros temporários.

## Configurações: bloqueio não resolvido por este pacote

A migration slim_restore_settings_security_and_invitations foi bloqueada e não aplicada. Não foi colocada em script de implantação para contornar a restrição. As correções posteriores de lógica/UI não criam esse backend.

Segurança, dispositivos, MFA/passkeys/recuperação e convites não estão declarados prontos. Preferência salva não comprova aplicação da proteção. Permanecem os avisos do advisor registrados no checkpoint seguinte.

## Dashboard: continuidade executada

Campos/valores foram restaurados nesta frente por serem dependências de Públicos. Envios de formulários, fontes de tracking e agregação foram tratados depois de Configurações, nas migrations 20261015125725 e 20261015130340. Ver o documento da continuidade para testes, publicação e limites. A coleta no site e a navegação autenticada ainda não foram homologadas.

Nenhuma mensagem real foi enviada durante testes, nenhuma chave foi lida/rotacionada, nenhuma conta real foi criada e a conexão Evolution foi preservada. Sem mudanças em main, DNS, Harpia, MCP, MktOn original, Pedidos, GitHub Actions ou agente Lovable.
