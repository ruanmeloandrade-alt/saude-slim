# MKTOn SalesBot Recovery — Frente 2 — Outras contas

**Chave:** `MKTON-SALESBOT-RECOVERY-F2-OUTRAS-CONTAS`  
**Branch canônica:** `work/salesbot-recovery-f2-other-workspaces`  
**Status inicial:** 🔴 NÃO INICIADA  
**Data:** 2026-09-18

## Objetivo

Auditar todos os workspaces do MKTOn para detectar perda lógica de blocos/estrutura de SalesBot relacionada ao carregamento/salvamento, criar backup/snapshot das contas afetadas e recuperar somente alterações comprovadamente indevidas.

**Paulo Mendes está explicitamente fora desta frente.** A recuperação dele pertence à F1.

## Evidência inicial

Workspaces atualmente com grande volume de blocos e portanto maior exposição a consultas globais de blocos:

- Lucas Bulhosa — ~3.397 blocos;
- Paulo Mendes — ~2.879 blocos (**fora desta frente**);
- Harpia Patrimonial & Co. — ~2.818 blocos;
- savio — ~2.642 blocos;
- Leandro Alves — ~2.120 blocos.

Na primeira triagem por logs, apareceram UUIDs históricos ausentes em:
- Leandro Alves: 20 UUIDs históricos distribuídos em 5 bots;
- Paulo Mendes: tratado exclusivamente pela F1.

Esse sinal **não equivale automaticamente a perda lógica**, porque UUIDs podem ter sido recriados por versões antigas de persistência. A auditoria deve provar ausência por `local_id`/estrutura/config e não apenas por UUID.

## Regra de backup

Para qualquer workspace classificado como afetado ou possivelmente afetado:

1. criar snapshot completo antes de qualquer reparo;
2. preservar bot, blocos, `local_id`, config, posição, ligações, settings, gatilhos, escopo e estado ativo;
3. registrar contagens, timestamps e hash/identificador do snapshot;
4. nunca restaurar em massa todos os workspaces por suposição;
5. não tocar Paulo Mendes.

## Método de auditoria

Varrer todos os workspaces e classificar:

### A — perda comprovada
Há evidência lógica suficiente de que um bloco/ligação/config existia e desapareceu ou foi truncado indevidamente.

### B — suspeita / UUID churn
Há UUID histórico ausente, mas o mesmo bloco lógico pode ter sido recriado com outro UUID/local_id/config equivalente.

### C — sem evidência de perda
Estrutura atual e evidências disponíveis não mostram perda recuperável.

Para cada bot suspeito:
- comparar `local_id`;
- comparar grafo lógico;
- verificar referências quebradas em `next_block_id` e branches internas;
- verificar logs/runs;
- procurar snapshots/cópias homólogas;
- verificar timestamps de saves;
- diferenciar edição intencional de truncamento sistêmico sempre que possível.

## Recuperação

- backup obrigatório antes de escrever;
- restaurar apenas classe A;
- classe B permanece documentada sem escrita destrutiva;
- não ativar/desativar bots;
- não disparar runs/mensagens;
- não alterar leads/CRM;
- escrever com controle de concorrência: se o bot mudou depois do snapshot, recalcular diff antes de aplicar.

## Critérios de verde

- todos os workspaces foram triados;
- contas afetadas possuem snapshot pré-reparo;
- todas as perdas classe A recuperáveis foram tratadas;
- nenhuma classe B foi restaurada por adivinhação;
- integridade de referências validada;
- nenhuma execução de SalesBot foi disparada;
- relatório final lista workspaces A/B/C e ações realizadas;
- smoke de leitura confirma estrutura esperada pós-reparo.

## Fora de escopo

- Paulo Mendes;
- alterar a arquitetura do Builder/salvamento;
- Inbox/WhatsApp;
- Cora;
- chat/agente Lovable.

## Acessos obrigatórios

- GitHub;
- Supabase operacional `wqriaxzymngkntccljjp`;
- Lovable somente leitura/status/ponte SQL quando necessário;
- nunca usar chat/agente Lovable.

## Semáforo

- Inventário global: 🔴
- Classificação A/B/C: 🔴
- Snapshots afetados: 🔴
- Recuperações comprovadas: 🔴
- Validação global: 🔴
- Estado global: 🔴
