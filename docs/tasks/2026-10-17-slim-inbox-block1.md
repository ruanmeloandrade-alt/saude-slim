# Saúde Slim | Bloco 1: Inbox, grupos e mídia

## Solicitação de 17/10/2026

Executar uma etapa por vez e pausar ao concluir para conferência do usuário. Este bloco cobre exclusivamente o Inbox. O usuário informou teste real bem-sucedido em 16/10/2026 de SalesBot passando o atendimento para IA individual; localizar evidência operacional e atualizar o registro sem reenviar mensagens. Atendimento autônomo de IA nos grupos foi retirado do escopo pelo usuário; manter SalesBots e gatilhos de grupos.

## Contexto e limites

Repositório ruanmeloandrade-alt/saude-slim, produção restauracao/sistema-completo-20261014, base 71aeb83b9bd8afc69a08ccf4e9d9c5e0c9017788. Supabase exclusivo vyzvfcgpjjzvcjegzzza. Branch de trabalho fix/slim-inbox-block1-20261017. As referências a outros projetos e ciclos antigos no AGENTS.md herdado não substituem este escopo autorizado pelo usuário.

Não enviar mensagens reais, iniciar bots, mover leads, alterar pedidos, mesclar contatos ou recriar grupos durante QA. Não implementar IA de grupos, mini-Inbox do Funil, Copiloto, ERP ou demais blocos. Preservar dados e migrações existentes. Não usar Lovable, Vercel nem GitHub Actions. Publicação automática apenas após validação técnica; depois pausar para conferência.

## Diagnóstico inicial

1. Controles de SalesBot do Inbox não reconhecem a chave composta sessão|JID dos grupos recuperados sem metadados. O resolver os classifica como lead, impedindo carregamento das automações e mostrando controles individuais indevidos.
2. Histórico dos grupos ainda não oferece recuperação autenticada sob clique para mídia sem URL ou com URL Storage expirada.
3. Webhook de recebimento continua realizando download antecipado sem prazo e armazenando base64 em JSONB, apesar da recuperação segura já publicada no caminho individual.

## Implementação prevista

Resolver grupos históricos no workspace e sessão corretos, preservar SalesBots/gatilhos e remover entrada operacional de IA para grupos. Disponibilizar áudio/PDF/imagem de grupos sob clique por mensagem autorizada, com limite de tamanho/prazo e Storage privado. Retirar recuperação antecipada do recebimento, preservando as chaves/metadados necessários para a abertura posterior. Não descarregar mensagens nem regravar o histórico em lote.

## Critérios de aceite

- Grupo histórico mantém sessão/JID, não é tratado como lead e permite carregar seus controles SalesBot.
- Anexos individuais e de grupos têm abertura explícita, com verificação de workspace/conversa/mensagem e tratamento de indisponibilidade.
- Novas entradas não dependem de download antecipado da Evolution nem acrescentam mídia base64 ao histórico.
- Testes direcionados e build real aprovados; verificar versão publicada e saúde após a publicação.
- Evidência do teste informado separada de testes ainda não executados; não declarar navegação autenticada ou envio real realizados sem prova.
- Pausar após este bloco para o usuário conferir antes da etapa seguinte.

## Execução

Implementação concluída, com build final integrado e regressões locais aprovados, incluindo o ajuste dos gatilhos por sessão. Publicação e healthcheck são acompanhados na entrega. Ambiente com quatro serviços online no início. Navegador disponível abriu /auth sem sessão; a conferência visual autenticada permanece para o usuário na pausa solicitada. Todas as consultas ao Supabase foram somente leitura.

### O que mudou

