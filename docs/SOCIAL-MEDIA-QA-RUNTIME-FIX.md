# Social Media — QA runtime image fix

## Início — 2026-08-11

QA real do usuário confirmou:
- OpenAI: Re-testar = conexão validada.
- Ideogram: Re-testar = conexão validada.
- Falha de geração de imagem ocorria em Banco de Ideias, Campanha > Post, Novo Post e Chat Mídia.
- Aba Marca apresentava erro genérico `Try again`.

## Regra de progresso
Este é um bugfix de QA sobre o escopo histórico de 15 tasks. Não reduz o percentual já concluído nem reabre tasks antigas por cautela.

## Objetivo desta correção
1. Comparar o pipeline atual da MarketOn com a documentação oficial do Ideogram V3.
2. Corrigir a camada compartilhada de geração/persistência para que uma geração resulte em uma única persistência durável.
3. Preservar o metering/limites de storage já presentes na `main`.
4. Verificar o consumo real do contexto da aba Marca pelo Banco de Ideias e pela Campanha orgânica.
5. Corrigir o erro da aba Marca sem mascarar falha de storage.
6. Adicionar regressão técnica específica do pipeline de imagem; build/lint isolados não bastam.
7. Integrar à `main` somente depois de validar tecnicamente o head de código.

## Diagnóstico confirmado
- `generate-image.ts` usa o contrato atual do Ideogram V3: endpoint V3, `Api-Key`, `multipart/form-data` e download de `data[].url` antes de devolver base64 ao cliente.
- O defeito compartilhado estava em `social-stream.ts`: o frame final era persistido antes de ser entregue ao consumidor.
- Banco de Ideias e Campanha já eram donos da persistência de suas imagens; a persistência antecipada no stream duplicava trabalho e criava um ponto de falha depois de o provider já ter consumido o crédito.
- O código de storage também dependia de `workspace_storage_files` / `workspace_storage_addons`; foi adicionada migration idempotente para versionar o contrato esperado pelo metering.
- A Marca podia falhar por completo ao tentar assinar um logo legado/quebrado; agora essa falha não derruba todo o contexto.

## Correções entregues
- `streamImage()` voltou a ser transporte puro: recebe o resultado do provider e entrega o frame final sem upload escondido.
- Banco de Ideias e Campanha persistem a imagem uma única vez em seus próprios fluxos.
- Novo Post e Chat Mídia podem receber/renderizar o resultado antes de qualquer persistência obrigatória.
- Migration de metering de storage adicionada de forma idempotente.
- Carregamento de Marca endurecido contra logo legado com signed URL inválida.
- `src/lib/social-image-pipeline.test.ts` criado com 6 regressões específicas do pipeline.

## Marca — consumo real
- Banco de Ideias consulta `social_brand_context` e usa contexto da Marca na geração de ideias.
- Campanha/Post também consulta `social_brand_context` e injeta um bloco de referência da Marca no refinamento/geração.
- Limite conhecido: os dois fluxos ainda não injetam de forma uniforme todos os campos disponíveis da Marca. Portanto esta correção prova consumo real, mas não declara paridade total de todos os campos.

## Validação técnica final
Head de código validado: `cfdc8de026ff7152fc054bcd56d1df21031d8c01`.

GitHub Actions no mesmo head:
- Social Media CI `31499452340`: success.
- Integrations 47 CI `31499452157`: success.
- Paid Media Integrations CI `31499452548`: success.
- Google Workspace 47 CI `31499452150`: success.
- Microsoft Graph Files 47 CI `31499452171`: success.

No Social Media CI passaram:
- Social publishing tests.
- Social campaign rules tests.
- Social post channel rules tests.
- Social image pipeline regression: 6/6.
- Home regression tests.
- Lints de Social Media/Home.
- Production build.

O commit documental seguinte (`21037be2d9ac4c27b6752f14d4b2d3dcecb122cc`) alterou apenas este Markdown. Os workflows disparados para esse commit permaneceram em fila no momento do fechamento e não representam falha de código executada.

## Merge
- PR #89: `Corrige pipeline compartilhado de imagem no Social Media`.
- Merge realizado em `main`.
- Merge commit: `79b45d2501758ec36a7b0f8456b7e0d5ebd44cb8`.

## Estado
Correção técnica concluída, validada e integrada à `main`. Próxima etapa é QA funcional ponta a ponta no ambiente publicado: Banco de Ideias, Campanha > Post, Novo Post, Chat Mídia e aba Marca. O CI não substitui essa validação real do usuário.
