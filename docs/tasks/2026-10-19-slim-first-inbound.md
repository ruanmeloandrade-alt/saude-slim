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
