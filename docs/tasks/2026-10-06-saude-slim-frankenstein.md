# Saude Slim - Frankenstein funcional

## Objetivo

Montar a primeira superficie navegavel da plataforma Saude Slim reaproveitando a base Marketion/MKTON.IO e os fluxos operacionais ja existentes de produtos, vendas, CRM, Inbox, automacoes e recuperacao.

## Direcao do owner

- Codar diretamente no repositorio/GitHub como fonte de verdade.
- Nao usar o chat/agente da Lovable.
- Nao trabalhar direto na `main`.
- Primeiro montar o Frankenstein funcional.
- Rebranding, logo, cores, textos finais, dominio, deploy final e conexoes finais ficam para depois.
- O navegador servira apenas para visualizar a aplicacao enquanto o codigo evolui.

## Dentro do escopo desta etapa

- Criar uma entrada/tela Saude Slim dentro da branch `saude-slim`.
- Reaproveitar modulos reais existentes em vez de duplicar:
  - dashboard;
  - CRM/leads/funis;
  - produtos/catalogos/estoque;
  - Inbox;
  - automacoes/SalesBots;
  - agentes de IA;
  - tracking;
  - recuperacao de clientes.
- Criar atalhos operacionais para as rotas reais.
- Exibir indicadores a partir de fontes reais existentes quando disponiveis.
- Mostrar estados vazios quando os dados ainda nao existirem.

## Fora do escopo desta etapa

- Trocar identidade visual.
- Configurar dominio.
- Criar novas conexoes finais de cliente.
- Substituir backend real por mock.
- Criar nova arquitetura de pedidos se ja houver contrato aproveitavel.
- Alterar Supabase, Kommo, WhatsApp, Inbox real, tracking real ou automacoes sensiveis sem necessidade comprovada.

## Criterios de aceite

- A rota `/saude-slim` abre dentro do app.
- A sidebar possui entrada para Saude Slim.
- A tela mostra o Frankenstein operacional com secoes de vendas, pedidos, produtos/estoque, clientes/recuperacao, Inbox, automacoes e IA.
- Os cards navegam para rotas reais existentes.
- Build ou validacao tecnica equivalente e executada.
- Arquivos alterados e limitacoes ficam registrados.

## Status

