# Primeira mensagem no funil e recuperação do recebimento

Alvo confirmado: `ruanmeloandrade-alt/saude-slim`, branch `fix/slim-first-inbound-funnel-20261019`, produção `restauracao/sistema-completo-20261014`, Supabase exclusivo `vyzvfcgpjjzvcjegzzza`. Referências herdadas ao MKTOn não mudam o produto solicitado.

## Pedido e aceite

Primeiro inbound gera card em Vendas/Novo lead e dispara a automação configurada. Preservar sessão de origem e estados dos atendimentos existentes. Rastrear e recuperar a mensagem real do proprietário, sem exigir outro envio ou criar mensagem fictícia.

## Diagnóstico verificado

Os dois telefones fornecidos não estão no recebimento persistido. A entrada em tempo real cria cards e enfileira a automação; o bot apontado na primeira etapa está inativo. Há mensagens LID sem número alternativo, preservadas sem associação. Não inferir telefone de LID ou por nome.

## Execução

Inspeção limitada do histórico da sessão real na Evolution, usando credenciais somente dentro do ambiente existente do servidor. Nenhum segredo ou telefone pessoal deve entrar no Git ou nos logs. Os alvos ficam em variável operacional temporária. Usar pre-deploy temporário na imagem atual, mantendo o deployment saudável atendendo, e restaurar configuração ao terminar. A inspeção não envia mensagens, altera credenciais nem cria leads. Recuperação posterior somente com mensagens reais identificadas, passando pelo webhook existente e verificando card/etapa/sessão.

Fora do escopo: reativação em massa dos bots, importação de outras empresas, criação de sessões, DNS, Evolution/restart do serviço de integração, alteração de dependências.

## Correção incremental
Identificado caminho de backfill que criava contato sem pipeline/etapa nem evento de criação. Novos contatos recuperados agora resolvem o primeiro funil/etapa do CRM principal, mantêm sessão e marcam evento pendente. O handler autenticado emite esse evento depois de salvar o histórico real, confirma com comparação de versão e mantém retry em falha. A fila recebe identificador estável de criação, compartilhado com o webhook, para evitar jobs duplicados. Cards existentes mantêm suas etapas e campos. Sem migration, dependência nova ou mock em produção.

Validação: 11 cenários de entrada/recuperação e 8 regressões de origem aprovados; inclui dispatcher real e ordenação do handler gerado. Build completo `npm run build` aprovado, com regressões herdadas e cliente/SSR/Nitro. ESLint dos arquivos novos e do dispatcher aprovado; TypeScript focado em identidade/entrada aprovado. Inspeção operacional validada com transporte isolado: empresa/sessão exatas, alvo exato, LID alternativo explícito, apenas inbound, dedupe e orçamento de chamadas. Nenhuma dependência adicionada, nenhum dado real alterado pelos testes. Produção permanece ativa.

Status: diagnóstico do caso real e validação de build em andamento.

Nota operacional: o conector não entregou saída da inspeção no pre-deploy do redeploy da imagem anterior. Não declarar execução sem resultado. Para tornar o diagnóstico verificável, executar antes do start da próxima versão validada e gravar somente o resumo (IDs, horário, indicador de saudação, últimos quatro dígitos) no metadata da sessão exata. Gravação com comparação de updated_at preserva configurações concorrentes; sem mensagens, telefones completos ou credenciais no relatório persistido. Restaurar comandos e limpar variáveis temporárias ao finalizar.


## Resultado em produção — 19/10/2026
Correção geral integrada pelo PR #7, merge 0218a688ce80e76bbf9e0580aef153d59bebce22, Railway fcedf06c-c289-4733-a389-141c8faf0b8f SUCCESS. Operação do PR #8 integrada no merge 9d53152580f8212d11ee2e623817986500aed9d9, Railway 8cdf6693-206d-494f-b7ee-b69a4d8692db SUCCESS. Builds completos do servidor passaram, incluindo os 11 checks de entrada. HTTP de Home, Tutoriais, Inbox e Funil: 200 após a publicação.

Pesquisa real pelos dois números, formas com/sem nono dígito, banco e logs; inspeção direta da sessão às 17:39:17 e às 17:47:26 de Brasília. Resultado final persistido: zero mensagens e nenhum LID comprovado nos quatro alvos consultados; recuperação vazia. Nenhum inbound foi reprocessado e nenhum card/mensagem fictício foi criado. O atendimento específico Baroni NÃO foi recuperado, pois o histórico retornado não o disponibilizou. A falta desse dado não foi usada para segurar a correção geral.

Bot da primeira etapa: Rastreamento | Origem do contato, inativo; configuração preservada. LIDs sem telefone/JID alternativo comprovado permanecem sem associação automática. Não afirmar cobertura de entrega para contatos ainda sem identificação nem resposta real de bot pausado. Não houve teste autenticado novo no navegador, indisponível nesta fase; os smokes HTTP e as consultas operacionais são a evidência pós-publicação disponível.

Comando configurado restaurado para npm start, pre-deploy vazio, nenhum staged change. Seis valores operacionais temporários esvaziados sem gerar outro deploy; resumo sem corpo/telefone completo mantido na metadata para auditoria. O processo de inspeção da réplica atual já terminou e o servidor está atendendo; nonce e janela protegem a operação contra replay após reinício.
