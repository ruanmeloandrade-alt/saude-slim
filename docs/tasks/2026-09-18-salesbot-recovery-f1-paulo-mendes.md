# MKTOn SalesBot Recovery — Frente 1 — Paulo Mendes

**Chave:** `MKTON-SALESBOT-RECOVERY-F1-PAULO`  
**Branch canônica:** `work/salesbot-recovery-f1-paulo`  
**Status atual:** 🟢 FINALIZADA — RECUPERAÇÃO, MERGE E SMOKE PÓS-MERGE CONCLUÍDOS  
**Data:** 2026-09-18

## Objetivo

Recuperar de forma segura os SalesBots da conta/workspace **Paulo Mendes**, com prioridade para o bot `Comercial · Pré-atendimento Qualificatório`, reconstruindo o último estado comprovadamente válido sem apagar as correções que o owner estiver fazendo agora.

Esta frente é **exclusivamente de recuperação de dados do Paulo Mendes**. Não corrige o código estrutural do Builder; isso pertence à F3.

## Evidência inicial já confirmada

Workspace operacional:
- nome: `Paulo Mendes`;
- workspace_id: `52bd93fb-abae-4ddc-961e-cc3d7f8980c0`.

Estado observado em 2026-09-18:
- aproximadamente 40 SalesBots;
- aproximadamente 2.879 blocos no workspace;
- o bot `Comercial · Pré-atendimento Qualificatório` estava sendo alterado pelo owner durante a investigação e não deve ser sobrescrito às cegas;
- há registros históricos de execução apontando para UUIDs de blocos que não existem mais como linhas atuais;
- UUID histórico ausente **não é, sozinho, prova suficiente de perda lógica**, porque versões antigas do salvamento podiam recriar linhas com novos UUIDs;
- existe pelo menos outra cópia com o mesmo `local_id` em outro workspace, que pode servir como evidência comparativa de linhagem, nunca como fonte automática sem validação.

## Regra de segurança máxima

Antes de qualquer UPDATE/INSERT/DELETE em SalesBots do Paulo:

1. capturar snapshot completo e imutável do estado atual do workspace/bots/blocos/gatilhos/settings/ligações;
2. registrar timestamp e hash/contagens do snapshot;
3. reconsultar `updated_at` imediatamente antes da escrita;
4. se o bot tiver mudado depois do snapshot, refazer a comparação e preservar as alterações novas;
5. nunca executar SalesBot, disparar mensagem, ativar/desativar bot ou alterar lead durante a recuperação;
6. nunca restaurar por UUID antigo apenas;
7. nunca substituir o bot inteiro por uma cópia de outro cliente sem prova de equivalência lógica.

Se a infraestrutura definitiva de revisions da F3 ainda não estiver disponível, esta frente deve criar/usar um mecanismo de snapshot de recuperação não invasivo sem esperar a F3.

## Fontes de reconstrução, em ordem de confiança

1. estado atual das tabelas `salesbots` e `salesbot_blocks`;
2. `local_id` estável de bot/bloco;
3. `salesbot_runs` + `salesbot_run_logs` para confirmar existência/uso histórico;
4. configs de branches/next ids ainda referenciadas em blocos sobreviventes;
5. bots duplicados/REPARO existentes no próprio workspace;
6. cópias homologáveis com mesmo `local_id` em outros workspaces, somente após comparar estrutura, conteúdo e linhagem;
7. qualquer snapshot/versionamento existente no banco.

## Estratégia de recuperação

- determinar janela provável do incidente;
- construir diff lógico `estado comprovado anterior → estado atual`;
- classificar cada bloco/ligação como:
  - 🟢 comprovado e recuperável;
  - 🟡 provável/ambíguo;
  - 🔴 sem evidência suficiente;
- restaurar automaticamente somente itens 🟢;
- preservar edições atuais do owner;
- para item 🟡, documentar e não inventar conteúdo;
- reconstruir referências usando `local_id`, não UUID histórico bruto;
- validar `next_block_id`, branches em config, start block, gatilhos, settings e escopo;
- realizar recuperação em transação quando aplicável;
- manter bot ativo/pausado exatamente como estava antes da recuperação, salvo evidência explícita de que o incidente alterou esse estado.

