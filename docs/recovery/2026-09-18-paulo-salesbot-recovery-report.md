# Paulo Mendes — relatório de recuperação dos SalesBots — 2026-09-18

## Resultado

A recuperação foi executada no workspace Paulo Mendes com snapshot integral antes e depois das alterações.

| Estado | Bots | Blocos |
|---|---:|---:|
| Antes da recuperação | 40 | 2.879 |
| Depois da recuperação | 40 | 2.907 |

Nenhum SalesBot foi executado como parte da recuperação e nenhuma mensagem foi enviada.

## Restaurados

| Bot | Antes | Depois | Integridade final |
|---|---:|---:|---|
| Reativação · Ativação 02 | 120 | 121 | 121/121 alcançáveis, 0 refs quebradas |
| Reativação · Ativação 03 | 110 | 121 | 121/121 alcançáveis, 0 refs quebradas |
| Reativação · Ativação 04 | 109 | 121 | 121/121 alcançáveis, 0 refs quebradas |
| Comercial · Pré-atendimento Qualificatório | 29 | 33 | 33/33 alcançáveis, 0 refs quebradas |

O Pré-atendimento tinha 5 blocos de reparo emergencial feitos no dia 18. O estado atual desses blocos foi preservado no snapshot e eles só foram removidos depois de 9 nós históricos do fluxo de 17/09 terem sido reconstruídos. Resultado líquido: +4.

## Evidência do Pré-atendimento

A execução íntegra de 17/09 comprovou esta sequência:

1. apresentação de Paulo + pergunta de nome/idade;
2. resposta do lead;
3. gravação no campo **Nome Idade**;
4. pergunta de renda;
5. gravação em **Renda Familiar**;
6. pergunta de profissão;
7. gravação em **Profissão**;
8. pergunta “Você já sabe como funciona? 1 Sim / 2 Não”;
9. validação 1/2;
10. resposta “2” envia áudio;
11. depois segue para o fork de expediente;
12. caminho final encaminha para atendimento humano.

O arquivo de áudio ainda existe no bucket privado `salesbot-media` e foi religado por referência; o recovery não duplicou o binário.

## Inferência controlada

A única rota sem execução histórica observada foi o timeout de 30 minutos depois da pergunta 1/2. O bloco original estava ausente.

Ela foi religada à cadeia já existente de Pré-Follow porque o próprio bot documenta abandono → Pré-Follow e as pausas anteriores usam o mesmo contrato. Essa decisão permanece explicitamente marcada como inferência, não como cópia exata do bloco apagado.

## Ativações 02/03/04

Os bots 01 e 05–10 forneceram o padrão estrutural íntegro. O 04 possuía adicionalmente uma cópia específica `· REPARO` com os parâmetros do ciclo 04.

A restauração:
- preservou UUIDs sobreviventes quando havia correspondência lógica;
- criou UUID apenas para nó realmente ausente;
- preservou ciclo/stage/destino próprios;
- não alterou estado ativo, gatilhos ou leads;
- foi feita em transação.

## Auditoria global após recuperação

Todos os 40 bots foram percorridos como grafo a partir do start, incluindo `next_block_id` e referências aninhadas em JSON.

Resultado:
- 40/40 com um único start;
- 40/40 com zero referência quebrada;
- 40/40 com zero bloco inalcançável;
- Leads Frios Cronômetro: 537/537;
- Leads Frios Disparo: 359/359;
- todas as Ativações 01–10: 121/121.

## Reversibilidade

Dois baselines privados existem em `app_private.salesbot_recovery_snapshots`:
- pré-recuperação: 40 bots / 2.879 blocos;
- pós-recuperação: 40 bots / 2.907 blocos.

Também existe snapshot versionado no GitHub do Pré-atendimento anterior à restauração:
`docs/recovery/2026-09-18-paulo-pre-atendimento-snapshot-current.json`.

## Ferramentas

- GitHub: fonte de verdade;
- banco Supabase operacional acessado pela ponte SQL da Lovable devido à negativa de permissão no conector Supabase direto;
- chat/agente Lovable não utilizado.
