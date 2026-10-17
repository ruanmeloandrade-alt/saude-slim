# Saúde Slim: bloco 3 do Copiloto com aprovação real

## Estado: 🟡 escopo registrado antes da implementação

Data: 17/10/2026. Repositório exclusivo ruanmeloandrade-alt/saude-slim. Branch de trabalho fix/slim-copilot-approval-block3-20261017, base 792e2a9fc0491cbd1bc4df7ec2fccb7bff174573. Produção restauracao/sistema-completo-20261014. Supabase vyzvfcgpjjzvcjegzzza, workspace c49945db-1960-461a-9339-a43b8403bdd9.

## Continuidade e autorização

O usuário confirmou em 17/10: “iniciou o bot! fiz o teste aqui. segue para as proximas tasks”. Pediu semáforo sempre com emojis. Permanece a execução de um bloco por vez, com pausa ao concluir. A rodada do Copiloto já foi aprovada anteriormente conforme docs/tasks/2026-10-16-slim-approved-history-copilot.md; não se solicita a mesma autorização novamente.

Não foi localizada uma definição literal dos blocos 3/4 na documentação ou contexto recuperado. A decisão atual é concluir a próxima frente coesa do Copiloto e, após conferência, seguir para entrega/endereço/frete. Não se apresenta essa sequência como recuperação de uma lista ausente.

## 🟢 Teste real do bloco 2 localizado

O usuário moveu seu contato controlado e confirmou que o bot iniciou. Consulta somente leitura em 17/10 às 22:41 UTC:

- Evento moved 8832d2ea-0f2b-486a-8254-22de95099a63, criado às 22:33:11 UTC, status dispatched, uma tentativa, destino Em atendimento no funil Vendas.
- Job 77bf038c-7a37-4f19-bedb-1bc26f5135ef, vinculado ao mesmo evento e ao SalesBot Emprestimos ativa IA (7208c558-d4df-4591-b758-3864137d995a), status done, uma tentativa, concluído às 22:33:29 UTC.
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
