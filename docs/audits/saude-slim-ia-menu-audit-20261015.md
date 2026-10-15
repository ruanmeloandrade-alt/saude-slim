# Saúde Slim: auditoria dos Agentes IA e do menu operacional

## Escopo e isolamento

Base examinada: commit 1cbd6c1c658e2d3782cf379fef3787dced28d513 da branch restauracao/sistema-completo-20261014, repositório ruanmeloandrade-alt/saude-slim. Banco exclusivo: vyzvfcgpjjzvcjegzzza. Serviço web existente: saude-slim-web, Railway ae81dbf0-2b77-4729-9055-c25ec98d6117. Não alterar main, conector Evolution, DNS, projetos originais, Harpia, GitHub Actions ou serviços Lovable.

Pedido: concluir diagnóstico antes de corrigir; começar pelos Agentes IA e seguir o menu lateral até Configurações. Preservar seleção/encerramento individual de bots no Inbox, salvamento manual e autosave de 120 segundos. Não disparar mensagens para clientes reais durante testes.

## Diagnóstico anterior

A única auditoria específica da Saúde Slim encontrada em docs/audits cobre salvamento SalesBot, não o sistema completo. O relato do usuário confirma um envio SalesBot no Inbox; não constitui homologação dos demais módulos.

## Evidência inicial

Log de produção 2026-10-15T02:13:07Z: integração OpenAI chega ao set_integration_secret, que falha por função inexistente no schema cache. O código valida a chave no endpoint OpenAI antes desse passo. No banco não existem integrations, set_integration_secret ou get_integration_secret. INTEGRATION_ENCRYPTION_KEY foi acessada pelo servidor antes da chamada, sem falhar. Não ler, registrar, substituir ou publicar seu valor.

Também não existem ai_agent_settings, ai_agent_conversations e support_robot_messages, referenciadas pelo backend de agentes. O resolvedor workspace-ai-key.server.ts descarta os erros das RPCs e pode apresentar indevidamente um erro de chave ausente. A mensagem de falha do cofre ainda cita MKTOn.

## Ordem efetiva do menu e diagnóstico estrutural

1. Agentes IA: corrigir cofre, armazenamento/recuperação segura, tratamento de erros e persistência. Testar autorização e isolamento sem chaves reais em logs.
2. Home: /saude-slim (Histórico de Vendas) e /painel (Dashboard detalhada). Histórico usa saude-slim-sales-client; painel usa componentes e funções herdados. Presença de tabelas não é prova de indicadores corretos.
3. Vendas: /pedidos, /crm/empresas, /crm/estoque, /crm/produtos, /disparo-em-massa. Leads, produtos, catálogos e supplier_product_costs existem. Pedidos/estoque têm adaptadores próprios; fornecedores/produtos ainda incluem serviços herdados. Disparo depende de Públicos e Evolution.
4. CRM: /crm/funis-de-venda, /crm/leads, /inbox/leads, /crm/automacoes, /crm/agente-ia, /crm/publicos. Cérebro tem fontes/chunks/termos bloqueados. Faltam crm_lead_audiences, crm_automation_jobs, lead_custom_fields e lead_custom_field_values entre as dependências examinadas. Não habilitar disparos reais para testar.
5. Configurações: /configuracoes e /integracoes. Equipe/permissões/notificações individuais têm estruturas existentes. Faltam, entre outros, workspace_security_settings, trusted_devices, security_events, device_approval_challenges, notifications e RPCs can_admin_workspace, preview_invitation, accept_invitation. Integrações externas opcionais têm outras estruturas ausentes e exigem separação de falha versus não configurado.
6. Fase 2 está explicitamente desabilitada no menu e permanece fora do trabalho de ativação.

## Critérios de aceite

- Distinguir falha estrutural, erro de credencial, serviço não configurado e ausência legítima de dados.
- Credenciais criptografadas; somente servidor utiliza a chave do ambiente. Sem fallback para chaves/projetos de terceiros.
- RLS e isolamento entre workspaces mantidos. RPCs públicas com SECURITY INVOKER; sem liberar anon.
- Testes de persistência, releitura, rejeição de acesso indevido, erro de chave e limpeza/rollback das sondas.
- Código versionado, publicação comprovada e testes aplicáveis registrados.
- Não afirmar homologação integral sem navegação autenticada e operações reais controladas. Teste de banco, build e HTTP não substituem teste ponta a ponta.

## Status inicial

Diagnóstico estrutural inicial registrado antes das correções. Auditoria funcional integral e homologação de todos os itens ainda pendentes. Próxima alteração: restauração segura do cofre e das dependências mínimas de IA. Nenhuma chave de usuário foi obtida ou reproduzida neste documento.
