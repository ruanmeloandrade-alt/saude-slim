# Saúde Slim: semáforo de produção

Checkpoint 15/10/2026: integração revisada de checkout, histórico, resumo ERP e PDF em validação de publicação. Ainda não declarar nova versão no ar. Base operacional previamente conferida 464efa7f98f6df23db61e6b6ef5c3cb6ca6cbc70; último código funcional anterior 8b78ae0. Este checkpoint deve ser atualizado após o resultado do deployment.

Destino: ruanmeloandrade-alt/saude-slim, branch restauracao/sistema-completo-20261014; Supabase vyzvfcgpjjzvcjegzzza; serviço saude-slim-web. Preparação fix/slim-erp-final-20261015.

Legenda: 🟢 entrega delimitada publicada/verificada; 🟡 em validação ou parcial; 🔴 pendência/bloqueio. Não converter teste de lógica, banco ou healthcheck em homologação de navegador.

## Frente atual

| Recorte | Estado | Evidência e limite |
|---|---|---|
| Checkout multi-item ligado ao banco | 🟡 Aguardando build/deploy | Rota utiliza RPC autenticada existente, não o fluxo antigo de criar lead e vínculo separados. |
| Estoque por pedido e estorno | 🟡 Banco validado anteriormente, UI em publicação | Funções transacionais e RLS preservadas. Nenhum saldo real foi alterado nesta sessão. |
| Histórico e Dashboard | 🟡 Aguardando build/deploy | Mesmo registro de pedidos; cancelados excluídos dos totais; recebimento informado separado de pagamento pendente. CRM anterior preservado em bloco separado. |
| PDF por pedido | 🟡 Aguardando build/deploy | Gerado sob demanda com snapshot persistido, disponível após confirmar e no histórico; não fiscal. Sem escrita privilegiada de documento. |
| Envio opcional do PDF WhatsApp | 🔴 Pendente | Não incluído na versão revisada de menor privilégio. Nenhuma chave/canal acessado; nenhum envio. |
| Reconciliação dos pedidos anteriores | 🔴 Pendente | Valores 8,50/7,39 com item e 101 sem item não foram reescritos ou usados para ajustar saldos por suposição. |

## Validação desta sessão

37 testes locais de regras/leitores, três módulos em TypeScript strict e oito arquivos em sintaxe passaram. 63 testes do pacote de leitura anterior foram reexecutados. O prebuild inclui as regressões anteriores e 53 testes de checkout/PDF, 37 de release e 17 do contrato de integração. Aguardar logs para registrar resultado do build.

O banco já possui as três migrations do ERP confirmadas em leitura. Nenhuma reaplicação da operação antes bloqueada, mudança de permissão, rota alternativa de implantação ou nova migration nesta sessão.
A implementação revisada elimina totalmente o cliente privilegiado, acesso a credenciais, escrita direta de documentos e transporte WhatsApp do pacote anteriormente recusado. Esses efeitos não foram divididos em outra chamada: foram excluídos deste escopo de publicação e continuam pendentes.

## Demais frentes preservadas

| Área | Estado | Situação |
|---|---|---|
| Modais/menu/Gestão ERP/Cérebro alinhado | 🟡 Publicados antes | Correções de f352e12 mantidas; interface autenticada integral não homologada. |
| Preços/fornecedores | 🟡 Publicados antes | Centavos, origem manual própria e custos verificados anteriormente. |
| Copiloto | 🟡 Correção anterior | Membership corrigida; resposta real ainda não homologada. Presença global e novas ações aguardam escopo seguinte. |
| Métricas/relatórios/marca | 🟡 Publicados antes | 8b78ae0 preservado; contadores reais e marca revisada, sem percentuais fictícios. |
| Públicos/Disparos | 🟡 Parcial anterior | Filtros/fila/progresso existentes; entrega real e silêncio por histórico pendentes. |
| Funil/Clientes/Inbox | 🟡 Parcial anterior | Novos relatos de duplicação, mídia, etiquetas, grupos e compositor recebidos; ainda não implementados. |
| Cérebro/Automações | 🟡 Parcial anterior | Grupos/workflow/Meta, ingestão/RAG e cenários completos pendentes. |
| Dashboard/coleta externa | 🟡 Parcial anterior | Cinco fontes restauradas antes; pixel/formulário real não homologados integralmente. |
| Segurança/convites | 🔴 Bloqueio anterior | Pacote anterior não aplicado; não tratado como resolvido pelo ERP. |
| Emissão fiscal | 🔴 Pendente | Comprovante comercial não substitui emissão fiscal autorizada. |

## Continuidade

Confirmar build/deploy, corrigir qualquer falha e atualizar este documento. Depois concluir pendências do escopo antigo antes de apresentar e executar os novos ajustes de Inbox/Copiloto, endereço/frete e IA por prompt. A próxima rodada requer o OK separado já solicitado pelo usuário.
Escopo atual: docs/tasks/2026-10-15-slim-erp-release-review.md. Escopo/transações anteriores: docs/tasks/2026-10-15-slim-erp-integration.md. Sem alterações em main, DNS, Evolution, projetos originais, chaves ou GitHub Actions. O checkpoint não implica trabalho do assistente em segundo plano.
