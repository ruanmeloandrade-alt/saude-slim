# Saúde Slim — preparação de entrega e limpeza dos testes — 18/10/2026

## 🟡 Escopo autorizado

O usuário forneceu explicitamente dois e-mails e senhas para criar duas contas administradoras, uma do cliente e uma dele. Solicitou remover os dados dos testes, a instância WhatsApp e bots, deixando a Saúde Slim limpa para começar a configuração do cliente.

Escopo exclusivo: projeto Supabase vyzvfcgpjjzvcjegzzza, workspace operacional c49945db-1960-461a-9339-a43b8403bdd9, repositório ruanmeloandrade-alt/saude-slim. Produção atual 5e24b2da48a21a1011c6a3894c1454c5ffa0a141. Nenhum valor de credencial, e-mail, telefone ou conteúdo de conversa será versionado.

## Dentro do escopo

- Criar exatamente duas identidades pelo Supabase Auth Admin já integrado ao aplicativo, com confirmação de e-mail no servidor, sem enviar e-mails. Conferir roles admin na mesma empresa, perfil inicial e conta ativa.
- Identificar filas, instâncias e relações do tenant antes da limpeza. Remover bots, agentes, regras, históricos e cadastros operacionais de teste e arquivos de teste associados à empresa.
- Desconectar e excluir somente as instâncias WhatsApp de teste da Saúde Slim, com leitura de verificação quando disponível. Preservar a infraestrutura Railway para uso futuro.
- Executar a limpeza relacional em escopo explícito, sem TRUNCATE global ou alteração de schema/RLS. Preservar a empresa, funcionamento dos módulos, históricos técnicos de segurança e escopos versionados.
- Não excluir a identidade proprietária enquanto ela possui a empresa (FK ON DELETE CASCADE). Não transferir ownership, excluir usuários existentes, conceder super_admin global ou tocar outros workspaces por inferência.

## Inventário inicial

26 leads, 3 SalesBots, 1 agente individual, 6 execuções de bot, 2 campanhas, 2 pedidos, 1 produto, 40 grupos, 360 mensagens WhatsApp e 5 registros de sessão WhatsApp. Filas conhecidas terminadas, sem execução ativa. Dois e-mails novos confirmados por consulta; nenhum cadastro efetuado até este escopo.

## Aceite

Duas novas identidades e memberships admin conferidos; ambas selecionam a empresa operacional. Dados e conexões de teste removidos no escopo autorizado, com contagens finais e limitações explícitas. Login real dos destinatários não será declarado sem evidência. Infraestrutura existente funcional. Nenhuma mensagem WhatsApp, convite por e-mail ou cobrança durante o trabalho.

## Execução

Inventário em andamento. Sem alteração de código de produto prevista; sem novo deployment apenas para registrar operação.

### Contas concluídas e execução externa preparada

As duas novas identidades foram criadas pelo formulário real de Equipe no aplicativo, usando o Supabase Auth Admin existente. Conferidos e-mail confirmado, senha configurada, nomes corretos, ausência de bloqueio, membership admin/admin sem prazo e current_workspace_id operacional. Credenciais usadas somente no formulário autorizado, sem valor registrado aqui. Criado setor Administração para os novos administradores. Permanecem as duas identidades anteriores; nenhuma transferência de propriedade ou exclusão de acesso foi solicitada especificamente.

Antes da limpeza, desabilitados 2 SalesBots ativos, 1 agente e 1 automação de etapa, sem disparos. Operação externa usa exclusivamente variáveis já existentes no processo do web service. Para executá-la sem extrair credenciais ou criar infraestrutura, será configurado temporariamente um preDeployCommand no serviço existente e solicitado redeploy da mesma imagem 5e24b2d. Exigir recibo de conclusão e restauração do comando vazio antes do encerramento. Nenhum código de produto ou segredo é alterado. Timeout temporário 240s, script total180s, requisições15s/2MB, sem retry/redirect. Execução restrita a execute-20261018 e expiração2026-10-19T00:00Z.

Script externo: sintaxe e3mocks aprovados com invocação CLI exata Node -e: exclusão dos5alvos+6arquivos, modo padrão sóleitura com0DELETE, objeto inesperado com0DELETE; saída sem segredos. Revisão independente aprovada. A operação SQL fica em transação com guards de admin/workspace/conjunto de sessões, ausência de filas ativas, contagens máximas e relações entre empresas, preservando estrutura inicial e trilhas técnicas. Dados não são excluídos via SQL antes da confirmação externa. Não é necessário build de produto para esta execução operacional.


### Adaptação de transporte da operação SQL

Evolution e Storage foram conferidos vazios para os alvos autorizados em 18/10/2026 às 22:24 UTC. O deployment 4bdd3c83 está SUCCESS e o preDeployCommand foi restaurado para vazio. Duas chamadas do SQL com múltiplas instruções retornaram Invalid or expired requestState; leituras posteriores confirmaram os registros operacionais intactos. Trata-se de erro técnico retornado pelo conector, sem causa confirmada. Uma instrução DO inócua passou. A operação revisada passa a uma única instrução DO atômica, preservando os 17 guards, ordem de exclusão e verificações. Inclui deadline explícito de 30 segundos nos limites das operações e lock_timeout de 5 segundos. NOTICE não substitui leitura independente das contagens após sucesso. Execução ainda pendente neste checkpoint.