- 2026-10-06: escopo aberto; implementacao inicial da rota Saude Slim em andamento.
- 2026-10-06: primeira versao do Frankenstein implementada em `/saude-slim`.
- Validado: `npm run check:routes` passou com a rota gerada.
- Validado: checagem focada de TypeScript nao retornou erros em `src/routes/saude-slim.tsx` nem `src/components/dashboard/AppSidebar.tsx`.
- Limitacao de ambiente: `npm run build` ainda depende de `bun` no script de `prebuild`, e `bun` nao esta instalado neste Windows.
- 2026-10-06: rota `src/routes/saude-slim.tsx` refeita com CSS proprio inline para nao depender do Tailwind/global no preview local.
- Validado: `/saude-slim?refresh=inline-ui` respondeu HTTP 200 no servidor local.
- Decisao: sem mockup, sem imagem fake, sem dado inventado e sem Marketion/MKTOn visivel na tela Saude Slim.
- 2026-10-07: corrigidos seletores Tailwind/CSS herdados que quebravam o Vite/LightningCSS no Windows e faziam o preview abrir sem estilos.
- Validado: `npm run check:routes` passou novamente.
- Validado: `/saude-slim?refresh=cssfix2` respondeu HTTP 200 no servidor local com Vite reiniciado usando `--force`.
- Observacao: permanecem warnings antigos de `createServerFn().inputValidator()` depreciado e hydration mismatch de tema no shell global; nao bloqueiam a rota Saude Slim nesta etapa.
- 2026-10-07: ajustada a experiencia para sistema interno da Saude Slim: removida linguagem de criar conta, teste gratis e venda SaaS da rota `/auth`.
- 2026-10-07: marca visual do shell/sidebar e da tela `/saude-slim` alterada para Saude Slim. Nomes tecnicos internos `Mkton/MKTOn` em funcoes, pixel, provisionamento e APIs foram preservados para nao quebrar backend/integracoes reais.
- 2026-10-07: fluxo autenticado padrao ajustado para direcionar usuarios logados para `/saude-slim`.
- Validado: `/auth?refresh=saudeslim-internal` respondeu HTTP 200.
- Validado: `/saude-slim?refresh=internal-brand` respondeu HTTP 200.
- 2026-10-07: novo ajuste solicitado pelo owner: aplicar a identidade visual Saude Slim no shell autenticado inteiro, especialmente Pedidos, Clientes e Inbox, para nao parecer que o usuario saiu para a Marketion.
- Dentro desta etapa: sidebar global, cores de tema front-end, rotulos visiveis principais e links reais reaproveitados.
- Fora desta etapa: alterar backend, renomear funcoes internas Mkton/MKTOn, migrations, integracoes, contratos de APIs ou dados reais.
- 2026-10-07: sidebar autenticada global substituida por navegacao operacional Saude Slim com largura fixa, marca Saude Slim, atalhos para Dashboard, Pedidos, Clientes, Inbox, Funis, Automacoes, SalesBots, Agentes IA, Disparo em massa, Estoque, Produtos, Tracking, Historico de vendas e Fornecedores.
- 2026-10-07: tema base de front-end ajustado para tons operacionais da Saude Slim e principais textos visiveis herdados de Marketion/MKTOn substituidos por Saude Slim, preservando identificadores tecnicos internos quando fazem parte do backend existente.
- Validado: `npm run check:routes` passou.
- Validado: `/saude-slim?refresh=global-shell`, `/crm/funis-de-venda?refresh=global-shell`, `/crm/leads?refresh=global-shell` e `/inbox/leads?refresh=global-shell` responderam HTTP 200.
- Observacao: o servidor local ainda emite warnings herdados de hydration/theme e `createServerFn().inputValidator()` depreciado; nesta etapa eles nao bloquearam as rotas testadas.
- 2026-10-07: menu lateral simplificado conforme revisao do owner. Estrutura atual: Dashboard; Pedidos com Historico de vendas, Fornecedores, Estoque e Produtos; Clientes com Disparo em massa; CRM expansivel com Funil de vendas, Automacoes, SalesBots, Agentes IA e Inbox.
- Validado: `npm run check:routes` passou apos a reorganizacao do menu.
- Validado: `/saude-slim?refresh=sidebar-groups`, `/crm/funis-de-venda?refresh=sidebar-groups`, `/crm/leads?refresh=sidebar-groups` e `/inbox/leads?refresh=sidebar-groups` responderam HTTP 200.
- 2026-10-07: removida da navegacao a leitura de produto por assinatura. O menu recebeu Configuracoes com Geral, Integracoes, WhatsApp e Usuarios; Configuracoes deixou de exibir grupo de Faturamento/Planos na navegação principal.
- 2026-10-07: gates visuais de plano/teste/assinatura foram neutralizados no front-end para o sistema interno da Saude Slim; backend, tabelas, hooks e contratos reais foram preservados.
- 2026-10-07: painel de WhatsApp Web em Integracoes passou a falar em numeros conectados da Saude Slim e nao em limite de plano, mantendo o fluxo real de QR/sessao.
- Validado: `npm run check:routes` passou apos ajustes de Configuracoes/Integracoes.
- Validado: `/configuracoes?refresh=internal-settings`, `/integracoes?refresh=internal-settings` e `/modulos/tracking?refresh=no-plan-gate` responderam HTTP 200.
- 2026-10-07: substituidas as superficies frágeis/legadas navegadas pelo menu por paginas operacionais estaveis da Saude Slim para Pedidos/Funis, Clientes, Automacoes/SalesBots, Agentes IA, Inbox, Estoque/Produtos, Fornecedores e Historico de vendas. As paginas mostram estado vazio e CTAs reais, sem numeros inventados.
- 2026-10-07: corrigidos identificadores tecnicos invalidos criados por troca visual no legado de funis (`Saúde Slim` dentro de variaveis, keyframes, MIME types, headers e atributos data-*), preservando textos visiveis de Saude Slim.
- 2026-10-07: servidor local reiniciado com `--force` para limpar cache de modulo antigo que causava `Failed to fetch dynamically imported module` em `/crm/funis-de-venda`.
- Validado: `npm run check:routes` passou apos a troca das superficies.
- Validado: `/auth`, `/saude-slim`, `/crm/funis-de-venda`, `/painel`, `/crm/empresas`, `/crm/produtos`, `/crm/leads`, `/crm/automacoes`, `/crm/agente-ia`, `/inbox/leads`, `/configuracoes`, `/integracoes` e `/modulos/tracking` responderam HTTP 200 depois do restart forçado, sem texto de erro na resposta.
- Observacao: `npx tsc --noEmit --skipLibCheck` continua pesado/lento neste projeto; foi interrompido depois de nao finalizar em tempo util. A validacao objetiva desta etapa foi rota, SSR e dev server sem erro fatal apos restart.
- 2026-10-07: correcao de rumo apos revisao do owner: as paginas genericas iguais foram removidas das rotas principais. Funil de vendas, Automacoes/SalesBots, Agentes IA, Inbox, Produtos, Fornecedores, Clientes e Historico de vendas voltaram a usar as implementacoes reais/ricas existentes, com branding Saude Slim no front-end.
- 2026-10-07: Estoque foi separado de Produtos em rota propria `/crm/estoque`, lendo os produtos reais via `listProductCatalogs` e exibindo quantidade, preco, status OK/baixo estoque/sem estoque e estado vazio quando nao houver produto cadastrado.
- 2026-10-07: Clientes voltou a ser tela real de lista/ficha de clientes; Disparo em massa ficou como item interno de Clientes apontando para `/crm/publicos`, que mantem o fluxo real de listas/transmissao/reativacao.
- 2026-10-07: removido `TrialBanner` do painel autenticado da Saude Slim e rótulos de fallback do dashboard foram ajustados para Saude Slim, sem trocar contratos de backend.
- Validado: `npm run check:routes` passou com 145 rotas geradas.
- Validado: `/auth`, `/saude-slim`, `/crm/funis-de-venda`, `/painel`, `/crm/empresas`, `/crm/estoque`, `/crm/produtos`, `/crm/leads`, `/crm/publicos`, `/crm/automacoes`, `/crm/agente-ia`, `/inbox/leads`, `/configuracoes`, `/integracoes` e `/modulos/tracking` responderam HTTP 200 e sem texto de erro fatal na resposta.

