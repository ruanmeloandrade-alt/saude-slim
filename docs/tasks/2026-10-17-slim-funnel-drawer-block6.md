# Saúde Slim: bloco 6 da ficha do lead com Mini-Inbox

## Estado: 🟡 escopo registrado antes da implementação

Base 9cbfca6cd3671f8b32214e9b1cabff13fc38dbd5. Branch fix/slim-funnel-drawer-block6-20261017. Produção restauracao/sistema-completo-20261014, repositório ruanmeloandrade-alt/saude-slim. Supabase vyzvfcgpjjzvcjegzzza, empresa c49945db-1960-461a-9339-a43b8403bdd9. Somente Saúde Slim.

## Pedido e autorização

Em 17/10 às 21:38 de Brasília, o usuário pediu produção contínua enquanto testa. Às 21:45, reforçou que clicar no lead do Funil deve abrir a ficha com dados do cliente e Mini-Inbox, e pediu manter/adicionar isso ao escopo e continuar. A seção 4 de 2026-10-16-slim-next-inbox-copilot-scope.md já descreve a entrega. A ordem atual reafirma a implementação e a publicação após testes, sem nova pausa de aprovação. Copiloto, gatilho Funil → SalesBot e SalesBot → IA individual continuam aceitos.

## Diagnóstico e registro da recusa anterior

A rota monta LegacyFunnelComponent; handleLeadClick ainda navega ao Inbox, no Kanban e na lista. O mesmo código aparece na última compilação publicada. A edição rápida é uma ação separada. A ficha solicitada ainda não foi integrada.

Quatro módulos de referência estão no WIP d6d84a5a7579c64d284a7266124ec013d7a7492c: SlimFunnelLeadDrawer.tsx, slim-funnel-drawer.css, slim-funnel-drawer.core.ts e slim-funnel-drawer.functions.ts. A documentação registra recusa da escrita que os conectaria ao Funil/ChatThread, sem preservar ferramenta, payload ou razão técnica. Não atribuir uma causa inventada ou tratar a autorização do usuário como ausente.

A referência não é compatível diretamente com produção: importa SlimEmbeddedChatThread, que ainda não existe, e verifica source sem o selecionar. Este bloco revisa a integração contra o Inbox atual e seus testes. Usar o fluxo normal de edição, revisão e publicação; não trocar ferramentas, endpoints ou payloads para contornar uma recusa atual. Se houver recusa, preservar o trabalho revisável e registrar exatamente a ação e a razão devolvida.

## Dentro do bloco

- Clique normal no lead abre ficha lateral no Funil; manter URL/contexto do Funil. Preservar arraste, seleção em massa e edição rápida.
- Dados atuais do contato canônico, campos personalizados, etiquetas, responsável, etapa e informações/histórico disponíveis. Preservar a edição autorizada existente, sem inventar campos ou salvar alterações ao abrir.
- Mini-Inbox reutiliza o ChatThread, consultas, compositor e envios autenticados já existentes. Nenhum transporte ou worker novo; mídia permanece sob demanda, com as proteções de tamanho, prazo e comprovante já publicadas.
- Abrir Inbox navega explicitamente para a conversa canônica. Abrir no WhatsApp Web usa telefone individual validado, em nova aba. Abrir ficha ou usar links não cria lead, move etapa nem inicia automação.
- Estados de texto, anexo/áudio preparado, gravação, transcrição e envio são informados à ficha. Fechamento/troca de lead pede confirmação para descartar rascunho ou gravação e fica impedido durante envio/transcrição. Exibir motivo ao operador. Desmontagem libera microfone, objetos temporários e listeners.
- Isolar montagem por empresa, operador e lead. Mudança de contexto encerra a ficha e limpa conteúdo anterior. Reutilizar os guards atuais no servidor: empresa obtida da autenticação, UUID de lead limitado à empresa e permissões de operador. A auditoria não encontrou justificativa para novos parâmetros de autorização ou outro backend de envio.
- Foco, teclado, Escape, rolagem e largura responsiva funcionam com o menu aberto/recolhido. A tela principal do Inbox preserva seu comportamento padrão.

## Fora do bloco

Sem migration, novos grants, mudança de RLS, sessão WhatsApp, chave, DNS ou infraestrutura. Sem reenviar pacotes recusados de pedidos, segurança/convites ou unicidade global. Sem contatos, campanhas, mensagens, grupos, pedidos, estoque ou movimentos de QA em produção. Sem IA autônoma em grupos, novas funções do Copiloto, alterações no Cora, outros projetos, Lovable, Vercel ou GitHub Actions.

## Áreas e divisão de execução

Funil legado e componente lateral/CSS; ChatThread e VoiceControls existentes com props opcionais de incorporação/estado; helpers de ficha e leitura autenticada estritamente necessários; testes sintéticos e gate de build existente. Dividir propriedade de arquivos entre agentes para não sobrepor edições. O WIP é referência de leitura, sem cherry-pick integral. Mudanças no getter de dados apenas acrescentam os campos necessários à ficha e mantêm autenticação e escopo.

## Aceite e validação

Testes do clique normal versus seleção/arraste, mesmo lead canônico ao reabrir, zero escrita ao abrir, dados e links corretos, empresa/lead inválidos, estados de fechamento, envio único, preservação do texto seguinte e limpeza do áudio. Renderização/eventos locais dos componentes reais, com transporte simulado. Verificar integração também depois dos transforms de build. Manter gates anteriores; uma compilação final em cópia isolada e uma publicação deste bloco. Confirmar Railway SUCCESS, healthcheck e serviços. Nenhum teste autenticado do usuário ou envio real será marcado como realizado pela equipe.

## Riscos e reversão

ChatThread é compartilhado: props novas devem ser opcionais e não alterar a tela principal. Os transforms existentes exigem integrar no ponto correto sem perder as correções de mídia e comprovantes. Nunca descartar rascunho por resposta assíncrona de outra conversa. Se a publicação falhar, corrigir ou reverter por novo commit, preservando dados e histórico Git.

## Execução

Escopo escrito antes de qualquer alteração de runtime deste bloco. Públicos/Disparos 9cbfca6 está em publicação independente; não aguardar conferência do usuário para desenvolver esta ficha. Registrar decisões, testes, publicação e limites neste documento.
