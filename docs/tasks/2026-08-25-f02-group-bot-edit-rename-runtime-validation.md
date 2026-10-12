# F02 · SalesBot de grupo · editar, renomear e validar runtime

Data: 2026-08-25

## Sintoma

Na Central de Grupos, a listagem de SalesBots de grupo expõe apenas duplicar e excluir. O fluxo normal de SalesBots já possui edição e renomeação, mas a Central de Grupos não está ligada a esse fluxo.

## Escopo

- adicionar ação **Editar** aos SalesBots de grupo;
- adicionar ação **Renomear** aos SalesBots de grupo;
- reaproveitar o SalesbotBuilder existente por `local_id`;
- preservar criar, duplicar, excluir e status atual;
- não criar migration;
- não usar Lovable chat;
- não incorporar o PR F02 antigo inteiro;
- validar executor de grupo com mensagem, pausa e continuação;
- resolver workspace, sessão e o grupo `Rico.txt` por dados reais antes de qualquer disparo.

## Critérios de aceite

1. Editar aparece na listagem de SalesBots de grupo e abre o bot correto no builder existente.
2. Renomear aparece na listagem e persiste o novo nome no workspace atual.
3. Duplicar e excluir continuam operando.
4. Nenhuma alteração de schema é necessária.
5. O runtime de grupo executa mensagem, pausa e continuação sem misturar com fluxo 1-a-1.
6. O grupo `Rico.txt` é localizado por workspace/sessão/JID reais, sem suposição.
7. Um disparo real de teste é realizado e conferido por evidência de runtime/log.
8. A integração em `main` só ocorre após validação direta do patch e do caminho de execução.
