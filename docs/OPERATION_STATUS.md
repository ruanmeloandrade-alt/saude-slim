# Saúde Slim: semáforo de produção

Checkpoint: 15/10/2026, após publicação do escopo aprovado de interface, preços, fornecedores e autorização do Copiloto.
Último código funcional publicado e conferido: `f352e12141f2e6f508f109200b5de239d7c7943b` (inclui `eef0379`).
Railway: deployment `3d080296-25c1-45d6-83bc-34bb563f5606`, SUCCESS. Healthcheck aprovado em `2026-10-15T14:33:21Z`; estado Online, uma réplica rodando, nenhuma réplica travada e nenhum trabalho pendente na consulta posterior.
Este checkpoint é documental. Não declara uma nova alteração de código além do deployment verificado acima.

Destino exclusivo: `ruanmeloandrade-alt/saude-slim`, branch `restauracao/sistema-completo-20261014`, Supabase `vyzvfcgpjjzvcjegzzza`, serviço `saude-slim-web`.
Branch desta entrega: `fix/slim-approved-shell-money-suppliers-20261015`.

## Legenda

🟢 Entrega técnica delimitada publicada e verificada no nível descrito.
🟡 Código publicado ou trabalho parcial, mas ainda sem homologação integral do fluxo.
🔴 Implementação pendente ou bloqueio explícito.
O verde de uma correção não equivale à aprovação do módulo inteiro. Banco, testes de código, geometria isolada e healthcheck não substituem interface autenticada, resposta real de IA ou entrega WhatsApp.

## Entregas técnicas deste checkpoint

| Recorte | Estado | Evidência e limite |
|---|---|---|
| Escrita no GitHub | 🟢 Restabelecida nesta sessão | Branch, escopo, código e commits gravados pelo conector. A indisponibilidade de escrita da sessão anterior não se aplica a este checkpoint. |
| Interface compartilhada | 🟢 Publicada | Dialog, Sheet, Drawer, AlertDialog e Select com hierarquia de camadas; wrappers personalizados de produto também ajustados; limite de altura/rolagem. A página real ainda precisa de navegação autenticada. |
| Menu e navegação | 🟢 Publicados | Botão discreto apenas com ícone junto a Operação Saúde Slim; recolhimento 272/72px sincronizado com espaço do conteúdo; preferência persistida; Vendas renomeado Gestão ERP; Disparo em massa no CRM imediatamente após Inbox. Quinze destinos e quatro itens desabilitados da Fase 2 preservados. |
| Cérebro IA: alinhamento | 🟢 Publicado | Retirada da margem adicional de 272px, que se somava ao espaço do menu. Formulários e recursos existentes preservados. Não é uma implementação de indexação/RAG. |
| Produtos: centavos | 🟢 Contrato publicado e banco verificado | Entrada decimal em texto preserva vírgula; validação antes de salvar; serialização exata com duas casas; formato visual com centavos. Cadastro/importação/promoção/custo seguem validação. Banco já possui numeric com duas casas. Não foi alterado preço real ou histórico. |
| Fornecedores: origem correta | 🟢 Correção publicada e banco verificado | Cadastro deixa de exigir provider mkton inexistente; usa origem manual local. Sem criar outra origem nem acessar projeto original. Campo de origem é opcional no schema. Atualização exige retorno de registro, custos validam fornecedor/produto da mesma empresa. |
| Copiloto: chamada de autorização revogada | 🟢 Correção de código publicada | Removida chamada à RPC pública is_workspace_member sem EXECUTE; validação usa o mesmo cliente autenticado do bearer e suas políticas RLS, identidade, workspace e validade do vínculo. Nenhuma permissão ou chave alterada. Resposta real do provedor ainda não comprovada. |

## Semáforo do escopo aprovado

| Ordem | Frente | Estado funcional | Feito / pendência efetiva |
|---|---|---|---|
| 01 | Modais/drawers/menu/Cérebro | 🟡 Publicado, falta homologação UI | Correções acima no site. Falta conferir todas as janelas e seletores pela sessão autenticada, desktop/mobile e menu expandido/recolhido. |
| 01a | Gestão ERP e posição de Disparo | 🟡 Publicado, falta homologação UI | Estrutura e rotas verificadas em código; não afirmar teste manual no site. |
| 02 | Precisão monetária | 🟡 Publicado no cadastro | 0,01 / 19,99 / 1.234,56 e promoção 0,01 gravados e relidos sob authenticated em sonda revertida. Falta validar fluxo completo do checkout/documento com este contrato. |
| 03 | Fornecedores | 🟡 Publicado, falta homologação UI | Cadastro/edição/custo verificados em banco e correção do consumidor publicada. Logo, relações e cenários integrais de interface continuam sujeitos a homologação. |
| 04 | Checkout real de Pedidos | 🔴 Próximo bloco de implementação | Cliente existente/novo, múltiplos itens, quantidades, descontos e forma/situação de pagamento. Ainda não implementado nesta entrega. |
| 05 | Pedido → Histórico → Dashboard → Estoque | 🔴 Próximo bloco de implementação | Transação, idempotência, baixa/estorno e reconciliação do pedido anterior continuam pendentes. Nenhum pedido ou estoque real alterado nesta entrega. |
| 06 | Copiloto com chave própria | 🟡 Correção publicada | Erro de autorização localizado e consumidor corrigido. Falta resposta real OpenAI e persistência ponta a ponta. Não pedir nova chave nem afirmar integração completa a partir dos testes locais. |
| 07 | Métricas de SalesBots e relatórios | 🔴 Pendente | Executados/ativos/conversões e percentuais do relatório ainda precisam ser reconciliados com registros reais. Nenhuma métrica foi fabricada. |
| 08 | PDF do pedido e emissão fiscal | 🔴 Pendente | Documento comercial associado à venda e integração fiscal real no contrato aprovado. Não tratar PDF comercial como NF autorizada. |
| 09 | Envio opcional do documento no WhatsApp | 🔴 Pendente | Confirmação, destinatário correto, vínculo do documento e resultado do envio. Nenhuma mensagem enviada nesta entrega. |
| 10 | Identidade Saúde Slim em todo o sistema | 🟡 Parcial | Navegação e erros tocados nesta entrega usam Saúde Slim. Revisão global de textos/relatórios ainda pendente; identificadores internos preservados. |
| 11 | Configurações e homologação anterior | 🔴 Backend de segurança parcialmente bloqueado | Pacote de segurança/convites bloqueado anteriormente continua não aplicado. Não contornado por outro meio. Demais pendências abaixo preservadas. |

