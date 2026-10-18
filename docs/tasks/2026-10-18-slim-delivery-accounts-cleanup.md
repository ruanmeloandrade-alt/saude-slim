# Saúde Slim — preparação de entrega e limpeza dos testes — 18/10/2026

## 🟢 Concluído e liberado para configurar o cliente

O usuário forneceu dois e-mails e senhas para criar duas contas administradoras, uma do cliente e uma dele, e solicitou remover os dados dos testes, a instância WhatsApp e os bots. As duas contas foram criadas e passaram pelo login real. A base operacional ficou vazia, com estrutura inicial e acessos preservados.

Escopo exclusivo: Supabase vyzvfcgpjjzvcjegzzza, workspace operacional c49945db-1960-461a-9339-a43b8403bdd9, repositório ruanmeloandrade-alt/saude-slim. Nenhuma senha, chave, e-mail, telefone ou conteúdo de conversa está registrado neste documento ou nos scripts versionados.

## Requisitos e limites recebidos

- Criar exatamente dois administradores na empresa operacional, usando o Auth Admin existente; confirmar contas e permissões sem convites por e-mail.
- Remover cadastros, bots, agentes, regras, públicos, campanhas, históricos e arquivos dos testes.
- Desconectar e excluir as instâncias WhatsApp de teste da Saúde Slim.
- Preservar a empresa, módulos, infraestrutura e estrutura padrão para nova configuração.
- Preservar as identidades e vínculos anteriores. Não transferir propriedade, conceder super_admin global ou excluir Auth por inferência. A identidade proprietária possui FK ON DELETE CASCADE para a empresa.
- Preservar os registros técnicos de segurança/idempotência e os documentos de entrega. Nenhuma mensagem de WhatsApp, convite por e-mail ou cobrança foi enviada pela equipe.

## Contas e login real

As duas identidades foram criadas pelo formulário Equipe do aplicativo, com nome correto, e-mail confirmado, senha configurada, conta ativa e vínculo admin/admin sem expiração. Ambas selecionam automaticamente a Saúde Slim operacional. Criado setor Administração.

O login do administrador solicitante foi testado inicialmente às22:21 UTC. Após a limpeza, o administrador cliente entrou às23:46:46 UTC e o solicitante às23:47:27 UTC. Auth confirmou os horários de last_sign_in_at; o navegador carregou a operação autenticada em ambos os casos. A última aba foi deixada no Histórico de Vendas, autenticada como solicitante.

Permanecem quatro memberships: dois novos administradores, a identidade proprietária anterior e o funcionário anterior. Não houve troca de propriedade nem exclusão das duas identidades antigas.

## Inventário e reconciliação

Inventário inicial: 26 leads, 3 SalesBots, 1 agente individual, 6 execuções de bot, 2 campanhas, 2 pedidos, 1 produto, 40 grupos, 360 mensagens, 439 atividades e5 sessões locais WhatsApp.

Durante o preparo, chegaram três pares adicionais de mensagem/atividade da mesma sessão de teste, às21:42 e22:12 UTC, antes da remoção da instância. O preflight impediu a limpeza enquanto os limites eram360/439. A consulta dos metadados confirmou 363 mensagens e442 atividades, sem novos leads, bots ou outros cadastros. Ajustados somente esses dois limites após reconciliação.

## Desligamento e exclusão externa

Primeiro foram desabilitados 2 SalesBots ativos, 1 agente e1 automação de etapa. Não havia jobs/execuções pendentes.

A operação externa usou exclusivamente as credenciais já existentes no processo do web service, sem extrair valores. O preDeployCommand temporário tinha escopo de cinco nomes de instância e seis arquivos, flag explícita de execução e expiração em 19/10/2026 às00:00 UTC. Cada requisição tinha prazo15s, limite2MB e nenhuma repetição/redirect; operação total180s e timeout do predeploy240s.

Histórico material:
- O primeiro redeploy reutilizou uma configuração antiga e não executou a operação externa; não foi considerado evidência de limpeza.
- O primeiro predeploy real removeu a instância conectada e interrompeu ao receber HTTP400 no logout de uma sessão antiga com QR pendente.
- A sessão pendente foi removida pelo comando existente Remover instância no aplicativo. Nenhuma instância ou mensagem nova foi criada.
- O rerun do deployment 4bdd3c83 confirmou os cinco nomes de instância ausentes. Às22:24:11.718 UTC, o recibo registrou 6 arquivos excluídos,0 objetos residuais e0 instâncias alvo.
- Os cinco registros locais foram marcados desconectados/excluídos somente depois da ausência remota; depois foram removidos pelo bloco SQL final.
- O preDeployCommand foi restaurado para[] e o timeout temporário foi retirado. Não há configuração de limpeza pendente.

Os seis arquivos foram removidos pela API Storage. Nenhuma exclusão SQL foi aplicada a storage.objects. A infraestrutura Evolution/Railway foi preservada para o novo WhatsApp do cliente.