- Resolver de grupo confirma workspace, sessão Evolution e JID, inclusive quando não há cadastro em whatsapp_groups. Erros são mostrados no Inbox, sem montar controles individuais em um grupo ainda não identificado.
- Contextos técnicos, consulta de execução ativa, recebimento e regras usam a sessão de origem. O primeiro gatilho pode funcionar mesmo antes de existir um contexto técnico do grupo. Contatos individuais mantêm seu fluxo.
- Histórico de grupos consulta metadados escalares. Cache e Realtime não conservam data URLs; Realtime confere workspace, sessão e JID.
- Abrir mídia usa uma operação autenticada por mensagem. Áudio, imagem, documento, figurinha e vídeo circular podem usar mídia legada ou recuperação limitada da Evolution. Arquivo fica em Storage privado e é aberto por URL temporária, renovável.
- Recuperação exige operador e tem limite de 16 MB. A requisição à Evolution mantém 30 segundos e não repete automaticamente. Upload usa RLS do usuário; a gravação administrativa se limita ao ponteiro media_url depois de reverificar acesso e identidade da mensagem.
- Ponteiro gravado não inclui token assinado. Atualização concorrente não sobrescreve ponteiro já recuperado; raw histórico não é regravado. Caminho por mensagem e hash evita duplicar o mesmo arquivo em tentativas concorrentes.
- Webhook não faz mais a busca antecipada sem prazo. Novos snapshots excluem base64/miniaturas binárias, mantendo a chave do provedor e metadados para abertura posterior.
- Central de Grupos não monta a aba nem consulta/opções de IA. SalesBots e gatilhos continuam disponíveis, sem excluir cadastro antigo.

### Evidência do teste real de 16/10

Consultas diretas no Supabase exclusivo, sem ler o texto das conversas nem executar bots:

| Registro | Evidência |
|---|---|
| SalesBot | “Emprestimos ativa IA”, execução f55e9849-f1e6-4c17-8a8e-7e0ce09177b2, status finished, sem last_error |
| Início e fim | 2026-10-16 21:56:39Z a 21:56:48Z, correspondentes a 18:56 de Brasília |
| Transferência | Log 31ce3a18-6c6d-40ae-8d76-6e70473ea201, às 21:56:49Z, status ok, agente “Consultor” assumiu e SalesBot encerrou |
| Resposta 1 da IA | Atividade a3d69a63-8009-4df5-8631-bea731f636cf, 21:57:20Z |
| Resposta 2 da IA | Atividade e3bcd69b-3dfc-40c7-b648-fc38e28a2de5, 21:58:51Z |
| Resposta 3 da IA | Atividade 25dcc0f6-8047-4bf3-b2da-4d98a8a1500e, 22:01:00Z |

As três atividades têm source=ai_agent e ID WhatsApp. Cada uma corresponde a exatamente uma linha de whatsapp_web_messages da mesma sessão e empresa, from_me=true e delivery_status=sent. Isso confirma a execução relatada pelo usuário; não afirma recibo de leitura. A tabela conversation_agent_runs não tinha registro nesse recorte, portanto essa métrica não foi usada como prova nem preenchida artificialmente.

### Verificações e limites

Testes novos: test-slim-inbox-group-target.mjs, test-slim-group-salesbots-only.mjs, test-slim-group-media.mjs e test-slim-inbox-group-media.mjs, integrados ao prebuild existente. Cobrem isolamento por sessão/empresa/mensagem, permissões, grupos históricos, links privados, mídia legada, cancelamento da entrada de IA de grupos e recebimento sem arquivos inline. Regressões anteriores de rascunho, confirmação do envio, prazos, Funil e PostgreSQL isolado permanecem.

Consulta live encontrou quatro conversas de grupos, 85 mensagens e 17 URLs inline, sem metadados de grupos cadastrados. Não foram modificadas. Índices e triggers reais de leads foram inspecionados: contexto source=whatsapp_group fica fora da unicidade de contatos source=whatsapp; não há trigger de INSERT ou de reescrita de source/phone. A compatibilidade também foi testada em PostgreSQL descartável, sem migração live.

Nenhum envio real, clique autenticado em arquivo, início de bot ou mudança de lead foi executado no QA. O usuário deve conferir o bloco publicado antes de iniciarmos o próximo. Este documento não declara as outras frentes concluídas.