## Ajustes rapidos solicitados em 2026-10-12

- Reorganizar a sidebar em Modulos com Historico de Vendas, Vendas, CRM e Configuracoes.
- Transformar `/saude-slim` em Historico de Vendas em lista, com busca e paginacao 10/20/35/50.
- Manter `/painel` como dashboard rica e renomear a navegacao para Dashboard detalhada.
- Criar entrada de Pedidos sem redirecionar para Funil de vendas, preservando o funil existente sem alteracoes.
- Preservar Funil de vendas, Inbox, Automacoes, Estoque, Produtos, Fornecedores e Publicos.
- Ajustar cadastro de cliente para aceitar fonte existente ou fonte nova digitada, alem de endereco e e-mail opcionais.
- Corrigir contraste do menu lateral no estado ativo/aberto.
- Liberar a superficie de Agente IA no front-end para sistema interno, sem alterar RLS, banco ou contratos sensiveis.
- Forcar tema escuro e remover o controle de Aparencia/tema das configuracoes.
- Limpar Configuracoes/Integracoes: Geral sem Perfil/Empresa/Notificacoes/Preferencias/Aparencia; Integracoes apenas Meta, WhatsApp Web, OpenAI, Claude Code, Gemini, Webhook e Central Google, sem busca/filtros/categorias.

Fora de escopo deste pacote:
- Alterar backend sensivel, RLS, Supabase, contratos de integracoes, Funil de vendas, Inbox e Automacoes aprovados.
- Conectar VPS/WhatsApp em runtime.

Status 2026-10-12:
- Implementado menu lateral novo com Historico de vendas, Vendas, CRM e Configuracoes.
- Criada rota `/pedidos` para retirada de pedido com produto existente, novo produto ou venda avulsa; cliente existente, novo cliente ou sem cadastro; desconto em valor ou porcentagem.
- `/saude-slim` passou a ser Historico de vendas em lista com busca e paginacao 10/20/35/50.
- Cadastro de cliente aceita fonte existente ou nova fonte digitada, e ganhou endereco opcional.
- Tema escuro fixo aplicado via provider; controle de aparencia ficou fora da navegacao de Configuracoes.
- Integracoes reduzidas para Meta, WhatsApp Web, OpenAI, Claude Code, Gemini, Webhook e Central Google, sem busca/filtros/categorias.
- Agente IA liberado no front-end do sistema interno, sem alterar RLS ou contratos do banco.
- Validado: `npm run check:routes` passou com 146 rotas geradas.
- Validado: `/saude-slim`, `/pedidos`, `/configuracoes`, `/integracoes`, `/crm/leads`, `/crm/agente-ia`, `/painel`, `/crm/funis-de-venda`, `/inbox/leads` e `/crm/automacoes` responderam HTTP 200 no servidor local.
- Limitacao: `npx tsc --noEmit --skipLibCheck --pretty false` foi interrompido apos mais de 2 minutos sem concluir.
- Limitacao: `npx vite build` avancou ate o bundle, mas falhou em plugin legado do SalesBot (`helper screenToWorld nao encontrado` em `src/components/automations/SalesbotBuilder.tsx`), fora do escopo preservado de Automacoes.