## Execução relacional efetiva

A transação original com múltiplas instruções retornou Invalid or expired requestState duas vezes. Uma adaptação para um único DO retornou o mesmo erro. As consultas posteriores confirmaram que essas tentativas não apagaram registros. O conector não informou recusa de aprovação; a causa técnica exata não foi confirmada.

Um DELETE explícito, limitado ao único job done auditado, workspace, owner e dois administradores, foi aceito. Depois, a operação foi concluída em quatro blocos CTE explícitos, na ordem filhos antes de pais. Cada bloco:
- Calculou uma autorização MATERIALIZED com empresa/owner, dois administradores ativos, perfil na empresa e cinco sessões exatas já desconectadas/excluídas.
- Bloqueou a empresa durante a instrução e exigiu remetentes desligados e contagens dentro dos limites auditados.
- Limitou todo DELETE à empresa autorizada. A fonte e etapa extras exigiam também os IDs exatos.
- Usou dependência do RETURNING anterior para ordenar os efeitos e retornou as contagens efetivas.
- Retornou authorized=true e as quantidades esperadas.

A sequência dos quatro blocos não foi uma transação global única. O preflight original, sem mutações relacionais, passou após a reconciliação e verificou estrutura, FKs entre empresas, estados ociosos e acessos. As verificações finais foram feitas em chamadas independentes das exclusões.

Total: 967 registros operacionais diretamente removidos, incluindo o job individual, históricos, entidades e os dois registros extras de estrutura. Um registro privado de credencial de integração foi removido pelo cascade previsto.

## Resultado conferido às23:45:53 UTC

| Área | Estado final |
|---|---|
| Leads/clientes de teste |0|
| SalesBots / agentes individuais / regras de etapa |0 /0 /0|
| Públicos / campanhas / execuções e logs |0|
| Pedidos / produtos / fornecedores / movimentos de estoque |0|
| Grupos / mensagens WhatsApp / atividades de lead |0 /0 /0|
| Sessões WhatsApp / integrações / credenciais privadas de integração |0 /0 /0|
| Arquivos de teste associados ao workspace |0|
| Funil / etapas padrão / fonte padrão / catálogo vazio |1 /4 /1 /1|
| Novos administradores |2|
| Memberships totais preservados |4|

Todas as 47 tabelas operacionais auditadas retornaram zero. Também foram conferidos0 arquivos em Storage e0 credenciais privadas da integração removida.

Os22 valores de verificação da empresa, perfis novos, memberships, permissões, setores, defaults, guard de sessão e ledgers privados permaneceram iguais antes/depois. As192 políticas conservaram o hash 3c1767d874321020684cfbafc8ec5460; o guard slim_assert_session_security conservou cea919fe8a00fd3be21482665196f997.

## Produção e validação visual

Versão e33b28722b733ff849b15eaba22cc250931d4931, deployment 4bdd3c83-7377-406f-a420-33dae954bb54 SUCCESS. Healthcheck1/1 aprovado às22:24:28 UTC. Conferência final: quatro serviços online, uma réplica cada, nenhum aviso crítico/alerta e nenhuma operação pendente.

Não houve alteração de código funcional da aplicação neste pedido. A compilação completa e os gates da versão e33 passaram no Railway. Script externo: sintaxe e três cenários CLI sintéticos aprovados (execução dos alvos, dry-run com 0DELETE, recusa de objeto inesperado com 0DELETE). Operação SQL e ordem/FKs dos blocos receberam revisão independente.

Após os dois logins reais, Integrações exibiu 0 conexões e WhatsApp pronto para conectar; Histórico de Vendas exibiu 0 registros e R$0,00. Nenhum dado comercial novo foi criado para esse smoke.

## Estado de entrega e arquivos

🟢 Pedido concluído. O usuário pode configurar seus produtos, públicos, bots e integrações do cliente. O WhatsApp e a chave de IA precisam da nova configuração desejada após a remoção dos testes.

Contas antigas de proprietário/funcionário e ledgers técnicos permanecem. Os antigos IDs e números de testes citados em outros escopos são evidências históricas; os registros operacionais correspondentes foram apagados por esta solicitação. O aceite anterior das funcionalidades continua registrado.

Arquivos:
- scripts/operations/2026-10-18-slim-handoff-cleanup-external.mjs — operação externa limitada.
- supabase/operations/2026-10-18-slim-handoff-cleanup.sql — adaptação DO revisada, sem sucesso de execução; não repetir após a limpeza.
- supabase/operations/2026-10-18-slim-handoff-cleanup-batches.sql — quatro blocos efetivamente executados.
- docs/tasks/2026-10-18-slim-handoff-cleanup-receipt.json — recibo agregado e contagens/hashes, sem credenciais ou conteúdo de cliente.

A documentação final permanece na branch de trabalho, sem deployment extra apenas para atualizar status.
