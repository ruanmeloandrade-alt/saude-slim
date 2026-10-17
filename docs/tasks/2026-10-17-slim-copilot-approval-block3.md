# Saúde Slim: bloco 3 do Copiloto com aprovação real

## Estado: 🟢 publicado; 🟡 pausa para conferência do usuário

Data: 17/10/2026. Repositório exclusivo ruanmeloandrade-alt/saude-slim. Branch de trabalho fix/slim-copilot-approval-block3-20261017, base 792e2a9fc0491cbd1bc4df7ec2fccb7bff174573. Produção restauracao/sistema-completo-20261014. Supabase vyzvfcgpjjzvcjegzzza, workspace c49945db-1960-461a-9339-a43b8403bdd9.

## Continuidade e autorização

O usuário confirmou em 17/10: “iniciou o bot! fiz o teste aqui. segue para as proximas tasks”. Pediu semáforo sempre com emojis. Permanece a execução de um bloco por vez, com pausa ao concluir. A rodada do Copiloto já foi aprovada anteriormente conforme docs/tasks/2026-10-16-slim-approved-history-copilot.md; não se solicita a mesma autorização novamente.

Não foi localizada uma definição literal dos blocos 3/4 na documentação ou contexto recuperado. A decisão atual é concluir a próxima frente coesa do Copiloto e, após conferência, seguir para entrega/endereço/frete. Não se apresenta essa sequência como recuperação de uma lista ausente.

## 🟢 Teste real do bloco 2 localizado

O usuário moveu seu contato controlado e confirmou que o bot iniciou. Consulta somente leitura em 17/10 às 22:41 UTC:

- Evento moved 8832d2ea-0f2b-486a-8254-22de95099a63, criado às 22:33:11 UTC, status dispatched, uma tentativa, destino Em atendimento no funil Vendas.
- Job 77bf038c-7a37-4f19-bedb-1bc26f5135ef, vinculado ao mesmo evento e ao SalesBot Emprestimos ativa IA (7208c558-d4df-4591-b758-3864137d995a), status done, uma tentativa, concluído às 22:33:29 UTC.
- Execução 1df3a006-62a5-4871-bf08-c65efa83f21e, do mesmo contato e SalesBot, iniciada às 22:33:21 UTC e finalizada às 22:33:28 UTC, status finished, sem erro. Este run do worker não possui actor_user_id/request_id; a correlação usa evento, contexto do job, contato, bot e intervalo, sem atribuir campos de auditoria ausentes.
- Nenhum evento ou job pendente na consulta. A movimentação anterior, sem gatilho aplicável, foi finalizada como skipped.
- Esta evidência confirma o cenário movimento → gatilho → início do bot. Não equivale a teste real de criação/lote ou mídia.
- SalesBot → IA individual permanece comprovado pelo teste real de 16/10 já documentado no bloco 1.
- IA autônoma em grupos permanece retirada; SalesBots e gatilhos são preservados.

## Objetivo

O Copiloto deve propor ações concretas, apresentar seus alvos e efeitos e executar somente após uma decisão explícita do operador, validada no servidor. A interface global existente permanece como entrada, com continuidade entre páginas e isolamento por empresa e operador.

## Diagnóstico confirmado

A montagem global é aplicada por scripts/apply-slim-global-history.mjs. A flag approvalRequired enviada pelo navegador não constitui controle no servidor. O catálogo atual inclui escrita direta de etapa e ferramentas CRM mutáveis; acrescentar apenas um cartão não fecharia essas entradas. AiAgentChat não exibe nem resolve propostas e salva somente texto no histórico. O cache de histórico/chat também precisa incluir o operador.

## Dentro deste bloco

