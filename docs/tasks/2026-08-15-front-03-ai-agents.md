# Frente 03 — Agentes IA — MKTOn

Status: **🔴 NÃO INICIADA**
Chave canônica: `MKTON-F03-AGENTES-IA`
Gatilho legado aceito: `Inicie a Frente 03 da MKTOn.`
Dependências: Frentes 02 e 05 🟢; consumir contratos da Frente 01.

Ao receber somente a chave, ler `FRONT_KEYS.md`, `AGENTS.md`, `PROJECT_STATUS.md`, Plano Mestre e este arquivo; continuar do último checkpoint sem pedir contexto repetido ao owner.

## Papel do chat
Atue como arquiteto de agentes IA conversacionais, especialista em LLM orchestration, ferramentas/actions, memória/contexto, state machines, builders visuais, RAG/base de conhecimento, tracking e automações. Precisa pensar como product designer de atendimento e como engenheiro sênior.

## Escopo
### Listagem
- aproximar visualmente da Central de SalesBots;
- remover faixa/tag gigante desnecessária de Fluxo de Objetivo;
- manter diferenças na configuração, não criar duas experiências arbitrárias.

### Agente de Prompt
- preservar layout/manual que já está bom;
- validar runtime real de prompt, persona, idioma, interações, conhecimento, links, condições e ações;
- modelos prontos viram construção guiada por perguntas;
- montar agente completo, não só prompt: regras, ações, etapas, conhecimento, links e configurações;
- ampliar biblioteca de modelos por função/nicho;
- ações habilitadas devem aparecer automaticamente nas capacidades/instruções do agente.

### Fluxo de Objetivo — contrato
Definição do owner: **SalesBot com liberdade de fala**.
- somente um Contexto Geral, obrigatório e não deletável;
- remover Contexto Geral roxo duplicado;
- demais blocos e cabos deletáveis;
- Contexto Geral: estratégia, objetivo macro, conhecimento, links permitidos, produtos opcionais, desconto máximo opcional;
- remover links proibidos; whitelist de links;
- produto/desconto não habilitado = agente não toca no tema.

### Bloco Objetivo
- duas definições centrais: `o que conduzir` e `o que conclui`;
- IA responde desvios e retoma objetivo;
- link opcional com regra de quando usar;
- ação ao concluir opcional e removível;
- próxima etapa normal vs ramificação condicional;
- ramificar por interesse, venda, recusa, tag, tracking, inatividade etc.;
- caminhos malsucedidos devem poder levar a remarketing/nutrição/humano, não morrer obrigatoriamente.

### Condição
- E/OU;
- critérios ligados ao lead/contexto real: mensagem, tag, campo, etapa, origem, interações, compra, formulário, cadastro, canal, inatividade;
- Tracking exige selecionar origem + evento específico + operador + valor quando aplicável;
- incorporar validações úteis sem exigir bloco redundante.

### Tracking dentro do Agente
- corrigir origens/sites não listados;
- suportar consultas imediatas (ex.: histórico) e espera por evento (formulário/cadastro/clique/compra) com prazo/tentativas/frequência;
- histórico completo de conversa pode enriquecer contexto;
- consumir contrato final da Frente 05.

### Webhooks
- receber, ler/processar e enviar webhook;
- dados do webhook reutilizáveis em condições/ações seguintes.

### UX do Builder
- referência de clareza: Make, sem copiar identidade;
- novo bloco nasce onde o `+` foi clicado;
- conexões/ramificações claras;
- painel de configuração mais leve;
- manter mapa/canvas próprio da MKTOn.

### Estado e retomada
Consumir contrato da Frente 02:
- Iniciar Agente != Retomar Agente;
- Retomar Agente IA e Retomar SalesBot;
- retornar exatamente ao objetivo/bloco anterior com contexto persistido;
- follow-up SalesBot pode reativar lead e devolver execução ao agente.

### Agente IA de Grupo
Criar experiência própria/híbrida se necessário, para controlar:
- grupos permitidos;
- gatilhos observados;
- membro foco;
- palavra-chave;
- X interações/tempo/objetivo;
- assuntos/conhecimento;
- ações e parada.
Templates guiados: suporte por palavra-chave, puxador de conversa, mentor de conteúdo, anfitrião, moderador.

### Encerrar agente
- validar ações finais existentes;
- permitir exclusão do bloco;
- parar de responder/encerrar conversa/transferir/mudar etapa/disparar automação conforme configurado.

## Critérios de aceite
Testes precisam validar conversa real/simulada, persistência de estado, condições, tools, RAG, ramificações, retomada e isolamento por workspace. Não considerar pronto porque o Builder salva JSON. GitHub Actions não é gate; seguir validação direta de `AGENTS.md`/`FRONT_KEYS.md`.

## Handoff
Atualizar este arquivo, Plano Mestre e `PROJECT_STATUS.md`; registrar cenários E2E aprovados e qualquer limitação real de provider/modelo.