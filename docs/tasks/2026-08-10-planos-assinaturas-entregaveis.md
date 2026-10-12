# Task — Planos e assinaturas / matriz de entregáveis

Data: 2026-08-10
Branch final de implementação: `feat/planos-assinaturas-entregaveis-main-sync`
PR final de implementação: `#61`
Merge em `main`: `da21d9bca1831a2ce1ee0760a718b75b28523345`
PR original substituída: `#59` (fechada sem merge após a `main` avançar com a Dashboard V3)
Status: **FINALIZADA — 100% da implementação técnica definida para esta task**

## Objetivo

Organizar a apresentação e a matriz de acesso dos planos MKTOn sem alterar preços, limites de usuários ou limites de números de WhatsApp. A mesma matriz vale para os ciclos mensal, trimestral, semestral e anual; o ciclo altera somente preço/vigência/bônus, nunca os entregáveis do plano.

## Regras preservadas

- Não alterar valores existentes de nenhum plano/período.
- Não alterar os limites atuais de usuários/funcionários e números de WhatsApp.
- Manter os códigos internos atuais (`starter`, `professional`, `business`, `enterprise`) para compatibilidade; apresentar comercialmente como Start, Growth, Performance e Scale.
- Não implementar nesta task a funcionalidade futura do Gestor de CRM; apenas refletir que ele pertence ao escopo/acesso do Start conforme definição do produto.
- Home, Configurações e Faculdade MKTOn são áreas comuns a todos os planos.

## Matriz implementada

### Start

- Dashboard.
- Suporte via Chat Suporte dentro do Inbox Chat.
- CRM: funis de venda, automações do CRM, Sales Bot e relatórios do Sales Bot.
- Gestor de CRM incluído no escopo do plano, sem implementar sua funcionalidade nesta task.
- Formulários, Empresas, Produtos, Arquivos e Leads.
- Inbox Chat.
- Calendário.
- Não inclui Agent AI, bots de grupo, Agent AI de grupo ou demais recursos de IA do Growth em diante.

### Growth

Tudo do Start, mais:

- Fluxo de Trabalho.
- Notas.
- Agent AI.
- Sales Bot de grupo.
- Agent AI de grupo.

### Performance

Tudo do Growth, mais:

- Tracking & Analytics.
- Suporte prioritário via WhatsApp.
- Automações executáveis do Gestor de Tráfego.
- Calendário do Social Media em modo manual.
- Banco de Ideias, Marca, Campanhas, rota Novo Post, Chat Mídia e planejamento mensal com IA ficam ocultos/bloqueados sem `social_media_ia`.
- A tela de calendário deixa explícito que o modo manual não depende de configuração de IA.

### Scale

Tudo do Performance, mais:

- Gestor de Tráfego IA completo.
- Social Media IA completo e todas as funções avançadas do módulo.

## UI / apresentação implementada

- Título interno da grade alterado para `Planos e assinaturas`.
- Entregáveis agrupados em blocos compactos por área de produto.
- Planos superiores usam herança visual (`Tudo do plano anterior`) para evitar listas gigantes.
- Travessão removido do texto de bônus.
- Economia calculada por plano contra o mensal:
  - valor de referência = preço mensal do mesmo plano × meses totais de uso;
  - economia total = valor de referência − valor cobrado no ciclo;
  - meses de cortesia entram no valor de referência e seu valor também é mostrado separadamente.

## Arquitetura aplicada

- `src/lib/billing/plan-catalog.ts` é a matriz canônica de apresentação e entitlements.
- `effectiveEntitledModules` usa a matriz canônica do plano para assinaturas ativas, evitando divergência entre card e acesso mesmo se `workspace_modules` estiver desatualizado.
- Gates granulares:
  - `trafego_automacoes`: Performance e Scale;
  - `social_calendar`: Performance e Scale;
  - `trafego_ia`: somente Scale;
  - `social_media_ia`: somente Scale.
- A rota pai do Gestor de Tráfego libera apenas `/automacoes` para quem tem `trafego_automacoes`; as demais rotas exigem `trafego_ia`.
- Social Media diferencia `social_calendar` de `social_media_ia`; rotas diretas de Campanhas e Novo Post exigem Scale.

## Auditoria dos itens adicionais

- `configuração materializada`: busca direta no repositório por `materializada`, `materializado`, `materialized` e pela expressão completa não encontrou texto, identificador ou componente correspondente na `main`. Portanto não existe remoção segura a fazer no código desta task. Se essa informação ainda aparecer visualmente no produto, tratar como bug visual separado com reprodução/screenshot, sem reabrir a matriz de planos.
- `integration encryption key`: o problema estrutural relacionado ao escopo de planos foi resolvido separando o calendário manual dos controles de IA. Performance não precisa de entitlement de IA para operar o calendário manual. Nenhuma credencial foi alterada.
- Banco conectado: foi observada divergência entre tabelas legadas `platform_plans`/`platform_plan_modules` e a camada atual de billing (`plans`, `plan_prices`, `subscriptions`, `workspace_modules`). Como os testes/build e o código atual usam a camada canônica versionada, nenhuma mutação ad-hoc foi feita no banco. Qualquer problema de deploy/schema deve ser tratado como task de infraestrutura separada, não como pendência desta matriz de produto.

## Critérios de aceite

1. [x] Cards mostram Start/Growth/Performance/Scale com entregáveis corretos e compactos.
2. [x] Mensal, trimestral, semestral e anual usam a mesma matriz de entregáveis.
3. [x] Preços e limites de usuários/WhatsApp permanecem inalterados no diff.
4. [x] Economia é calculada contra o mensal e inclui o valor dos meses de cortesia.
5. [x] Performance fica restrito às automações executáveis de tráfego e ao calendário do Social Media; funções completas de IA permanecem no Scale.
6. [x] Start não recebe Agent AI ou recursos de grupo definidos para Growth.
7. [x] A grade exibe `Planos e assinaturas` no plural.
8. [x] Testes de matriz, regressões, lint relevante e builds de produção passaram na CI.
9. [x] Regra permanente de escopo versionado para novas tasks registrada no projeto.
10. [x] Implementação sincronizada sobre a `main` atual sem sobrescrever a Dashboard V3.

## Fora de escopo preservado

- Alterar preços.
- Alterar limites de usuários ou WhatsApp.
- Construir o Gestor de CRM.
- Alterar integrações/credenciais por fora do GitHub.
- Corrigir eventual divergência de schema/deploy do Supabase sem evidência de falha do ambiente.

## Evidências de validação final

PR final: `#61`.
Merge em `main`: `da21d9bca1831a2ce1ee0760a718b75b28523345`.

GitHub Actions executadas novamente sobre a `main` que já continha Dashboard V3:

- `Planos final CI`, run `31447765518`: sucesso.
  - regressões de billing: sucesso;
  - production build: sucesso.
- `Social Media CI`, run `31447765557`: sucesso.
  - testes de publicação: sucesso;
  - regressão Home: sucesso;
  - lint Social Media/Home: sucesso;
  - production build: sucesso.
- `Mkton CRM Config CI`, run `31447765522`: sucesso.

## Encerramento

**Progresso: 10/10 critérios concluídos — 100%.**

A etapa Planos e assinaturas / entregáveis está tecnicamente encerrada. O próximo passo é somente teste visual/funcional do usuário. Bugs encontrados nesse teste devem abrir nova task de correção com escopo próprio, sem alterar esta matriz canônica sem nova decisão de produto.
