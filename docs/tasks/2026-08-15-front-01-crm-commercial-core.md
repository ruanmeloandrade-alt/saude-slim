# Frente 01 — CRM e base comercial — MKTOn

Status: **🔴 NÃO INICIADA**
Chave canônica: `MKTON-F01-CRM`
Gatilho legado aceito: `Inicie a Frente 01 da MKTOn.`
Dependência: Frente 00 concluída ou bloqueada apenas por provider externo sem impacto nesta frente.

Ao receber somente a chave, ler `FRONT_KEYS.md`, `AGENTS.md`, `PROJECT_STATUS.md`, Plano Mestre e este arquivo; continuar do último checkpoint sem pedir contexto repetido ao owner.

## Papel do chat
Atue como arquiteto CRM, analista de dados e desenvolvedor sênior full-stack, com domínio de funis, leads, B2B, formulários, produtos, deduplicação, webhooks, atribuição comercial e UX operacional. Preserve arquitetura existente quando funcional; corrija contratos quebrados entre UI, banco e runtime.

## Escopo
### Funil de Vendas / Automatize
- corrigir tema claro/menu quando houver contraste insuficiente;
- finalizar `Receber webhook / URL de entrada`;
- validar todos os gatilhos de etapa e fontes, condições e horários;
- permitir horário comercial e personalizado com horários reais;
- criar SalesBot a partir do gatilho e retornar ao contexto original;
- `Aplicar gatilho para todos os leads da etapa` deve executar para os atuais;
- duplicar funil em três modos: estrutura; estrutura+gatilhos/bots; estrutura+gatilhos/bots+leads;
- sanfona como ponto principal de gestão, rename inline por duplo clique, sem controles redundantes externos;
- ocultar Entrada de Leads somente na UI, preservando ingestão real.

### Ações de etapa
Validar, sem deixar opção decorativa: formulário, limpar arquivos, vincular produto com preço negociado/desconto/acréscimo, excluir lead, alterar campo, responsável, tags, etapa, tarefas, duplicar lead, mensagem interna, webhooks, Meta/CAPI, venda ganha/perdida, pausa/execução de Agente IA e SalesBot.

### Leads
- clique abre ficha completa, não Inbox;
- ficha é a visão comercial mais completa do lead;
- linguagem humana em atividades, sem `message_in/message_out`;
- pesquisa/filtros avançados;
- merge de duplicatas com decisão de conflitos por campo, etapa, responsável, contatos, tags, dados personalizados e preservação de histórico.

### Públicos
- segmentação CRM real para transmissão, reativação, Meta Custom Audience e Lookalike;
- filtros por origem, etapa, tag, produto, campos, comportamento e tracking quando disponível.

### Formulários
- organizar central (pastas/categorias/busca/filtros);
- `Puxar formulário do meu site` deve detectar/importar de URL suportada;
- formulário importado/da MKTOn deve ser reutilizável em Inbox, SalesBot e Agentes;
- validar envio do formulário correto e correlação da submissão ao lead.

### Campos personalizados
- editar campos existentes, não apenas criar;
- tipos coerentes, incluindo seleção/múltipla seleção e tipos já existentes;
- contrato tipado para `Definir campo`: campo de destino controla fontes/valores compatíveis; usar inteligência da Condição como referência.

### Empresas
- consolidar central B2B: logo, dados, funcionários/contatos, setores/departamentos, responsáveis e relações com leads.

### Produtos
- `Vincular produto` deve existir no CRM e integrar com SalesBot;
- preço efetivo negociado pode diferir do catálogo sem alterar preço-base;
- preservar vínculo comercial para receita/relatórios.

### Gestor de CRM
- análise autônoma; execução somente após aprovação;
- sem modos redundantes leitura/execução;
- horário configurável ou 24h;
- acesso ao histórico completo das conversas;
- gerar alertas/sugestões apenas quando houver evidência útil;
- registrar motivo, evidência, recomendação, aprovação/rejeição e execução.

## Dependências/contratos
- CRM é fonte de verdade comercial;
- Tracking fornece eventos/origem, mas atribuição final será fechada na Frente 05;
- SalesBot/Agentes consomem os contratos desta frente, não devem duplicar modelo de lead/campo/produto.

## Critérios de aceite
Cada item crítico deve ter teste de UI + persistência + server/runtime + regressão. Não considerar pronto apenas por salvar configuração. GitHub Actions não é gate; seguir validação direta de `AGENTS.md`/`FRONT_KEYS.md`.

## Handoff
Atualizar este arquivo, Plano Mestre e `PROJECT_STATUS.md` com tarefas 🟢/🟡/🔴, testes, migrations materializadas, riscos e contratos que as Frentes 02/03/05 devem consumir.