## Ajuste pontual solicitado em 2026-10-12 - Home e filtros do historico

Objetivo:
- Trocar o item solto de Historico de vendas por uma sanfona `Home`.
- Colocar dentro da Home as paginas `Historico de Vendas` e `Dashboard detalhada`.
- Remover `Dashboard detalhada` da sanfona de Vendas.
- No Historico de Vendas, manter busca escrita e adicionar filtros selecionaveis para Data, Tag, Origem e Campo personalizado usando as opcoes existentes nas vendas carregadas.

Fora de escopo:
- Alterar Funil de vendas, Inbox, Automacoes, backend, Supabase, RLS ou contratos sensiveis.

Status:
- Implementado `Home` como sanfona no menu lateral, contendo `Historico de Vendas` e `Dashboard detalhada`.
- `Dashboard detalhada` removida da sanfona `Vendas`.
- Historico de vendas ganhou filtros selecionaveis por Data, Tag, Origem e Campo personalizado, combinados com a busca escrita existente.
- Validado: `npm run check:routes` passou com 146 rotas geradas.
- Validado: `/saude-slim?refresh=home-filters` e `/painel?refresh=home-menu` responderam HTTP 200 no servidor local, sem texto de erro fatal.

## Ajuste pontual solicitado em 2026-10-12 - Fornecedores

Objetivo:
- Remover a experiencia/textos de `Empresas` da aba `Fornecedores`.
- Fazer a pagina funcionar como lista de fornecedores, com botao para adicionar fornecedor.
- Permitir associar produtos aos fornecedores com custo, pedido minimo, prazo e observacoes.
- Preparar a base real para automacoes por fornecedor, comparacao de preco e ranking de lucro por fornecedor.

Decisao tecnica:
- Reaproveitar `companies` como cadastro persistente do fornecedor para nao duplicar cadastro organizacional.
- Adicionar migration `supplier_product_costs` para persistir vinculo produto/fornecedor/custo sem mock.

Fora de escopo:
- Publicar/aplicar migration no Supabase de producao nesta etapa.
- Implementar ranking global e automacoes completas; a base de dados e a ficha ja ficam preparadas para isso.

Status:
- `/crm/empresas` deixou de carregar a tela legada de Empresas e passou a renderizar uma pagina propria de Fornecedores.
- Implementada lista de fornecedores com busca, selecao de ficha e botao `Adicionar fornecedor`.
- Implementada ficha do fornecedor com dados comerciais, edicao e metricas de produtos vinculados/custo/margem.
- Implementado vinculo fornecedor-produto com custo, pedido minimo, prazo e observacoes via `supplier_product_costs`.

## Ajuste pontual solicitado em 2026-10-12 - Copiloto mordomo operacional

Objetivo:
- Configurar o Copiloto como mordomo operacional da Saude Slim, sem fugir do atendimento padrao.
- Permitir que ele ensine o usuario a usar o sistema e tambem execute acoes reais quando solicitado.
- Permitir leitura de conversas, historicos, leads, funis, etapas, integracoes e configuracoes para dar respostas com contexto real.
- Manter o bloqueio quando nao houver chave de IA propria no workspace.

Status:
- Prompt do Copiloto atualizado para papel de mordomo operacional, com autonomia para executar ferramentas reais quando o pedido estiver claro.
- Copiloto passou a aceitar IA propria do workspace por OpenAI ou Gemini; sem chave propria continua bloqueado.
- Adicionadas ferramentas para buscar leads, listar etapas, mover lead de etapa, ler historico/conversas do lead, atualizar fuso/expediente, convidar funcionario e gerar relatorio operacional.
- Endpoint do Copiloto passou a combinar ferramentas de suporte, diagnostico, CRM e leituras estrategicas ja existentes.
- Validado: `npm run check:routes` passou com 146 rotas geradas.
- Validado: `/saude-slim?refresh=copilot-butler`, `/integracoes?refresh=copilot-ai-provider` e `/crm/agente-ia?refresh=copilot-butler` responderam HTTP 200, sem texto de erro fatal.
- Limitacao: `npx tsc --noEmit --skipLibCheck --pretty false` foi interrompido apos cerca de 90 segundos sem concluir nem emitir erros.

## Ajuste pontual solicitado em 2026-10-12 - Remocao de azul do sistema

Objetivo:
- Trocar os acentos azuis/indigo ainda espalhados pelo sistema pelo verde usado no menu lateral.
- Manter o sistema no tema escuro, sem reintroduzir tema claro para o usuario.

