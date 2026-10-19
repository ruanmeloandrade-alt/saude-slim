# Recuperação do inbound real do proprietário

Continuação autorizada do pedido de localizar o "oi" e fazê-lo aparecer no primeiro funil/etapa. Repositório `ruanmeloandrade-alt/saude-slim`, branch `ops/slim-recover-owner-inbound-20261019`, base de produção `restauracao/sistema-completo-20261014`. A correção geral de backfill já foi integrada no PR #7.

O script operacional consulta apenas os telefones informados pelo proprietário na sessão confirmada. Telefones completos ficam somente na variável temporária do serviço; não são incluídos no Git ou nos logs. Credencial da sessão é descriptografada pelo RPC existente dentro do servidor. A recuperação exige habilitação explícita, janela de até 48 horas e identificador de solicitação.

Para cada telefone realmente retornado pela Evolution, selecionar o primeiro inbound da janela. Reprocessar o item original pelo webhook existente, sem fabricar texto, remetente ou data, somente se ainda não houver card daquela origem. Confirmar card/funil/etapa no banco. Preservar cards existentes e não reexecutar operação concluída após reinício. Persistir apenas resumo sem corpo/telefone completo em metadata da sessão, com comparação de versão. Não ativar outros bots nem importar o histórico de outras pessoas.

Validação isolada: replay conserva item original e direção inbound; outbound, outra origem e histórico fora da janela são rejeitados; card existente e solicitação concluída impedem replay. Cobertura de sessão/empresa, dedupe, credenciais, gravação de resumo e configuração desabilitada preservada. Syntax/lint/teste operacional aprovados. Sem dependências ou migration.

Publicação: executar com inicialização temporária da próxima versão, mantendo o deployment saudável anterior ativo. Restaurar `npm start`, pre-deploy vazio e limpar variáveis operacionais após confirmar o resultado. Status: preparado; resultado real ainda pendente.
