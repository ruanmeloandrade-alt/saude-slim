# Saúde Slim: retomada da auditoria do Agente IA

Status: EM EXECUÇÃO. Não declarar atendimento IA nem auditoria global concluídos.

## Destino exclusivo

- Repositório: ruanmeloandrade-alt/saude-slim.
- Base de produção: restauracao/sistema-completo-20261014, commit 1cbd6c1c658e2d3782cf379fef3787dced28d513.
- Branch de trabalho: fix/ia-vault-audit-20261015.
- Supabase: vyzvfcgpjjzvcjegzzza.
- Railway: projeto ae81dbf0-2b77-4729-9055-c25ec98d6117; serviço 9f4b1d9b-ee8a-4048-b5f2-99087988deb5; ambiente f9d4ca40-bba7-4409-822e-d5de5ad62dbe.
- Nenhuma alteração na MKTOn original, Harpia ou MCP. Referências herdadas no AGENTS.md não mudam este destino.

## Pedido e prioridade

Corrigir primeiro a integração OpenAI e o Agente IA, preservando o SalesBot e seus controles por conversa já testados pelo usuário. Auditar também home, vendas, histórico, dashboard, pedidos, fornecedores, produtos, disparos, CRM, público, cérebro, automações e Inbox. Separar leitura estática, teste automatizado, banco, publicação e validação real de mensagens.

## Evidências verificadas nesta retomada

- Railway apresenta deploy SUCCESS, id 9d497f5d-1d8a-4298-8271-bebbef5238c7.
- INTEGRATION_ENCRYPTION_KEY está listada no ambiente. Seu valor não foi lido nem alterado.
- Log de 2026-10-15T02:13:07Z: [integration-vault] set_integration_secret Could not find the function public.set_integration_secret(_key, _metadata, _plaintext, _provider, _status, _workspace_id) in the schema cache.
- src/lib/integrations.functions.ts usa o RPC acima, após validar a chave na OpenAI. src/lib/workspace-ai-key.server.ts lê get_integration_secret(_workspace_id, _provider, _key).
- Inventário Supabase: public.integrations não aparece; schema private não possui tabelas. A lista de migrations aplicadas não inclui implantação de cofre de integrações.
- conversation_ai_agents e conversation_agent_runs existem, com zero registros no inventário. SalesBot foi confirmado funcionando pelo usuário, não reproduzido nesta sessão.
- O resolver de IA ignora erros do RPC de leitura e pode apresentar incorretamente ausência de chave em vez de indisponibilidade do cofre.
- Uma consulta de catálogo via execute_sql foi bloqueada pela ferramenta e não executada. Não contornar esse bloqueio com outra credencial/serviço. Metadados foram obtidos pelas ferramentas list_tables/list_migrations/list_extensions.

## Correção delimitada

Preparar o contrato faltante de armazenamento criptografado, com isolamento por workspace, metadados públicos sem credencial, chave de criptografia somente no servidor e sem fallback para conta original. Corrigir propagação de erros do cofre e mensagem herdada MKTOn. Não modificar salvamento, temporizadores ou envio do SalesBot.

## Critérios de aceite

1. Assinaturas de RPC compatíveis com o frontend atual.
2. Nenhum segredo em log, resposta pública, GitHub ou variável de frontend.
3. RLS ativa e controle de acesso por workspace; anônimos sem acesso.
4. Falha de cofre não é mascarada como integração desconectada.
5. Testes de regressão direcionados aprovados antes da promoção do código.
6. Banco implantado e verificação pós-implantação distinguida de chamada real à OpenAI/WhatsApp.
7. Nenhuma mensagem de teste enviada a clientes e nenhum dado de teste deixado no banco.

## Limitações atuais

Checkout integral não disponível no container: resolução DNS do GitHub falhou. Leituras pelo conector GitHub funcionam. Não há sessão autenticada de navegador nem teste real de entrega IA nesta retomada. Não declarar a home ou o módulo de vendas auditados apenas por inventário de tabelas.
