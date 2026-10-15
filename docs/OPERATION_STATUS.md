# Saúde Slim: semáforo de produção

Checkpoint: 15/10/2026. Último código funcional publicado e conferido: `c7956c46a5bfdf9de5d2f63d3289a0970ce66e7f`.
Railway: deploy `b98780e6-c606-4450-bbb4-64791b75caa0`, SUCCESS; servidor iniciou em 15/10/2026 às 09:05 UTC (06:05 Brasília). Este checkpoint altera documentação, não o código desse deploy.

Repositório exclusivo: `ruanmeloandrade-alt/saude-slim`.
Branch operacional: `restauracao/sistema-completo-20261014`.
Supabase: `vyzvfcgpjjzvcjegzzza`. Serviço web existente: `saude-slim-web`.

Este documento substitui o status herdado da MktOn de agosto, que não descrevia a Saúde Slim. Não usar o projeto original como destino de alterações.

## Legenda

- 🟢 Concluído no recorte descrito, publicado e com evidência de validação.
- 🟠 Em andamento ou parcialmente corrigido. A coluna de pendência explica o que impede a conclusão.
- 🔴 Pendente com bloqueio confirmado ou implementação necessária.

O verde de uma correção não torna todo o módulo verde. Não usar número de tabelas, build ou teste controlado como prova de homologação integral.

## Entregas delimitadas já verificadas

| Entrega | Estado | Evidência e limite |
|---|---|---|
| Cofre de IA e persistência de configuração/histórico | 🟢 | Migrations 20261015024506 e 20261015025453; RPCs autenticadas testadas com rollback, código publicado e nove testes de resolução de chave passaram. Não equivale a resposta OpenAI real. |
| Correção de leitura do histórico de vendas | 🟢 | Commit 28c8a5a publicado; sete testes de paginação e precedência de resultado passaram. Não equivale a homologação de pedidos. |
| Varredura estrutural do menu | 🟢 | 16 frentes, 444 arquivos e 147 rotas referenciadas; execução estática documentada. Auditoria funcional integral permanece aberta. |
| Dashboard: carregamento comercial sem bloqueio por fontes opcionais | 🟢 | Commit c7956c4 publicado; 16 testes de dados e oito verificações do contrato sobre fontes reais passaram no build. Oito SELECTs comerciais executados com papel authenticated. Falta navegação autenticada/E2E. |
| Semáforo exclusivo da Saúde Slim | 🟢 | Estado herdado substituído; cada frente abaixo possui feito, pendência e ponto de continuidade. |

## Frentes na ordem do menu

