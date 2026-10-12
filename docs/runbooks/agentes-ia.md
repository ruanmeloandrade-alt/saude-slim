# Rota operacional — Agentes IA

## Objetivo
Criar, atualizar e conectar agentes IA individuais ao workspace correto, preservando objetivos, ações e configuração existente.

## Regra de implementação
Código, documentação, migrations e provisionadores são sempre alterados pelo GitHub. Para dados reais, o ChatGPT pode usar a Lovable apenas como gateway de banco/query quando o acesso direto ao Supabase não estiver disponível; não enviar prompt nem editar código pela Lovable.

## Fonte de verdade
Tabela principal: `conversation_ai_agents`.
Referência de provisionamento existente: `src/lib/mkton-manual-agents-briefing.server.ts`.
Arquivos auxiliares incluem regras e dados de agente em `src/lib/agent-*`.

Campos centrais: `workspace_id`, `name`, `persona`, `system_prompt`, `model`, `temperature`, `max_tokens`, `cooldown_seconds`, `enabled`, `tools`, `metadata`.

## Ordem
1. Resolver `workspace_id` pelo slug.
2. Listar agentes existentes e localizar pelo nome/identidade estável definida pelo provisionador.
3. Atualizar o agente existente quando for a mesma função; não duplicar por pequena variação de nome.
4. Preservar `metadata`, ferramentas e vínculos não envolvidos na mudança.
5. Se houver árvore de objetivos/ações no provisionador, criar os registros dependentes na ordem definida pelo código e resolver os IDs gerados.
6. Manter agente desativado enquanto configuração obrigatória estiver incompleta.
7. Validar no banco real e na tela do workspace.

## Proteções
- não trocar modelo/prompt/persona sem pedido;
- não habilitar agente com referência manual pendente;
- não apontar ação para funil/etapa inexistente;
- não recriar agentes já provisionados se puder atualizar o existente.
