# Dashboard V4 — Management Cockpit

Status: concluída tecnicamente e publicada para teste visual
Data: 2026-08-10
Branch: `agent/dashboard-v4-management-cockpit`
PR: `#62`
Merge em `main`: `57bf4704bd15b35f16d4edd94678a1e3973074d3`

## Objetivo

Transformar a Dashboard em um protótipo visual completo de gestão da operação, sem restringir o front pela disponibilidade atual do backend. Nesta etapa, dados demonstrativos/mockados são permitidos e desejados para validar hierarquia, leitura e utilidade antes da fase de conexão real.

## Requisitos recebidos

- Dar mais liberdade visual ao painel e reduzir a sensação de layout engessado.
- Permitir que o usuário bata o olho e entenda a operação inteira.
- Mostrar Produtos/Serviços e ranking do que mais vende.
- Mostrar Empresas/Clientes com maior peso na operação.
- Mostrar performance de Formulários.
- Mostrar análise de Tags.
- Mostrar leitura útil de Campos Personalizados.
- Fazer o Tracking aparecer completo no front, incluindo UTMs, eventos, canais e atribuição.
- Manter CRM, tráfego, vendedores, Social Media, agenda e automações dentro da leitura executiva.
- Usar mocks nesta fase para dar liberdade de prototipação; remover/substituir mocks na fase 2 de backend.

## Escopo

1. [x] Criar topo executivo com receita, mídia, ROAS, leads, vendas e conversão.
2. [x] Criar visão de saúde geral da operação.
3. [x] Criar leitura comercial com funil e ranking de vendedores.
4. [x] Criar ranking de produtos/serviços por vendas, receita, ticket e participação.
5. [x] Criar ranking de empresas/clientes e performance de formulários.
6. [x] Criar análise visual de tags e campos personalizados.
7. [x] Criar Tracking demonstrativo completo: canais, UTMs, eventos e caminhos de conversão.
8. [x] Criar bloco de mídia paga conectado ao resultado do negócio.
9. [x] Criar bloco Social Media com top conteúdos e indicadores.
10. [x] Criar bloco de operação com agenda, tarefas e saúde das automações.
11. [x] Validar build/CI e corrigir regressões.
12. [x] Publicar em `main` para teste visual na Lovable.

Progresso: **12/12 concluídos — 100% da V4 front-end**.

## Fora de escopo desta etapa

- Conectar dados reais de produtos, empresas, formulários, tags, campos personalizados, Tracking, Social Media, agenda ou automações.
- Alterar schema de banco.
- Criar novas integrações ou credenciais.
- Definir arquitetura definitiva de atribuição.

## Decisões

- A V4 é explicitamente um protótipo de front com dados demonstrativos.
- O painel exibe uma identificação clara de `Dashboard V4 · protótipo de gestão` e informa que os dados são demonstrativos.
- A fase seguinte substituirá os mocks pelas fontes reais preservando a hierarquia visual aprovada.
- A V4 prioriza visão executiva integrada em vez de condicionar cada seção aos módulos disponíveis durante a prototipação.
- Nenhum mock desta etapa deve ser tratado como dado real de produção.

## Implementação visual

- Visão executiva com receita, investimento, ROAS, leads, vendas, conversão e saúde da operação.
- Comercial com funil de vendas e ranking de vendedores.
- Produtos/Serviços com vendas, receita, ticket e mix de faturamento.
- Empresas/Clientes com ranking de negócios e receita.
- Formulários com envios, qualificados e taxa de qualificação.
- Tags com volume, ganhos e conversão.
- Campos personalizados com padrões e insights de perfil.
- Tracking com sessões, conversões, vendas atribuídas, receita, canais, UTMs, eventos e caminhos de conversão.
- Mídia paga com CPL, CTR, CPC, conversas e leitura do gestor.
- Social Media com top conteúdos, alcance, engajamento e leads influenciados.
- Operação com agenda, tarefas, leads sem próxima ação e saúde das automações.

## Arquivos afetados

- `src/components/dashboard/BusinessIntelligenceBoard.tsx`
- `docs/tasks/2026-08-10-dashboard-v4-management-cockpit.md`

## Validação

GitHub Actions `Social Media CI`, run `31448062858`:

- instalação de dependências: sucesso;
- testes sociais: sucesso;
- regressão Home: sucesso;
- lint Social Media: sucesso;
- lint Home: sucesso;
- production build: sucesso.

## Próximo passo

Aguardar avaliação visual/funcional da V4. Somente depois da aprovação do desenho, iniciar a fase 2 para substituir mocks por fontes reais e definir a arquitetura de dados/atribuição necessária.