| Ordem | Área | Estado | Feito | Falta / próxima ação |
|---|---|---|---|---|
| 0 | Agentes IA | 🟠 | Cofre, persistência e tratamento de falhas corrigidos | Última consulta: zero integrações salvas e zero agentes cadastrados. Falta cadastro pelo operador e resposta IA real/WhatsApp controlada. Nunca solicitar chave no chat. |
| 1 | Home: Histórico de Vendas | 🟠 | Corte de mil registros e precedência won/lost corrigidos | Validar filtros e detalhamento pela interface autenticada. |
| 2 | Home: Dashboard detalhada | 🟠 | Leitura comercial paginada; status explícito respeitado; fontes ausentes identificadas; removido fallback de métricas fictícias; sincronização respeita módulos habilitados; publicado | Fontes de formulários/campos/tracking continuam ausentes e são exibidas como indisponíveis. Falta homologação da interface, períodos e indicadores personalizados. |
| 3 | Vendas: Pedidos | 🟠 DIAGNÓSTICO INICIADO | Primeiro vínculo de compra testado anteriormente; fluxo da tela agora revisado | Resolver gravação não atômica, duplicação de lead na seleção de cliente existente, desconto integral com produto novo e tratamento de valor monetário. Restrição UNIQUE bloqueia repetição no mesmo lead; a tela atual cria outro lead, não um pedido associado ao mesmo cliente. Nenhuma dessas correções foi publicada neste bloco. |
| 4 | Vendas: Fornecedores | 🟠 | CRUD fornecedor/custo testado no banco com rollback | Homologar tela e relações. Banco testado não é E2E. |
| 5 | Vendas: Estoque | 🟠 | Cadastro/edição de estoque testados no banco | Validar movimentação por pedido e histórico. Não foi implementada baixa automática nesta auditoria. |
| 6 | Vendas: Produtos | 🟠 | Catálogo/produto testados no banco; leitura do painel corrigida | Homologar cadastro, edição, exclusão e vínculos pela interface. |
| 7 | Vendas: Disparo em massa | 🔴 | Dependências mapeadas | Públicos/execução ainda possuem bloqueios estruturais. Não testar contra clientes reais. |
| 8 | CRM: Funil de vendas | 🟠 | Adaptadores básicos e schema examinados | Auditar chamadas herdadas, automações de etapa e campos personalizados. |
| 9 | CRM: Clientes | 🟠 | Cadastro/leituras básicas verificados no banco | Homologar filtros, alterações, deduplicação e permissões pela interface. |
| 10 | CRM: Inbox | 🟠 | Usuário confirmou envio SalesBot; controles individuais publicados; regressões preservadas | Atendimento IA real, anexos e cenários completos. Preservar salvamento manual/120 segundos. |
| 11 | CRM: Automações | 🔴 | SalesBot básico e controle individual corrigidos | Dependências de automações de etapa, grupos e recursos avançados ausentes. |
| 12 | CRM: Cérebro IA | 🟠 | Fontes/chunks/termos bloqueados existentes | Homologar ingestão, recuperação de conhecimento e resposta real. |
| 13 | CRM: Públicos | 🔴 | Consumidores auditados | crm_lead_audiences e dependências de filtros/ações ausentes. |
| 14 | Configurações: Geral | 🔴 | Estruturas básicas de equipe/permissões existentes | Segurança, convites e funções ausentes; revisão de autorizações. |
| 15 | Configurações: Integrações | 🟠 | Cofre IA corrigido; conector WhatsApp preservado | Validar cadastro real da chave e revisar status/contratos das integrações oferecidas. |

## Validação deste checkpoint

- 16/16 regressões da camada de dados da Dashboard e 8/8 verificações de integração do código passaram no build do Railway.
- Regressões anteriores de Inbox, IA, histórico e salvamento SalesBot continuam no prebuild. Nove da IA e sete do histórico foram reconfirmadas nos logs deste deploy.
- Oito consultas comerciais reais executadas com papel authenticated; quatro fontes opcionais ausentes reproduzidas separadamente. Usuário sem vínculo não leu clientes/produtos/vendas.
- Nenhum registro de teste criado neste bloco, nenhuma mensagem enviada, nenhuma chave lida ou rotacionada.
- Primeiro build c0d04e57 foi bloqueado por âncora ambígua do widget de formulários. Corrigido em c7956c4; segundo deploy b98780e6 concluído com SUCCESS. A versão anterior permaneceu ativa durante a correção.
- Pós-deploy: status SUCCESS e inicialização do servidor confirmados. O acesso HTTP independente à página não pôde ser executado (ferramenta web sem acesso; container sem resolução DNS); os logs HTTP consultados não apresentaram requisições para esse deploy. Não declarar smoke da página nem navegador autenticado realizados.

## Continuidade

Ponto atual: `docs/tasks/2026-10-15-slim-orders-audit.md`, diagnóstico de Pedidos, preservando as pendências de homologação da Dashboard. Nenhum trabalho é considerado em execução após o encerramento da sessão; o estado acima registra a última frente trabalhada.

Atualizar este arquivo a cada checkpoint com commit, testes efetivamente executados, publicação e limites. Não marcar módulo inteiro de verde por conserto parcial.
Não alterar main, DNS, Evolution, Harpia, MCP, MktOn original ou Fase 2. Sem GitHub Actions, Vercel ou agente Lovable.

## Evidências versionadas

- `docs/tasks/2026-10-15-slim-dashboard-production.md`
- `docs/tasks/2026-10-15-slim-orders-audit.md`
- `docs/audits/saude-slim-ia-menu-audit-20261015.md`
- `docs/audits/saude-slim-ia-repair-20261015.md`
- `docs/audits/saude-slim-home-read-20261015.md`
