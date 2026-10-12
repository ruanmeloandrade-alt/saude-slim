# Sulamita de Paula — bot de conteúdo para loja de material de construção

Data: 2026-09-19  
Workspace: `Sulamita De Paula`  
Workspace ID: `8d323c29-d890-4220-b7f9-7a7025024bfd`  
Estado: **🟢 CONCLUÍDO / DEMO VISÍVEL NO FUNIL E MANTIDO OFF**

## Pedido do owner

Criar um SalesBot completo de **primeiro atendimento para loja de material de construção**, destinado à produção de conteúdo/demonstração pela Sulamita.

O bot não deve focar apenas em cimento ou telha. A copy deve cobrir materiais de construção de forma geral: estrutura, alvenaria, cobertura, hidráulica, elétrica, ferragens, ferramentas, acabamento e demais itens da obra/reforma.

## Contrato do bot

- primeiro atendimento curto: até 4 interações relevantes antes do handoff;
- nome perguntado, sem gravação automática;
- entender materiais/lista solicitada;
- entender quantidades/medidas disponíveis;
- entender retirada/entrega, região e prazo;
- salvar somente os campos operacionais úteis;
- atribuir Sulamita;
- criar tarefa comercial;
- registrar mensagem interna;
- mover o lead para `Atendimento` ao concluir a qualificação;
- qualquer abandono do primeiro atendimento deve cair numa régua de follow-up dentro do próprio bot;
- follow-up com pausas de `msg-recebida OU cronometro`;
- resposta em qualquer follow-up deve interromper a régua, voltar o lead para `Atendimento`, criar tarefa urgente e encerrar o bot;
- silêncio total termina com tarefa humana de última tentativa e `encerrar-bot`;
- zero bloco solto;
- zero referência quebrada;
- layout em organograma, com ramo principal e follow-up separados visualmente.

## Segurança operacional

A conta Sulamita já possui o primeiro atendimento oficial `RB MÍDIA | 01 Primeiro Atendimento · Sulamita` ligado à etapa `Nova entrada`.

Para não criar disparo duplo:
- o novo bot de conteúdo será criado **ativo, mas sem gatilho interno**;
- será adicionado visualmente à etapa `Nova entrada` por uma automação **desabilitada** e explicitamente marcada como conteúdo/demo;
- o primeiro atendimento oficial RB Mídia permanecerá intacto e ativo.

## Snapshot pré-mudança

- Funil Comercial: 10 etapas;
- leads atuais no Funil Comercial: 0;
- bots RB Mídia: 10 ativos;
- automação oficial em `Nova entrada`: 1;
- WhatsApp conectado no workspace: 0 sessões;
- owner/assignee: Sulamita de Paula `1f7deeaa-ffb1-44b5-bb95-90a20e81c099`;
- workflow disponível: `RB Mídia | Operação Comercial`.

## Semáforo

- 🟢 workspace e funil auditados;
- 🟢 regras canônicas de SalesBot relidas;
- 🟢 risco de disparo duplo identificado;
- 🟡 bot e campos em produção;
- 🔴 QA estrutural final ainda não executada.

## Implementação concluída

Bot criado:
- `CONTEÚDO | Material de Construção | Primeiro Atendimento · Sulamita`
- bot ID: `e1a68000-0000-4000-9800-000000000001`
- ativo: **sim**
- gatilhos internos: **0**
- blocos: **38**

Campos demonstrativos criados:
- `DEMO | Materiais solicitados`
- `DEMO | Quantidades / medidas`
- `DEMO | Entrega / retirada / prazo`

Fluxo principal:
1. tag de contexto;
2. saudação + nome;
3. necessidade/lista de materiais;
4. quantidades/medidas;
5. retirada/entrega + região + prazo;
6. atribuição à Sulamita;
7. movimento para `Atendimento`;
8. tarefa `Montar orçamento de materiais + conferir estoque e frete`;
9. mensagem interna de contexto;
10. confirmação ao cliente;
11. `encerrar-bot`.

Ramo de abandono/follow-up:
- qualquer uma das 4 esperas do atendimento tem `msg-recebida` + timeout de 90 min;
- timeout entra numa régua própria de follow-up;
- move para `Follow-up`;
- cria tarefa de retomada;
- envia 3 contatos com pausas de 24h, 48h e 72h;
- existe tarefa humana intermediária para áudio/ligação;
- resposta em qualquer uma das 3 pausas interrompe a régua, volta para `Atendimento`, atribui Sulamita, cria tarefa urgente, registra mensagem interna e encerra;
- silêncio total cria tarefa final humana, registra nota interna e encerra sem novo disparo.

## Integração visual com o Funil Comercial

Foi criada uma automação visível na etapa `Nova entrada`:

- título: `CONTEÚDO · Material de Construção · Primeiro Atendimento`;
- bot: novo bot de conteúdo;
- estado: **OFF / desabilitada**;
- trigger configurado: `created-only`;
- posição: 90.

Motivo do OFF:
- `Nova entrada` já possui o primeiro atendimento oficial RB Mídia ativo;
- manter o demo desligado evita disparo duplo quando uma sessão WhatsApp for conectada;
- o bot continua disponível para abertura, gravação e produção de conteúdo.

## QA estrutural final

Resultado direto do banco operacional:

- blocos: **38**;
- inícios: **1**;
- arestas totais: **42**;
- referências quebradas: **0**;
- blocos alcançáveis: **38/38**;
- blocos inalcançáveis: **0**;
- terminais indevidos: **0**;
- `encerrar-bot` com saída: **0**;
- pausas sem saída de resposta: **0**;
- pausas sem timeout: **0**;
- IDs locais duplicados: **0**;
- posições duplicadas: **0**;
- referências inválidas de campo: **0**;
- referências inválidas de etapa: **0**;
- responsáveis inválidos: **0**;
- workflows de tarefa inválidos: **0**;
- etapas de workflow inválidas: **0**;
- assignees de tarefa inválidos: **0**;
- runs criadas durante implantação: **0**.

Proteção operacional:
- automação demo da `Nova entrada`: **desabilitada**;
- automação oficial RB Mídia da `Nova entrada`: **habilitada**;
- gatilhos ativos `primeira-mensagem` no workspace: **1** — somente o bot oficial.

Migration canônica:
- `supabase/migrations/20260919222500_sulamita_material_construcao_content_bot.sql`
- commit: `620cb3f1556acb5e9a580fdf1f09292844c10726`

GitHub Actions não foi usado como gate.

## Semáforo final

- 🟢 bot criado;
- 🟢 bot completo com 38 blocos;
- 🟢 follow-up interno com 3 tentativas;
- 🟢 tarefas, mensagens internas, tags, campos e mudanças de etapa;
- 🟢 zero bloco solto;
- 🟢 zero referência quebrada;
- 🟢 38/38 blocos alcançáveis;
- 🟢 visível em `Nova entrada`;
- 🟢 protegido contra disparo duplo por automação demo OFF;
- 🟢 primeiro atendimento oficial da Sulamita preservado.

