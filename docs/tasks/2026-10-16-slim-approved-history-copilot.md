# Saúde Slim: execução autorizada em 16/10/2026

Estado: EM EXECUÇÃO. O usuário autorizou com “bora” o escopo de Inbox, Copiloto, Funil, checkout e IA por prompt. Não aguarda novo OK geral nem testes do usuário.

Projeto exclusivo: ruanmeloandrade-alt/saude-slim; branch operacional restauracao/sistema-completo-20261014; banco vyzvfcgpjjzvcjegzzza. Branch desta entrega fix/slim-approved-history-copilot-20261016. Nenhuma alteração em outros projetos, DNS, credenciais, GitHub Actions, Lovable ou Vercel.

## Novos requisitos do Histórico de Vendas

Lista única, retirar o bloco Vendas anteriores: conferência e regularização sem apagar dados, botão Pesquisar para aplicar filtros, Editar e Excluir por pedido. Edição deve ter revisão explícita, atualizar estoque e totais atomicamente, preservar documentação original e auditoria. Exclusão não pode apagar mensagens/documentos nem perder rastreabilidade: retirar da lista operacional após estorno único, mantendo registro auditável. Não criar botões falsos nem tratar alteração só visual como transação.

## Diagnóstico confirmado

O componente real do histórico usa artigos expandidos e aplica filtros a cada tecla; não tem botão Pesquisar. A regularização é inserida por transform de build. O layout raiz remove o SupportRobot justamente nas rotas migradas (histórico, pedidos, estoque, produtos e clientes). SupportRobot também fecha o chat e limpa a instância a cada navegação. O pedido novo já possui RPC transacional própria, mas isso não comprova que todos os caminhos de criação usam essa RPC; auditar esses consumidores.

## Escopo e ordem

Implementar e validar primeiro Histórico de Vendas e presença global do Copiloto. Continuar as frentes aprovadas em docs/tasks/2026-10-16-slim-next-inbox-copilot-scope.md: identidade/conversa sem duplicação; mídia/áudio/transcrição e compositor contínuo; etiquetas/grupos/indicadores e retirada do botão de formulário; drawer do Funil com mini-Inbox; ações de Copiloto aprovadas; entrega/endereço/frete; IA por prompt sem objetivos. Nenhuma dessas frentes deve ser marcada concluída só por este documento.

## Critérios e validação

Filtros só mudam resultados ao pesquisar/Enter; limpar volta ao conjunto total; erros não viram zero. Listagem com ações por linha e detalhes. Copiloto único em páginas internas, excluído de páginas públicas/auth, preservando contexto na navegação e isolando empresa/operador. Ações nunca autoexecutadas a partir de resposta de IA.

Preservar centavos, pedido/baixa/estorno únicos, arquivo imutável, envio opcional aprovado e bots com salvamento manual/autosave 120 segundos. Testes financeiros em PostgreSQL descartável, sem gravação de testes na produção. Não enviar clientes a grupos, mensagens, mídias ou cobranças de teste. Registrar build, deploy, testes e limites reais; build/healthcheck não são E2E autenticado.

## Rollback

Reverter somente os arquivos desta entrega por novo commit, sem force push. Migrations aditivas e auditáveis; não apagar dados empresariais. Testar transformações existentes e idempotência antes da publicação.