1. Catálogo explícito do Copiloto: consultas reais autorizadas e ferramentas que apenas preparam propostas de movimentação de etapa, envio de texto e controle de SalesBot, conforme as operações existentes permitirem confirmação segura. Remover do catálogo efetivo as escritas legadas que não passam pelo mecanismo, inclusive convites/permissões e expediente.
2. Proposta persistida, de conteúdo imutável, vinculada à empresa, solicitante, alvo, parâmetros e versão/estado relevante; vencimento e resultado auditável.
3. Endpoints separados para listar/conferir, aprovar e rejeitar; o modelo não recebe a ferramenta de aprovação. O navegador envia identidade da proposta e decisão, sem substituir conteúdo/destinatário.
4. Revalidar autenticação, empresa ativa, operador, permissão e estado relevante antes de executar. Mudança de alvo/estado exige nova proposta. Movimentação de etapa deve usar a RPC atômica existente e declarar a possibilidade de disparar os gatilhos já configurados.
5. Repetições da mesma aprovação recuperam o mesmo resultado. Efeito externo sem confirmação fica incerto e não é reenviado automaticamente. Rejeição não produz o efeito proposto. A aprovação e o recibo não dependem de instruções no prompt nem do histórico de texto.
6. Cartões com ação, alvo, conteúdo/canal quando aplicável, alterações, efeitos e eventuais custos; botões Aprovar, Rejeitar e Conferir resultado, estados claros e recuperação após reabrir.
7. Consulta de estoque e relatório com origem, período/filtros e limites reais, sem apresentar estimativa CRM como receita ERP.
8. Validação isolada de permissões, troca de empresa/operador, aprovação duplicada, conflito de estado, rejeição, timeout e recuperação; build completo em cópia isolada e publicação somente após aprovação técnica.

## Fora deste bloco

Não iniciar checkout/endereço/frete ou outras frentes durante esta entrega. Não reabrir Mini-Inbox, Editar/Excluir pedidos, segurança/convites, unicidade global nem migrações anteriormente bloqueadas. Não criar credenciais, alterar DNS/infraestrutura ou usar outros projetos, Lovable, Vercel ou GitHub Actions. Cora permanece congelado.

Não executar testes que movam leads reais, iniciem bots, enviem WhatsApp, criem contatos/pedidos de QA ou modifiquem dados comerciais de produção. O teste confirmado foi feito pelo usuário, não pela equipe. Não chamar testes de código/SQL de homologação visual autenticada.

## Áreas e divisão de trabalho

- UI: src/components/ai-agent/AiAgentChat.tsx, cartões específicos, SupportRobot e transform global.
- Servidor: src/routes/api/ai-agent/chat.ts, suporte do Copiloto, catálogo explícito, endpoints e contratos novos.
- Banco: migração aditiva exclusiva para propostas/decisões/recibos, se necessária, criada pela CLI, versionada e testada antes de aplicar.
- Integração: gates em scripts/apply-salesbot-save-contract.mjs, testes focados, docs/OPERATION_STATUS.md e este registro.

Nenhuma modificação do runtime foi feita antes deste escopo.

## Critérios de aceite e pausa

🟢 Pedir uma ação cria proposta sem executar a ação. Aprovar executa o alvo/conteúdo exibidos uma vez. Rejeitar não executa. Proposta alterada, vencida ou de outra identidade é recusada. Reabrir permite conferir o mesmo resultado.

🟢 Build/regressões e banco isolado aprovados; publicação com deployment SUCCESS, healthcheck e leitura pós-publicação. Manter limites explícitos do teste autenticado e das integrações externas.

🟡 Ao concluir, atualizar o semáforo completo com emojis e pausar para o usuário conferir o Copiloto antes de iniciar o bloco seguinte.

## Implementação e decisões verificadas

O escopo foi registrado em c383d75f74d39369e7223676ea4fa43ed6c5dfcd antes do código. O catálogo efetivo de support_robot contém 11 consultas e quatro ferramentas propose_*; nenhuma ferramenta de aprovação ou execução é entregue ao modelo. Os endpoints de decisão recebem somente empresa, operador, ID, versão e approve/reject. Autenticação e empresa ativa são lidas sem reparo automático de perfil ou membership.

As propostas duram 15 minutos e preservam conteúdo, destinatário, canal, versão e estado relevante. O ID de preparação é estável para a mesma mensagem humana e argumentos. Repetir uma aprovação consulta o recibo já existente. Mudar contato, etapa, vínculo do funil, configuração de gatilhos, bot ou run invalida a proposta correspondente. Uma nova proposta é necessária quando os dados relevantes mudam.