## Critérios de verde

A frente só fica 🟢 quando:

- snapshot pré-recuperação foi preservado;
- estado recuperável do Paulo foi reconstruído e aplicado sem sobrescrever edição mais nova;
- nenhuma referência estrutural ficou apontando para bloco inexistente;
- nenhum SalesBot foi disparado durante a recuperação;
- contagem/estrutura pós-recuperação foi comparada com as evidências;
- diferenças ambíguas ficaram documentadas, não inventadas;
- smoke de leitura do Builder confirma que o banco devolve o conjunto esperado do bot;
- handoff registra exatamente o que foi recuperado, o que não pôde ser provado e como reverter.

## Fora de escopo

- corrigir outras contas;
- mudar arquitetura global de persistência/carregamento;
- alterar Inbox/WhatsApp;
- Cora;
- usar chat/agente Lovable.

## Acessos obrigatórios

- GitHub canônico;
- Supabase operacional `wqriaxzymngkntccljjp`, usando ponte SQL da Lovable se o conector direto negar acesso;
- Lovable apenas leitura/status/ponte operacional;
- proibido `send_message`/chat/agente Lovable.

## Checkpoint final — recuperação executada em 2026-09-18

### Proteção antes da escrita
- 🟢 Snapshot completo pré-recuperação gravado em área privada do banco: **40 bots / 2.879 blocos**.
- 🟢 Snapshot específico do `Comercial · Pré-atendimento Qualificatório` também versionado em `docs/recovery/2026-09-18-paulo-pre-atendimento-snapshot-current.json`.
- 🟢 Toda escrita relevante revalidou `updated_at` antes de começar a transação.
- 🟢 Nenhum dos bots restaurados possuía run ativa/aguardando durante a alteração.
- 🟢 Nenhum SalesBot foi executado e nenhuma mensagem/lead foi disparado pela recuperação.

### Bots restaurados

#### Reativação · Ativação 02
Antes:
- 120 blocos;
- estrutura incompleta;
- dois blocos de reparo manual fora do desenho canônico.

Depois:
- **121 blocos**;
- **107 ligações principais**;
- **1 start block**;
- **0 referências quebradas**;
- **121/121 blocos alcançáveis a partir do início**.

A recuperação preservou o ciclo 02, o stage Ativação 02 e o destino de timeout para Pausa 03.

#### Reativação · Ativação 03
Antes:
- 110 blocos;
- múltiplos nós estruturais ausentes;
- dois blocos de reparo manual fora do desenho canônico.

Depois:
- **121 blocos**;
- **107 ligações principais**;
- **1 start block**;
- **0 referências quebradas**;
- **121/121 alcançáveis**.

A recuperação preservou o ciclo 03, o stage Ativação 03 e o destino para Pausa 04.

#### Reativação · Ativação 04
Antes:
- 109 blocos;
- apenas 6 ligações principais sobreviventes;
- 12 nós estruturais ausentes.

Fonte de recuperação:
- `Reativação · Ativação 04 · REPARO`, cópia específica do ciclo 04 com 121 blocos, stage 04 e ciclo 04 corretos.

Depois:
- **121 blocos**;
- **107 ligações principais**;
- **1 start block**;
- **0 referências quebradas**;
- **121/121 alcançáveis**.

Os 109 UUIDs sobreviventes do original foram reaproveitados por posição/tipo e apenas os nós realmente ausentes receberam novos UUIDs.

#### Comercial · Pré-atendimento Qualificatório
Referência de reconstrução:
- execução íntegra mais recente de 2026-09-17;
- mensagens reais enviadas/recebidas;
- campos personalizados criados no mesmo dia;
- arquivos de mídia ainda existentes no bucket privado;
- estrutura sobrevivente do próprio bot.

O fluxo íntegro reconstruído contém **33 blocos** e preserva:
- início → tag → responsável;
- pergunta conjunta de nome + idade;
- gravação da resposta no campo **Nome Idade**;
- pergunta e gravação de **Renda Familiar**;
- pergunta e gravação de **Profissão**;
- pergunta “Você já sabe como funciona? 1 Sim / 2 Não”;
- validação numérica 1/2;
- caminho “2” com o áudio que foi usado no teste de ontem;
- bifurcação expediente/fora do expediente;
- handoff para Atendimento Humano;
- abandono para Pré-Follow.

