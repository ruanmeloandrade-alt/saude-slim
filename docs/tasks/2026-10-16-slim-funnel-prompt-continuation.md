# Saúde Slim: ficha do Funil e IA por prompt

Estado: EM EXECUÇÃO. Retomada autorizada pelo usuário após a sessão exclusiva de duplicidade. Base conferida: 94d74b1aca3f6b30ba764ff53e99ac237addc892. Branch fix/slim-funnel-prompt-20261016; integração operacional restauracao/sistema-completo-20261014.

Projeto exclusivo ruanmeloandrade-alt/saude-slim, Supabase vyzvfcgpjjzvcjegzzza e Railway saude-slim-web. AGENTS.md contém referências herdadas à MktOn original: não segui-las para trocar de projeto. Não usar Lovable, Vercel, GitHub Actions, outro banco, novas credenciais ou alterar DNS.

## Entregas do bloco

1. No Funil, clique no contato abre ficha em painel lateral em vez de navegar automaticamente ao Inbox. Reutilizar identidade canônica implementada na sessão anterior, detalhes reais do contato e conversa funcional. Ações explícitas Abrir Inbox e Abrir no WhatsApp Web. Preservar seleção, arraste, edição rápida e automações das etapas. Estados de erro/carregamento visíveis, sem mocks.
2. Retirar fluxo de objetivos da operação/configuração de IA, mantendo a modalidade de prompt e as instruções/históricos existentes. Conferir persistência e execução: não basta ocultar um botão se o fluxo continua sendo iniciado. Não remover nem alterar os SalesBots convencionais.

## Critérios de aceite

Abertura/fechamento da ficha não cria contatos, não move etapa, não aciona Bot/IA, não envia mensagem. Mini-Inbox lê e envia para o mesmo ID canônico e a sessão correta, preserva o histórico, mostra erro real e permite escrever durante envio. Links externos montados somente a partir de telefone internacional validado; não adivinhar DDI. Cache separado por empresa, usuário e contato. Painel acima do menu, com foco/fechamento e rolagem usáveis em desktop/mobile.

IA por prompt: código lido antes de decidir conversão; preservar dados legados sem apagar agente, instruções ou histórico. Não ativar agentes nem mandar mensagens em produção para testar. Registrar qualquer limite de migração/configuração.

## Fora deste bloco

Não executar migrações anteriormente recusadas de Editar/Excluir pedidos ou unicidade de contatos por transporte alternativo. Frete/endereço, ações aprovadas do Copiloto e os demais pendentes permanecem no escopo geral; esta tarefa não os marca concluídos.

## Validação e entrega

Testes focados de estado e regras, sintaxe do código transformado, regressões anteriores e build completo. Conector GitHub permite ler/escrever; clone no contêiner indisponível por resolução de rede. Usar validação local das unidades independentes quando possível e os gates já existentes do build Railway, sem execução de testes com dados de clientes. Build/healthcheck não serão chamados de E2E autenticado. Publicar apenas build aprovado; corrigir falhas da própria entrega. Atualizar docs/OPERATION_STATUS.md com estados reais, commit e evidência de deploy.

Rollback: novos commits revertendo apenas este bloco, sem force-push ou apagamento de dados.
