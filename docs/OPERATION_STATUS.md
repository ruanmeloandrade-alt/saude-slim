# MKTOn — Status Global da Operação

Última consolidação: 2026-08-11
Fonte de verdade: GitHub `ruanmeloandrade-alt/code-to-lovely-ui`, branch `main`, commits e PRs mais recentes.

## Regra de leitura

Este arquivo deve refletir o estado mais recente do código e das frentes ativas. Escopos antigos não podem ser usados como fonte isolada quando commits ou PRs posteriores já fecharam a frente.

## Core concluído / não reabrir sem bug novo

- Home / Central do Dia — concluída.
- Dashboard V4 backend real — concluída.
- Dashboard V4 configuração por gadget/KPI — concluída na PR #78; engrenagem discreta, ocultar/restaurar widgets, seletores aplicáveis e escolha de KPI com catálogo fechado por contexto.
- Central de Operações — concluída.
- Configurações e Permissões — concluída.
- Planos / preços / matriz / entitlements — concluídos; PR #82 e commits posteriores substituem escopos antigos ainda abertos.
- Login / Cadastro / Auth — concluído nas etapas auditadas.
- CRM / Funis / Leads — core concluído.
- SalesBots — core concluído.
- Agentes IA — core concluído.
- Fluxo de Trabalho — core técnico concluído; não usar o antigo bloco de Gates 2–5 como pendência ativa.
- Notas — concluída, incluindo Nota → Tarefa.
- Formulários — concluídos no core atual.
- Empresas — concluídas no core atual.
- Produtos — materializados/sincronizados no escopo atual.
- Inbox / WhatsApp Evolution — concluído no core técnico; runtime, roteamento por sessão, deduplicação, criação de lead e integrações CRM/SalesBot/Agente IA estabilizados.
- Make / n8n / Zapier / Webhook — concluídos na main.
- Social Media — core concluído após PRs #89 e #95; correções do pipeline de imagem/Marca/persistência já substituem status antigos de QA pendente.
- Logo autenticada + Chat Suporte IA + handoff para super admin + gate visual por plano — concluídos; migration aplicada em produção.
- Google Maps no domínio próprio — correção mergeada pela PR #92.
- WhatsApp Oficial / Meta Cloud API — desenvolvimento concluído. O único passo restante é homologação humana com Meta Business/WABA/número real; isso é QA externo e não deve aparecer como desenvolvimento pendente no escopo do produto.

## Frentes técnicas em execução agora

- Tracking — PR #88.
- Gestor de Tráfego — PR #93.
- FAQ / Documentação / Copiloto — PR #96.

## Melhorias adicionais / pós-core

- Partners / Afiliados — expansão pós-core.
- Robustez visual system-wide — roadmap pós-core.

## Regra permanente de Dashboard

A configuração de KPI por gadget deve ser contextual e segura:

- cada bloco possui uma lista fechada de KPIs compatíveis com sua finalidade;
- não oferecer KPIs de outro domínio apenas porque existem no catálogo global;
- preservar drilldowns, fontes reais, gates de plano e permissões;
- esconder/mostrar widgets não pode quebrar o layout nem remover a possibilidade de restaurá-los;
- mudanças visuais não podem substituir os contratos reais do backend.

## Observação sobre WhatsApp

A MarketOn possui mais de uma modalidade/conector de WhatsApp. O fechamento do WhatsApp Oficial / Meta Cloud não altera o fato de que o WhatsApp Evolution / Inbox já estava tecnicamente concluído. A etapa restante do WhatsApp Oficial é exclusivamente homologação humana externa com credenciais/WABA real.