Cinco blocos `blk_*` criados no reparo emergencial de hoje foram removidos **somente depois** da reconstrução histórica estar completa na mesma transação.

Estado final:
- **33 blocos**;
- **1 start block**;
- **0 referências quebradas**;
- **33/33 blocos alcançáveis**;
- **0 blocos emergenciais `blk_*` remanescentes**.

### Único ponto reconstruído por inferência controlada
O timeout de 30 minutos após “Você já sabe como funciona?” nunca chegou a executar na run de referência e seu bloco original havia sido removido.

Não foi inventado um comportamento novo. O caminho foi reconstituído para **Pré-Follow** porque:
1. o `settings.purpose` do próprio bot registra “abandono 25min → Pré-Follow”;
2. as três pausas anteriores do mesmo fluxo já usam o mesmo contrato;
3. o restante da cadeia `Origem Pré-Follow → Data Entrada → Etapa → mover para Pré-Follow → encerrar` sobreviveu intacto.

Este é o único trecho marcado como inferência controlada; o restante da sequência recuperada possui evidência direta de runtime/configuração.

### Validação global da conta Paulo Mendes
Após a recuperação foi feita varredura de **todos os 40 SalesBots**:
- cada bot possui exatamente 1 início;
- **0 referências diretas ou internas quebradas**;
- **0 blocos inalcançáveis**;
- 100% dos blocos de cada bot são alcançáveis a partir do start.

Bots grandes também aprovados:
- Leads Frios · Cronômetro: **537/537** alcançáveis;
- Leads Frios · Disparo: **359/359** alcançáveis;
- Reativação · Ativação 01–10: **121/121 cada**;
- Comercial · Pré-Follow: **59/59**.

### Snapshot pós-recuperação
- 🟢 Snapshot privado pós-recuperação: **40 bots / 2.907 blocos**.
- Diferença líquida de +28 blocos em relação ao snapshot prévio corresponde exatamente aos nós recuperados:
  - Ativação 02: +1;
  - Ativação 03: +11;
  - Ativação 04: +12;
  - Pré-atendimento: +4 líquidos (9 nós históricos restaurados e 5 remendos emergenciais removidos).

### Acesso operacional
- Conector Supabase direto ao projeto canônico permaneceu sem permissão nesta sessão.
- Banco operacional foi acessado pela ponte SQL da Lovable, conforme autorizado em `AGENTS.md`.
- Chat/agente Lovable/`send_message` **não foi usado**.

### Rollback
- O snapshot privado pré-recuperação preserva o estado dos 40 bots imediatamente antes das escritas.
- O JSON versionado preserva o estado específico do Pré-atendimento antes da restauração.
- O snapshot pós-recuperação estabelece a nova baseline validada.

## Semáforo final

- Snapshot pré-recuperação: 🟢
- Reconstrução forense: 🟢
- Diff de recuperação: 🟢
- Aplicação segura: 🟢
- Integridade dos 40 bots: 🟢
- Snapshot pós-recuperação: 🟢
- Mensagens/runs disparados pela recuperação: **0**
- Estado global: **🟢 FINALIZADA**

## Fechamento de integração

- PR: **#228**
- Merge em `main`: `b915dd73907d72699fdb9977cc292ed20786c496`
- Smoke pós-merge repetido no banco operacional:
  - 40 SalesBots;
  - 2.907 blocos;
  - 40/40 com exatamente 1 start;
  - 0 referências quebradas;
  - 0 blocos inalcançáveis;
  - Pré-atendimento: 33/33;
  - Ativação 02: 121/121;
  - Ativação 03: 121/121;
  - Ativação 04: 121/121;
  - 9 blocos críticos recuperados do Pré-atendimento confirmados;
  - objeto de áudio original confirmado no storage;
  - snapshot pré e pós-recuperação confirmados na store privada.

A Frente 1 não possui pendência técnica remanescente.
