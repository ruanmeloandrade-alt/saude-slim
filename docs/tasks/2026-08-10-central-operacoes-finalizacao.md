# Task — Finalização da Central de Operações

Data: 2026-08-10
Branch: `fix/central-operacoes-final`
Base inicial: `main` em `dc803b7eb1ed88e06eb34ffa7fe9aa0dd4048f64`
PR: `#66`
Merge em `main`: `afd67286e587ac67f76dd8a6cef1136e9e89a499`
Status: **FINALIZADA — 8/8**

## Objetivo

Finalizar tecnicamente a Central de Operações administrativa da MKTOn, removendo redundâncias, corrigindo funcionalidades quebradas e deixando a área coerente para uso diário do super administrador.

## Requisitos recebidos

- Organizar nomes, abas, botões e funcionalidades da Central.
- Remover controles sem utilidade real ou que dupliquem outra função.
- Mesclar Cobranças e Renovação automática em uma mesma área operacional, sem perder funcionalidades existentes.
- Preservar Cadastros.
- Preservar gestão de Cupons e seu histórico.
- Permitir abrir o detalhe de uso de um cupom, identificar quem utilizou e navegar para o lead/conversa correspondente no Inbox quando houver correlação real.
- Corrigir a aba Execuções e Bugs, que estava apresentando erro.
- Manter a Central visível e executável somente para `super_admin`.
- Manter este escopo versionado para handoff entre IAs.

## Escopo fechado — 8 tarefas

1. [x] Auditar a estrutura atual da Central na `main` mais recente e classificar abas/ações em manter, mesclar, corrigir ou remover.
2. [x] Mesclar Cobranças e Renovação em uma única área financeira operacional, preservando criação das duas rotinas úteis.
3. [x] Revisar botões e ações da Central: a navegação foi reduzida a Cadastros, Cupons, Financeiro, SMS, Histórico e Execuções e Bugs; o botão genérico de campanha foi substituído por ações coerentes com cada frente.
4. [x] Transformar o uso de cupons em drill-down: uso → workspace/owner → lead real de cadastro (`signup:<userId>`) → botão de Inbox somente quando a correlação existe.
5. [x] Corrigir Execuções e Bugs na causa raiz: o relatório parte de `salesbot_runs` filtrado por workspace e carrega logs por `salesbot_run_id`, sem depender de `workspace_id` em `salesbot_run_logs`; fontes parciais geram aviso em vez de derrubar a tela.
6. [x] Preservar Cadastros, Histórico, Cupons, SMS e os dados financeiros/campanhas existentes sem recriar módulos.
7. [x] Atualizar regressões para `super_admin`, relatório resiliente, financeiro unificado, drill-down de cupom e preservação das abas essenciais.
8. [x] Revisar diff, validar teste focado + build de produção e integrar em `main` pela PR #66.

## Implementação realizada

- `src/routes/campanhas.tsx`
  - `Cobranças` + `Renovação` viraram uma única aba `Financeiro`;
  - a área financeira contém ações explícitas `Nova cobrança` e `Nova renovação`;
  - `SMS` usa `Novo envio`, evitando o termo genérico “campanha” onde não ajuda;
  - o contador de uso de cupom virou ação de drill-down;
  - Cadastros, Cupons, Histórico e Execuções e Bugs foram preservados.
- `src/components/operations/CouponUsageButton.tsx`
  - mostra os usos reais do cupom;
  - exibe cliente/workspace/contato quando disponível;
  - só oferece `Abrir no Inbox` quando existe `leadId` correlacionado.
- `src/lib/admin-coupon-usage.functions.ts`
  - resolve `coupon_usages` → workspace → owner → lead de cadastro real;
  - não inventa correlação quando não existe lead.
- `src/lib/operations-report.functions.ts`
  - remove dependência de `workspace_id` nos logs;
  - preserva isolamento pelo workspace via `salesbot_runs`;
  - telemetria parcial passa a ser degradada por fonte;
  - detecção de duplicidade continua exigindo timestamp real de log.
- `src/components/operations/OperationsExecutionReport.tsx`
  - mostra indisponibilidade parcial de telemetria sem quebrar o relatório inteiro.
- `src/lib/__tests__/operations-center.test.ts`
  - contratos atualizados para a Central atual.

## Validação executada

GitHub Actions run `31452722994`:

- aplicação do patch protegido: sucesso;
- instalação de dependências: sucesso;
- `src/lib/__tests__/operations-center.test.ts`: sucesso;
- build completo de produção: sucesso;
- commit do patch validado: sucesso.

Os arquivos temporários usados apenas para aplicar/validar o patch foram removidos antes da PR final.

## Fora de escopo

- Alterar preços, planos ou limites de usuários/WhatsApp.
- Reestruturar billing global fora do necessário para a Central.
- Modificar Lovable diretamente.
- Criar dados fictícios para preencher histórico, leads, execuções ou bugs.
- Alterar módulos de CRM, Inbox ou Workflow além do deep link para um lead já correlacionado.

## Decisões finais

- A rota interna permanece `/campanhas` para evitar quebra de links existentes, mas a experiência continua `Central de Operações`.
- `Financeiro` é a única entrada para cobrança e renovação.
- Falha de uma fonte opcional de telemetria não deve impedir o super admin de enxergar o restante do relatório.
- Drill-down de cupom só oferece navegação ao Inbox quando há `leadId` real.

## Próxima etapa

Finalização de **Configurações e Permissões**, com escopo próprio versionado em `docs/tasks/` antes das alterações.
