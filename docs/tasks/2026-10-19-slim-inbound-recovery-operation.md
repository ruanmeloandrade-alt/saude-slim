# Recuperação do inbound real do proprietário

Continuação autorizada do pedido de localizar o "oi" e fazê-lo aparecer no primeiro funil/etapa. Repositório `ruanmeloandrade-alt/saude-slim`, branch `ops/slim-recover-owner-inbound-20261019`, base de produção `restauracao/sistema-completo-20261014`. A correção geral de backfill já foi integrada no PR #7.

O script operacional consulta apenas os telefones informados pelo proprietário na sessão confirmada. Telefones completos ficam somente na variável temporária do serviço; não são incluídos no Git ou nos logs. Credencial da sessão é descriptografada pelo RPC existente dentro do servidor. A recuperação exige habilitação explícita, janela de até 48 horas e identificador de solicitação.

Para cada telefone realmente retornado pela Evolution, selecionar o primeiro inbound da janela. Reprocessar o item original pelo webhook existente, sem fabricar texto, remetente ou data, somente se ainda não houver card daquela origem. Confirmar card/funil/etapa no banco. Preservar cards existentes e não reexecutar operação concluída após reinício. Persistir apenas resumo sem corpo/telefone completo em metadata da sessão, com comparação de versão. Não ativar outros bots nem importar o histórico de outras pessoas.

Se o histórico por telefone estiver vazio, consultar `chat/whatsappNumbers` da mesma instância. Somente uma correspondência `exists=true` para o telefone exato pode fornecer o LID; buscar esse LID e acrescentar JID alternativo comprovado, mantendo ID, corpo, data e JID original. Nome ou dígitos do LID nunca servem como telefone. Contrato conferido nas fontes oficiais `evolution-foundation/evolution-api`: `src/api/routes/chat.router.ts`, `src/api/dto/chat.dto.ts` e `whatsapp.baileys.service.ts`.

Validação isolada: replay conserva item original e direção inbound; outbound, outra origem e histórico fora da janela são rejeitados; card existente e solicitação concluída impedem replay. Cobertura de sessão/empresa, dedupe, credenciais, gravação de resumo e configuração desabilitada preservada. Syntax/lint/teste operacional aprovados. Sem dependências ou migration.

Publicação: executar com inicialização temporária da próxima versão, mantendo o deployment saudável anterior ativo. Restaurar `npm start`, pre-deploy vazio e limpar variáveis operacionais após confirmar o resultado. Status: preparado; resultado real ainda pendente.


## Resultado em produção — 19/10/2026
Correção geral integrada pelo PR #7, merge 0218a688ce80e76bbf9e0580aef153d59bebce22, Railway fcedf06c-c289-4733-a389-141c8faf0b8f SUCCESS. Operação do PR #8 integrada no merge 9d53152580f8212d11ee2e623817986500aed9d9, Railway 8cdf6693-206d-494f-b7ee-b69a4d8692db SUCCESS. Builds completos do servidor passaram, incluindo os 11 checks de entrada. HTTP de Home, Tutoriais, Inbox e Funil: 200 após a publicação.

Pesquisa real pelos dois números, formas com/sem nono dígito, banco e logs; inspeção direta da sessão às 17:39:17 e às 17:47:26 de Brasília. Resultado final persistido: zero mensagens e nenhum LID comprovado nos quatro alvos consultados; recuperação vazia. Nenhum inbound foi reprocessado e nenhum card/mensagem fictício foi criado. O atendimento específico Baroni NÃO foi recuperado, pois o histórico retornado não o disponibilizou. A falta desse dado não foi usada para segurar a correção geral.

Bot da primeira etapa: Rastreamento | Origem do contato, inativo; configuração preservada. LIDs sem telefone/JID alternativo comprovado permanecem sem associação automática. Não afirmar cobertura de entrega para contatos ainda sem identificação nem resposta real de bot pausado. Não houve teste autenticado novo no navegador, indisponível nesta fase; os smokes HTTP e as consultas operacionais são a evidência pós-publicação disponível.

Comando configurado restaurado para npm start, pre-deploy vazio, nenhum staged change. Seis valores operacionais temporários esvaziados sem gerar outro deploy; resumo sem corpo/telefone completo mantido na metadata para auditoria. O processo de inspeção da réplica atual já terminou e o servidor está atendendo; nonce e janela protegem a operação contra replay após reinício.
