# MktOn — FAQ, Documentação Funcional e Copiloto

Data: 2026-08-11
Status: **implementação concluída — 15/15**; validação executável externa bloqueada antes dos steps do GitHub Actions
Escopo fechado: **15 tarefas / 5 blocos de 3**
Branch: `agent/faq-documentacao-copiloto`
PR: **#96**

## Objetivo
Finalizar a Central de Ajuda/FAQ, criar uma Central de Documentação funcional/tutorial da MktOn baseada no sistema real e consolidar o Copiloto global da plataforma.

O Copiloto permanece disponível continuamente. Enquanto existir configuração obrigatória do plano ainda incompleta, prioriza implementação, configuração, diagnóstico e ativação. Quando o checklist exigido pelo plano estiver concluído, o mesmo Copiloto passa a atuar como assistente normal de uso, suporte e orientação. **Não existe mais corte fixo de 20 dias.**

## Regras canônicas
1. Ler o código real antes de documentar ou alterar um módulo.
2. Não documentar mock, ideia futura ou comportamento inexistente como recurso disponível.
3. FAQ responde dúvidas rápidas; documentação ensina operação completa.
4. Preservar mecanismos existentes do Copiloto/chat e evoluir antes de recriar.
5. Não inventar integrações, planos, permissões ou regras comerciais.
6. O Copiloto é permanente: `implementation` enquanto faltar configuração obrigatória do plano; `assistant` quando a implementação estiver concluída.
7. Acionador discreto `Copiloto` colado à direita durante navegação autenticada; sem mascote/imagem concorrente.
8. O Copiloto usa **exclusivamente a integração OpenAI do próprio workspace**. O endpoint `support_robot` rejeita fallback/provider interno.
9. Cobrança/mensalidade atrasada não faz parte do papel definido para o Copiloto.
10. A documentação possui entrada pública e conteúdo público de Afiliados sem expor superfícies administrativas privadas.

# Escopo de produção

## Bloco A — Auditoria e FAQ — T1–T3 — ✅ 3/3
- `/ajuda` auditado e reaproveitado.
- FAQ centralizado em `src/lib/help-faq.ts` com 12 categorias, busca, atalhos, estado vazio e responsividade.
- Orientação de WhatsApp corrigida para não tratar QR Code como método universal.
- Contrato: `src/lib/help-faq.test.ts`.

## Bloco B — Fundação da Documentação — T4–T6 — ✅ 3/3
- inventário real em `src/lib/documentation-catalog.ts`;
- Central `/documentacao`;
- template padrão em `src/components/documentation/DocumentationArticleView.tsx`;
- status explícito para acesso/plano/integração/admin;
- contrato: `src/lib/documentation-catalog.test.ts`.

## Bloco C — Documentação dos módulos — T7–T9 — ✅ 3/3
Documentados CRM/Funis, Leads/Públicos, Formulários, Empresas, Produtos, Arquivos, Inbox, Automações/SalesBot, Gestor de CRM/IA, Dashboard, Workflow, Calendário, Notas, Tracking, Configurações, plano/faturamento/limites, segurança, Gestor de Tráfego, Social Media, Integrações, Faculdade MktOn e áreas administrativas pertinentes.

Complementos:
- `src/lib/documentation-admin-catalog.ts`;
- `src/lib/documentation-start-catalog.ts`;
- `src/lib/documentation-admin-catalog.test.ts`.

## Bloco D — Conexões, receitas e diagnóstico — T10–T12 — ✅ 3/3
- 7 mapas de conexão;
- 7 receitas de implementação;
- 7 diagnósticos guiados;
- navegação `Módulos | Conexões | Receitas | Diagnóstico`;
- arquivos `src/lib/documentation-guides.ts`, `src/components/documentation/DocumentationGuidesView.tsx` e `src/lib/documentation-guides.test.ts`.

## Bloco E — Copiloto, documentação pública e fechamento — T13–T15 — ✅ 3/3 de implementação

### T13. Consolidar Copiloto permanente — ✅ concluída
- reaproveitado chat global e histórico existentes;
- removidos mascote/imagens do acionador;
- botão textual `Copiloto` colado à direita;
- fase `implementation` enquanto houver item obrigatório do plano pendente;
- fase `assistant` somente quando o checklist real daquele plano estiver completo;
- checklist deriva dos entitlements canônicos `Start/Growth/Performance/Scale`, sem cobrar módulos não contratados;
- integração OpenAI do próprio workspace é requisito do Copiloto;
- endpoint `support_robot` chama `createWorkspaceAiProvider(..., { requireWorkspaceOpenAI: true })`, impedindo fallback/provider interno;
- Copiloto permanece visível sem OpenAI e direciona para `/integracoes`;
- handoff humano preservado;
- sem fluxo de cobrança/mensalidade atrasada.

Arquivos principais desta correção final:
- `src/components/SupportRobot.tsx`;
- `src/lib/support-robot.functions.ts`;
- `src/lib/support-robot.server.ts`;
- `src/lib/ai-agent/workspace-provider.server.ts`;
- `src/routes/api/ai-agent/chat.ts`.

### T14. Regressão contratual + documentação pública — ✅ implementação concluída
- `/documentacao` liberada como rota pública;
- biblioteca pública filtra conteúdos `admin_only`;
- artigo público `Programa de Afiliados` sem congelar percentuais/regras comerciais antigas;
- homepage ganhou extensão de rodapé `Recursos → Documentação | Afiliados`;
- rotas públicas previstas preservadas no AuthGate;
- contratos de FAQ/documentação/Copiloto permanecem versionados para execução quando o runner voltar.

### T15. Auditoria final e handoff — ✅ concluída
- escopo e PR atualizados com a regra definitiva do Copiloto;
- PR permanece draft/mergeable;
- conflito conceitual com PR #101 corrigido: a #101 voltou a preservar o ponto de montagem global do `SupportRobot`, porque esse é o nome técnico usado pelo Copiloto aprovado. A regra é remover somente apresentação/mascote legado concorrente, não o componente do Copiloto.
- merge, quando realizado, deve preservar histórico normal e não apagar trabalho paralelo.

## Validação executável / ambiente
O GitHub Actions continua sendo disparado, porém os runs mais recentes encerram o job `validate` antes de qualquer step (`steps: null`) e sem log de execução disponível.

Consequências:
- não existe falha de TypeScript, teste ou build registrada nesses runs — os comandos não chegaram a executar;
- `npm test` e `npm run build` não podem ser declarados verdes sem execução real;
- publicação segura na `main` continua condicionada a reexecutar o CI quando o runner estiver disponível ou a aceitar conscientemente publicar sem build executado.

## Progresso atual
- Total: **15**
- Feitas em implementação: **15**
- Em andamento: **0**
- Restantes de implementação: **0**
- Implementação funcional: **100%**
- Validação externa pendente: **GitHub Actions sem steps executáveis**