## Validação realmente executada nesta retomada

- **66 verificações novas passaram no build final:** 33 monetárias/origem do fornecedor, 20 de integração do código/interface e 13 de autorização do chat. As rotinas anteriores de IA, Inbox, salvamento manual/120s, Histórico, Dashboard, Públicos, Configurações e tracking permaneceram no prebuild.
- **Banco real, sonda autenticada:** catálogo/produto temporário com preços 0,01, 19,99 e 1.234,56, promoção 0,01; fornecedor com origem manual própria; edição/releitura; custo 19,99; fornecedor independente sem origem. Todos os registros revertidos e ausência conferida. Nenhum pedido criado.
- **Leitura de catálogo do banco:** products.price/promo_price são numeric(14,2); custo numeric(12,2); origem da empresa nullable; fonte manual própria existente. public.is_workspace_member sem EXECUTE para authenticated explica a chamada antiga do chat. Essa leitura não alterou privilégios.
- **Teste de autorização no banco:** uma sonda adicional com papel autenticado foi bloqueada pela segurança da ferramenta. NÃO executou/NÃO passou e não foi repetida por outro meio. A correção do consumidor do Copiloto foi testada em código; não declarar autorização ponta a ponta homologada.
- **Pacote local anterior:** 26 testes do pacote, duas verificações de sintaxe e 65 verificações geométricas em Chromium isolado foram reexecutados. São ensaios da base preparada, não da interface React/Radix autenticada em produção; não somar como novos testes ponta a ponta.
- Primeiro build `fb0c346e-bdab-431e-ba19-78da16c5e577` falhou antes de publicar por erro de sintaxe no transporte simulado de um teste. Corrigido em f352e12. Build seguinte passou e publicou; versão anterior permaneceu disponível durante a falha.
- **Pós-publicação:** SUCCESS, healthcheck aprovado, estado Online e uma réplica em execução. Não houve teste autenticado de navegador, resposta real OpenAI ou envio real WhatsApp nesta retomada.

## Pendências anteriores preservadas

Home/Histórico: paginação e classificação publicados antes; coerência com novos pedidos ainda pendente.
Dashboard: carregamento comercial e cinco fontes restaurados anteriormente; coleta real do pixel/formulário e cenários completos de indicadores não homologados.
Públicos/Disparos: filtros, fila, progresso/cancelamento publicados antes; envio real e execução completa da fila ainda não homologados; filtro legado de silêncio usa atualização do lead.
CRM/Funil/Automações: persistência de etapas e reserva de execução publicadas; grupos/workflow/Meta e cenários completos pendentes.
Inbox: envio SalesBot confirmado anteriormente pelo usuário; IA, anexos e cenários completos não homologados.
Cérebro: armazenamento existente, agora layout corrigido; ingestão/indexação/RAG e bloqueio antes do envio permanecem no escopo funcional anterior.
Configurações: validação/gravação e indicação honesta de segurança publicadas antes; backend de segurança/dispositivos/convites parcialmente bloqueado. MFA/passkeys/recuperação não declarados prontos.

## Continuidade

Próximo bloco técnico: checkout consistente, pedido/histórico/Dashboard/estoque, mantendo pendências de validação das entregas publicadas visíveis. O arquivo registra o checkpoint, não trabalho do assistente em segundo plano.
Escopo desta entrega: `docs/tasks/2026-10-15-slim-approved-shell-money-suppliers.md`.
Diagnóstico de Pedidos: `docs/tasks/2026-10-15-slim-orders-audit.md`.
Escopos anteriores de Públicos, Configurações e tracking permanecem em docs/tasks.
Preservados main, DNS, Evolution, projetos originais MktOn/Harpia/MCP, chaves, rotas e salvamento manual/120s. Nenhuma migration aplicada nesta entrega. Sem GitHub Actions, Vercel ou agente Lovable.
