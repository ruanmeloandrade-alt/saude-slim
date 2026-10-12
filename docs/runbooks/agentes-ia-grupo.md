# Rota operacional — Agentes IA de grupo

## Objetivo
Criar, atualizar e validar agentes IA destinados a grupos sem misturar configuração com agentes individuais.

## Regra de implementação
Toda alteração de código, documentação, migration ou provisionador é feita no GitHub. A Lovable pode ser usada pelo ChatGPT apenas como gateway de banco/query para dados reais quando necessário; nunca para prompt, edição de código ou programação.

## Fonte de verdade
Tabela principal: `group_ai_agents`.
Execuções: `group_agent_runs`.

Campos centrais: `workspace_id`, `name`, `persona`, `system_prompt`, `model`, `temperature`, `max_tokens`, `respond_only_when_mentioned`, `cooldown_seconds`, `enabled`, `tools`, `metadata`, `triggers`.

## Ordem
1. Resolver o workspace pelo `workspaces.slug`.
2. Listar agentes de grupo existentes antes de criar.
3. Reaproveitar o agente correto quando for a mesma função.
4. Configurar persona, prompt, ferramentas e gatilhos específicos de grupo.
5. Revisar `respond_only_when_mentioned` e `cooldown_seconds` conforme o comportamento desejado.
6. Manter desativado até concluir gatilhos e permissões.
7. Validar o registro e, quando aplicável, uma execução real em `group_agent_runs`.

## Proteções
- não gravar em `conversation_ai_agents` quando o agente é de grupo;
- não copiar gatilho de agente individual sem revisar contexto;
- não ativar com trigger vazio/incompatível quando o agente depende de condição de grupo;
- preservar metadata/tools existentes fora do escopo da mudança.
