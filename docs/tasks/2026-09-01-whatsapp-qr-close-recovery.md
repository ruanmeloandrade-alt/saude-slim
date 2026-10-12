# Correção — QR da Evolution volta para preparação ao fechar sem escanear

## Objetivo
Corrigir o fluxo em que uma sessão com QR gerado, ainda não pareada, recebe `state = close` e é persistida como `falha_pareamento`, deixando o WhatsApp indisponível para nova tentativa.

## Escopo
- Não considerar `close` durante um pareamento nunca concluído como falha definitiva.
- Manter a sessão reutilizável para gerar um novo QR.
- Recuperar sessões antigas que já estejam presas em `falha_pareamento` sem telefone e sem conexão anterior.
- Preservar a regra atual de quantidade de números de WhatsApp e de WhatsApp Extra.
- Não alterar isolamento por `workspace_id`.

## Validação
- Fechar/expirar um QR sem escanear não pode deixar a sessão bloqueada.
- A reabertura deve permitir novo QR.
- Sessões já conectadas/desconectadas devem manter o comportamento atual.
- Limites de WhatsApp devem permanecer inalterados.
