# Saúde Slim: semáforo de produção

Atualização: 15/10/2026. Base publicada na retomada: `28c8a5a82248897e9989488f7e8a71d78a6335f0`.
Repositório exclusivo: `ruanmeloandrade-alt/saude-slim`. Branch operacional: `restauracao/sistema-completo-20261014`. Supabase: `vyzvfcgpjjzvcjegzzza`. Serviço existente: `saude-slim-web`.

Este documento substitui o status herdado da MktOn de agosto. O documento anterior não descrevia a Saúde Slim. Não usar o projeto original como destino de alterações.

## Legenda

- 🟢 Concluído no recorte descrito, publicado e com evidência de validação.
- 🟠 Em andamento, parcialmente corrigido ou aguardando integração/validação. Não está concluído.
- 🔴 Pendente com bloqueio confirmado ou implementação necessária.
- ⚪ Não homologado integralmente; não confundir presença de código/tabela com funcionamento.

## Entregas já verificadas

| Entrega delimitada | Estado | Evidência e limite |
|---|---|---|
| Correção do cofre de IA e persistência de configuração/histórico | 🟢 | Migrations 20261015024506 e 20261015025453 aplicadas; RPCs autenticadas testadas com rollback, código a81b6e0 publicado, 9 testes de resolução de chave passaram no build. Não equivale a resposta OpenAI real. |
| Correção de leitura do histórico de vendas | 🟢 | Commit 28c8a5a publicado; 7 testes de paginação e precedência de resultado passaram no build. Não equivale a homologação de pedidos completos. |
| Varredura estrutural do menu | 🟢 | 16 frentes, 444 arquivos e 147 rotas referenciadas; auditoria estática executada. Não é homologação funcional de todas as telas. |

## Semáforo dos módulos na ordem de execução

| Ordem | Área | Estado | Feito | Falta / próxima ação |
|---|---|---|---|---|
| 0 | Agentes IA | 🟠 | Cofre, persistência e tratamento de falhas corrigidos | Na consulta desta retomada: zero integrações salvas e zero agentes cadastrados. Falta cadastro pelo operador e resposta IA real/WhatsApp controlada; não solicitar chave no chat. |
| 1 | Home: Histórico de Vendas | 🟠 | Corte de mil registros e precedência won/lost corrigidos | Validação autenticada de filtros e detalhamento completo. |
| 2 | Home: Dashboard detalhada | 🟠 EM EXECUÇÃO | Bloqueio localizado em consultas obrigatórias a tabelas ausentes | Corrigir carregamento comercial preservando widgets/drilldowns e mostrar indisponibilidade real, sem dados fictícios. |
| 3 | Vendas: Pedidos | 🔴 | Primeiro vínculo de compra testado no banco | Compra repetida lead/produto bloqueada; revisar transação, estoque, descontos e modelo de pedidos antes de alterar. |
| 4 | Vendas: Fornecedores | 🟠 | CRUD de fornecedor/custo testado no banco com rollback | Homologar tela e relações; banco testado não é E2E. |
| 5 | Vendas: Estoque | 🟠 | Cadastro e edição de estoque testados no banco | Validar movimentação por pedido e histórico; não foi implementada baixa automática nesta auditoria. |
| 6 | Vendas: Produtos | 🟠 | Catálogo/produto testados no banco | Homologar cadastro, edição, exclusão e vínculos pela interface. |
| 7 | Vendas: Disparo em massa | 🔴 | Dependências mapeadas | Públicos/execução ainda têm bloqueios estruturais; não testar contra clientes reais. |
| 8 | CRM: Funil de vendas | 🟠 | Adaptadores básicos existentes e schema examinado | Auditar chamadas herdadas, automações de etapa e campos personalizados. |
| 9 | CRM: Clientes | 🟠 | Cadastro e leituras básicas verificadas no banco | Homologar filtros, alterações, deduplicação e permissões pela interface. |
| 10 | CRM: Inbox | 🟠 | Usuário confirmou envio SalesBot; controles individuais publicados | Atendimento IA real, anexos e cenários completos; preservar autosave manual/120s. |
| 11 | CRM: Automações | 🔴 | SalesBot básico e controle individual corrigidos | Dependências de automações de etapa, grupos e recursos avançados ausentes. |
| 12 | CRM: Cérebro IA | 🟠 | Fontes/chunks/termos bloqueados existentes | Homologar ingestão, recuperação de conhecimento e resposta real. |
| 13 | CRM: Públicos | 🔴 | Consumidores auditados | crm_lead_audiences e dependências de filtros/ações ausentes. |
| 14 | Configurações: Geral | 🔴 | Estruturas básicas de equipe e permissões existentes | Segurança, convites e funções ausentes; revisão de autorizações. |
| 15 | Configurações: Integrações | 🟠 | Cofre IA corrigido; conector WhatsApp preservado | Validar cadastro real da chave e revisar status/contratos das integrações oferecidas. |

## Regras do próximo checkpoint

Atualizar este arquivo antes de avançar para outro bloco. Registrar commit, teste efetivamente executado, publicação e limite de validação. Não marcar o módulo inteiro de verde por causa de um conserto parcial.
Não alterar main, DNS, Evolution, Harpia, MCP, MktOn original ou Fase 2. Sem GitHub Actions, Vercel ou agente Lovable.

## Documentação de referência

- `docs/audits/saude-slim-ia-menu-audit-20261015.md`
- `docs/audits/saude-slim-ia-repair-20261015.md`
- `docs/audits/saude-slim-home-read-20261015.md`