Status:
- Tokens globais do tema escuro (`.dark` e `[data-theme="dark"]`) migrados de azul/indigo para verde Saude Slim.
- Tokens de foco, borda, graficos, sidebar e superficies de chat migrados para verde.
- Tema claro legado tambem foi neutralizado para verde, caso algum trecho antigo seja reaproveitado internamente.
- Classes azuis residuais em componentes internos foram trocadas para verde sem alterar regras de negocio ou backend.
- Validado: `npm run check:routes` passou com 146 rotas geradas.
- Validado: `git diff --check` passou sem erros de whitespace.

## Ajuste pontual solicitado em 2026-10-12 - Remover assistente do painel

Objetivo:
- Remover o assistente flutuante exclusivo do painel.
- Manter apenas o Copiloto global da Saude Slim.

Status:
- Removida a montagem do `DashboardChat` em `/painel`.
- Copiloto global (`SupportRobot`) preservado sem alteracoes.

## Ajuste pontual solicitado em 2026-10-12 - Sanfona Fase 2

Objetivo:
- Adicionar a sanfona `Fase 2` abaixo de Configuracoes no menu lateral.
- Exibir os caminhos futuros sem permitir clique/navegacao por enquanto.

Status:
- Adicionada sanfona `Fase 2` no menu lateral.
- Itens exibidos como desativados: `Tracking avancado`, `E-mail Marketing`, `Sms Marketing` e `Redes Sociais`.

## Ajuste operacional iniciado em 2026-10-12 - WhatsApp no Railway

Objetivo:
- Usar Railway para hospedar a Evolution API que alimenta o WhatsApp Web da Saude Slim.
- Conectar a Evolution ao backend real ja existente, sem criar mock nem duplicar integracao.

Status:
- Confirmado que o sistema ja possui integracao real com Evolution via `EVOLUTION_BASE_URL`, `EVOLUTION_GLOBAL_API_KEY`, `INTEGRATION_ENCRYPTION_KEY` e webhook `/api/public/evolution/webhook/<secret>`.
- Confirmado que o ambiente local ainda nao declara as variaveis de Evolution.
- Criado runbook `docs/runbooks/whatsapp-railway-evolution.md` com arquitetura, variaveis e validacao.

Proximo passo operacional:
- Criar/deployar Evolution API no Railway com Postgres, Redis e volume persistente.
- Copiar a URL publica da Evolution para `EVOLUTION_BASE_URL` no app.
- Copiar a chave global da Evolution para `EVOLUTION_GLOBAL_API_KEY` no app.
- Definir `PUBLIC_APP_URL` com a URL publica real do app Saude Slim.

## Ajuste pontual solicitado em 2026-10-12 - Separar Publicos e Disparo em massa

Objetivo:
- `Publicos` deve ser uma pagina de criacao/gestao de publicos.
- `Disparo em massa` deve ser uma pagina separada para selecionar um publico existente e executar o disparo.
- Corrigir o menu lateral para nao selecionar Publicos quando o usuario clicar em Disparo em massa.

Status:
- Criada rota separada `/disparo-em-massa`.
- Menu lateral passou a apontar `Disparo em massa` para `/disparo-em-massa`.
- `Publicos` permanece em `/crm/publicos` dentro do CRM.
- A rota de Publicos foi renomeada visualmente para `Publicos`, deixando de se apresentar como Disparo em massa.
- Removido o botao de transmissao direta da lista de Publicos; o envio fica concentrado na nova pagina.
- Validado: `npm run check:routes` passou com 147 rotas geradas.
- Validado: `/disparo-em-massa?refresh=separate-bulk` e `/crm/publicos?refresh=separate-publicos` responderam HTTP 200.

## Ajuste pontual solicitado em 2026-10-12 - Login Saude Slim

Objetivo:
- Dar mais identidade de Saude Slim para a pagina de login.
- Remover azul visual remanescente da tela de autenticacao.
- Preservar toda a logica existente de login, cadastro, confirmacao e recuperacao de senha.

Status:
- Login redesenhado com paleta verde, fundo claro esverdeado e painel lateral escuro da Saude Slim.
- Textos do painel lateral ajustados para operacao da Saude Slim: historico de vendas, estoque, atendimento e acesso seguro.
- Estados de confirmacao de e-mail, segunda etapa e recuperacao de senha tambem migrados para verde.
- Validado: `npm run check:routes` passou com 147 rotas geradas.
- Validado: `/auth?refresh=saude-slim-login` respondeu HTTP 200.
- Validado: busca por azul visual em `src/routes/auth.tsx` nao retornou ocorrencias.