A migração aditiva 20261017225228_slim_copilot_approval_ledger.sql foi gerada pela CLI. Acrescenta somente o ledger privado de propostas e auditoria e seus RPCs. As funções públicas são SECURITY INVOKER; helpers privados limitam-se a autenticação, locks, leitura e gravação do ledger. Mover etapa e controlar SalesBot reutilizam as funções de negócio existentes sob a identidade autenticada. A movimentação e seu recibo são transacionais: falha ao guardar o recibo desfaz também lead e outbox. Não há backfill, seed, job novo nem ampliação de permissões das tabelas comerciais.

O texto usa uma reserva persistida obtida após aprovação, uma única requisição Evolution com prazo de 25 segundos, corpo limitado a 64 KB e redirecionamento desativado. Antes do POST, reconfirma destinatário completo, sessão original, empresa, operador e bloqueio de contato. Não busca mídia. Exige ID do WhatsApp para confirmar envio e registra os dois históricos. Se o histórico local falha após o provedor confirmar, conserva o ID e informa a pendência sem reenviar. Resposta perdida ou reserva sem recibo final fica incerta; nenhuma repetição automática é permitida. O service role apenas finaliza o recibo dessa reserva, sem aprovar proposta ou escrever dados comerciais por esse RPC.

Movimentar e iniciar bot declaram a possibilidade de mensagens e IA individual conforme os gatilhos e blocos salvos. Depois da aprovação, o processamento segue a configuração vigente do runtime existente. Parar afeta somente o run exibido. O envio de texto não altera a sessão de IA. Grupos não são alvos dessas novas propostas.

O histórico do Copiloto usa IDs estáveis, grava usuário antes da resposta e carrega as últimas 100 mensagens em ordem cronológica. As propostas são recuperadas do ledger e independem do texto ou dos tool parts. Consultas de estoque usam o catálogo existente; relatório usa pedidos de slim_orders e separa cancelados/pagos/pendentes, em centavos, com período UTC e origem declarados.

## Verificações técnicas deste bloco

Todos os cenários abaixo usam dados sintéticos, PostgreSQL em memória e provedor simulado. Nenhum teste acessa credenciais reais ou envia WhatsApp.

| Gate | Resultado atual | Cobertura relevante |
|---|---|---|
| test-slim-copilot-text.mjs | 🟢 23/23 | Identidade, alvo, sessão, bloqueio de contato, único POST, prazo, recibo, duplicata de webhook e histórico parcial. |
| test-slim-copilot-backend.mjs | 🟢 33/33 | Catálogo, autorização, preparação estável, claims, mensagens não confiáveis, isolamento e persistência de histórico. |
| test-slim-copilot-postgres.mjs | 🟢 70/70 | Grants reais, RLS, rejeição, vencimento, mudança de estado, efeitos atômicos, rollback, reserva única e finalização exclusiva do servidor. |
| test-slim-copilot-integration.mjs | 🟢 9/9 | Ferramenta → RPC real → aprovação → ação/adapter → históricos → recibo; resposta perdida sem repetição. |
| test-slim-copilot-ui.mjs | 🟢 34/34 | Cartões renderizados, decisão duplicada, perda de resposta, troca de identidade e recibos preservados. |
| test-slim-global-history.mjs | 🟢 17/17 | Integração global, contexto autenticado e transform idempotente; gate anterior preservado. |
| Build completo e regressões | 🟢 Aprovado em cópia isolada | 169 verificações novas e regressões anteriores passaram. Compilação final concluída às 23:24 UTC; bundles cliente, servidor e Nitro gerados. Encerramento de stream ao desmontar limitado ao Copiloto. |

## Publicação e limites

Código e SQL versionados em 20930d8736262127c163eccea46e8341f9e9a361 após build aprovado. A árvore do GitHub foi comparada exatamente ao conteúdo local testado. Migração aplicada às 23:26 UTC; branch de produção avançada com comparação do SHA esperado, sem force. Railway b3d7b984-6f3a-47f2-8837-327751865100 terminou SUCCESS às 23:31 UTC, com healthcheck 1/1 aprovado às 23:30:57 UTC. A homologação visual autenticada do Copiloto e qualquer ação real pertencem à conferência do usuário após a pausa deste bloco.

