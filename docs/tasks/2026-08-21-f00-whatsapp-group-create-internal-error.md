# F00 — WhatsApp group creation: Internal Server Error

**Data:** 2026-08-21  
**Status:** 🟢 CORREÇÃO IMPLEMENTADA — PUBLICAÇÃO PENDENTE

## Sintoma

Ao usar **Central de Grupos → Criar grupo**, a interface retorna `Internal Server Error` e o grupo não aparece no cache local `whatsapp_groups`.

## Evidências do runtime

- A sessão selecionada existe em `whatsapp_web_sessions`, está marcada como `conectado`, possui telefone e credencial Evolution cifrada.
- O front envia o UUID real da sessão em `sessionId`.
- `get_evolution_credentials` recebe `_session_id` + `_key`; o código atual já usa esse contrato corretamente.
- Não foi encontrado novo registro de grupo após a tentativa que falhou, então a falha ocorre antes da persistência local ou durante a chamada ao provider.
- O erro histórico reportado imediatamente antes do 500 genérico foi `Connection Closed`.

## Causa tratada

Antes de chamar o endpoint real de criação, o fluxo executava um preflight em `/instance/connectionState/:instance` e exigia que a resposta fosse exatamente `state = open`.

Esse preflight era frágil por quatro motivos:

1. uma indisponibilidade transitória do endpoint de diagnóstico bloqueava uma operação que poderia funcionar;
2. respostas não JSON ou variantes de schema podiam virar estado `desconhecido`;
3. versões distintas da Evolution podem usar outro campo/valor para o estado;
4. falhas de rede e respostas do provider podiam chegar ao TanStack como HTTP 500 genérico.

Além disso, `Connection Closed` indica uma instância Baileys presa em estado fechado. A própria integração MktOn já possui precedente de usar `/instance/restart/:instance` para recuperar esse estado durante o fluxo de conexão/QR.

## Correção implementada

- `connectionState` virou preflight resiliente: falha HTTP, payload desconhecido ou falha de rede não bloqueiam `/group/create`.
- Estado explicitamente fechado/desconectado dispara uma tentativa de recuperação via `/instance/restart/:instance` usando a chave global Evolution, seguindo o padrão já existente no runtime.
- Se `/group/create` responder `Connection Closed`, é feito **um único restart + retry controlado**.
- Não há retry após falha de rede ambígua, evitando risco de grupo duplicado.
- Erro de rede da chamada real de criação é convertido em mensagem operacional explícita.
- Mensagens da Evolution são preservadas inclusive quando `message` vier como array ou a resposta não for JSON.
- Se a Evolution criar o grupo e somente o cache `whatsapp_groups` falhar, a criação não é reportada falsamente como fracasso; o cache pode ser recuperado pela sincronização.
- Nenhum outro fluxo da plataforma foi alterado.

## Validação

- Cobertura de contrato adicionada para normalização de participantes, estados de recuperação, detecção de `Connection Closed` e preservação das mensagens da Evolution.
- Diff revisado e restrito ao fluxo de criação de grupo, teste focado e este task doc.
- O container de validação não conseguiu resolver `github.com`, portanto não foi possível executar o checkout/build local neste ambiente; não foi aguardado GitHub Actions.
- A publicação autorizada pelo owner será usada como validação de build do artefato sincronizado após o merge.
