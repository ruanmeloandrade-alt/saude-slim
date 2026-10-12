# Consolidação Sulamita De Paula -> Sulamita Dias

Data: 2026-09-19  
Estado: **🟢 CONCLUÍDO NO BANCO OPERACIONAL**

## Origem

- Workspace: `Sulamita De Paula`
- Workspace ID: `8d323c29-d890-4220-b7f9-7a7025024bfd`
- Login do owner: `sulamitadepaula.mkt@gmail.com`

## Destino

- Workspace: `Sulamita Dias`
- Workspace ID: `63d59eea-6f62-4f5b-aba4-ecbd6fe2c39a`
- Login do owner: `suuhdias77@gmail.com`

## Backup antes da limpeza

Batch interno: `b7a4c9cf-5c24-4f44-a00e-1c8bd87c0c11`

O snapshot foi feito antes da exclusão/movimentação e preserva os registros workspace-scoped das duas contas no banco operacional.

Resumo:
- Sulamita De Paula: 16 snapshots de tabela / 352 registros;
- Sulamita Dias: 23 snapshots de tabela / 645 registros;
- total: 39 snapshots / 997 registros.

O armazenamento interno de backup foi protegido:
- RLS habilitado;
- `anon` sem SELECT;
- `authenticated` sem SELECT.

## Limpeza do workspace Sulamita Dias

Foi removido o conteúdo operacional anterior da conta Sulamita Dias, incluindo:
- 15 bots IMOB antigos + 291 blocos;
- 3 pipelines / 21 etapas;
- 3 leads / 38 atividades;
- 4 agentes de conversa;
- 1 sessão WhatsApp / 85 mensagens;
- 41 eventos de tracking;
- revisões/auditoria de SalesBot;
- CRM source/funnel mapping anterior.

Foram preservados de propósito os itens de identidade/acesso da conta destino:
- login/owner Sulamita Dias;
- membership do workspace;
- assinatura/plano;
- módulos;
- sessões de login/dispositivos confiáveis/eventos de segurança.

## Conteúdo transferido da Sulamita De Paula

A estrutura operacional foi transferida mantendo os IDs internos para não quebrar referências:
- 4 pipelines;
- 16 etapas;
- 17 campos personalizados;
- 15 automações de etapa;
- 11 SalesBots;
- 274 blocos;
- 1 workflow pipeline;
- 5 etapas de workflow;
- 1 CRM source.

Referências de responsável dentro dos SalesBots foram atualizadas do user ID de Sulamita De Paula para o user ID de Sulamita Dias.

O bot de conteúdo criado nesta mesma frente também está no destino:
`CONTEÚDO | Material de Construção | Primeiro Atendimento · Sulamita`.

## QA pós-transferência

- 11 bots / 11 ativos;
- 274 blocos;
- 0 bots IMOB antigos;
- 0 referências de bloco quebradas;
- 0 bots sem bloco inicial;
- 0 bots com mais de um bloco inicial;
- 0 referências inválidas de etapa;
- 0 referências inválidas de campo;
- 0 responsáveis inválidos;
- 0 assignees de tarefa inválidos;
- 0 automações apontando para bot inexistente;
- 0 referências restantes ao user ID antigo de Sulamita De Paula nos blocos;
- 37 referências operacionais de responsável agora apontam para Sulamita Dias;
- 4 pipelines no destino: Funil Comercial, Remarketing, Reativação de Base e Pós-venda;
- 15 automações no destino, 14 habilitadas e 1 demo OFF;
- 0 leads;
- 0 sessão WhatsApp;
- 0 mensagens WhatsApp.

A automação demo de material de construção continua OFF para não competir com o primeiro atendimento oficial.

## Situação da origem após consolidação

A estrutura operacional da Sulamita De Paula foi movida para Sulamita Dias. O workspace original permanece existente para preservar a conta/identidade, mas está sem pipelines/bots/campos operacionais. O estado anterior está preservado no backup interno do batch acima.

GitHub Actions não foi usado como gate.