### Leitura anterior à migração

Em 17/10 às 23:22:52 UTC: 25 leads, um pedido ERP e nenhum evento de etapa pendente. O ledger e as funções do Copiloto ainda não existiam. Hash do estado de leads 7282b4df6807dd873ae8710c89877b16; hash das funções existentes de movimentação e controle de bot 655e2bd6cbd760520cc70967d201c328. A aplicação e os outros três serviços estavam online, sem problemas ou operações pendentes. Estas leituras não executaram ações de negócio.

### Migração instalada e permissões conferidas

A migração slim_copilot_approval_ledger foi instalada pelo MCP com versão de banco 20261017232621; corresponde ao arquivo CLI 20261017225228_slim_copilot_approval_ledger.sql no commit funcional. A leitura posterior confirmou cinco funções públicas SECURITY INVOKER: create/decide/get/list para authenticated, finish_text somente para service_role e nenhuma execução anônima. As duas tabelas privadas possuem RLS e nenhum grant direto de leitura/escrita para anon, authenticated ou service_role. Foram encontradas zero propostas e zero entradas de auditoria; não houve preparação ou execução de QA em produção.

Às 23:26:53 UTC, os 25 leads, um pedido e os hashes de estado e funções existentes eram idênticos à leitura anterior; nenhum evento de etapa pendente. Os avisos de segurança anteriores permaneceram iguais. O advisor acrescentou dois registros informativos de [RLS sem políticas](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy) para o ledger privado: acesso direto é intencionalmente negado e verificado, e a gravação ocorre apenas pelos helpers autenticados. Não foi criada política permissiva para silenciar o aviso. Os quatro avisos de [RPCs antigas com SECURITY DEFINER](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable) e a [proteção contra senhas vazadas](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection) já existiam e não integram este bloco.

PGlite executa um único backend: os testes verificam transações, permissões, mudanças de estado e repetição, mas não constituem carga concorrente de múltiplas conexões. Em eventual rollback da aplicação, preservar o ledger e seus recibos; uma reserva incerta não deve voltar à fila de envio.

## 🟢 Publicação concluída em 17/10/2026

Versão funcional 20930d8736262127c163eccea46e8341f9e9a361, Railway b3d7b984-6f3a-47f2-8837-327751865100. Os quatro serviços ficaram online, cada um com uma réplica, zero réplicas travadas e nenhuma operação pendente. O servidor iniciou normalmente e escutou a porta esperada. O worker contínuo existente do Inbox é inicializado pelo entrypoint compilado e consulta a fila a cada cinco segundos; a ação do Copiloto confirma o enfileiramento e não antecipa uma confirmação de mensagem do bot.

Leitura pós-publicação às 23:32:09 UTC: Supabase respondeu, 25 leads, um pedido, zero eventos pendentes, zero propostas e zero entradas de auditoria do Copiloto. Os hashes de estado dos leads e das funções existentes permaneceram iguais aos registrados antes da migração. Nenhum lead foi movido, bot iniciado ou texto enviado pela equipe para homologar este bloco.

## 🟡 Conferência solicitada e pausa

1. Atualizar a página e abrir o Copiloto na lateral direita. Consultar estoque ou relatório de vendas confirma a entrada do chat e suas consultas.
2. Pedir uma proposta de mudança de etapa para o contato controlado, identificando claramente o cliente e a etapa. O cartão deve mostrar alvo, mudança e possíveis gatilhos antes de qualquer execução.
3. Rejeitar uma proposta e verificar a confirmação visível. Para conferir a aprovação real, preparar outra proposta para o contato controlado e decidir pelo botão Aprovar e executar.
4. Fechar e reabrir o Copiloto; conferir o resultado persistido da mesma proposta. Uma resposta incerta não autoriza reenvio automático.

A publicação técnica está concluída. A homologação visual autenticada e ações reais ainda não foram declaradas concluídas. Pausar aqui conforme solicitado; a próxima frente é entrega/endereço/frete, somente após a revisão do usuário. Inbox/mídias e os bloqueios anteriores continuam com seus próprios estados no semáforo. IA autônoma para grupos permanece retirada.
