# Saúde Slim: correção prioritária de histórico, anexos e gatilho de etapa

Estado: EM EXECUÇÃO. O usuário pediu tratar somente estas ocorrências antes de retomar as outras frentes: redundância do Histórico de Vendas; travamento percebido ao enviar PDF e áudio; gatilho SalesBot salvo no funil que não inicia ao mover lead; travamento ao navegar do funil ao Inbox.

Base confirmada 493d7f75393975afd939cc92ceb6182d1f3ae03e. Branch fix/slim-history-media-stage-hotfix-20261016, destino restauracao/sistema-completo-20261014. Exclusivamente repositório ruanmeloandrade-alt/saude-slim, Supabase vyzvfcgpjjzvcjegzzza e serviço saude-slim-web/Evolution próprio. Preservar as demais entregas. Sem mudança de DNS, infraestrutura, credenciais, outros projetos, Lovable ou GitHub Actions.

## Diagnóstico inicial verificado

Histórico: apply-slim-erp-release.mjs adiciona SlimErpWorkspace e mantém a página CRM inteira em details. Os hooks dessa página antiga continuam consultando dados mesmo recolhida. Resultado: títulos, filtros e históricos redundantes.

Gatilho: moveSlimLead no saude-slim-funnel-client.ts grava diretamente no Supabase e retorna backendPending:true e automations:[], sem encaminhar a movimentação ao motor de automações. O banco tem um gatilho salesbot ativo para created-or-moved e o bot de destino ativo; crm_automation_jobs não tem registros no momento da consulta. Precisamos conectar a movimentação ao enfileiramento persistente sem manter a navegação aguardando toda a execução do bot.

Mídia: sendLeadMedia faz preflight de conexão, reinicia automaticamente a instância e repete o envio após connection closed. As chamadas ao provedor não têm limite explícito de duração; decode usa Uint8Array.from(atob(...)) e lê a resposta inteira sem limite. O Inbox dispara polling em duplicidade, rotinas de sincronização e invalidações de mensagens. Investigar e corrigir esses caminhos sem afirmar que um PDF provocou queda do processo.

Operação: serviços online na inspeção; pico amostrado da memória web nas últimas quatro horas ~0,313 GB para limite de 8 GB e CPU máxima ~0,096. Logs registram várias requisições abortadas às 15:12 UTC; encerramento SIGTERM às 15:10 coincide com substituição de deploy, não comprova OOM. Evolution registrou timeout de webhook de 60000ms às 14:47 UTC. Essas evidências não confirmam a causa integral dos 15 minutos relatados.

## Entrega planejada

Uma única tela/lista de pedidos no histórico, sem apagar dados anteriores. Transporte de mídia limitado, sem reiniciar WhatsApp automaticamente nem reenviar tentativa incerta; leitura/decodificação segura e UI responsiva. Corrigir consultas repetidas/esperas evitáveis identificadas no Inbox. Conectar movimentação autorizada do lead ao enfileiramento e processamento no servidor, com erro visível e sem sucesso fictício.

## Critérios

Histórico possui uma única fonte operacional e um formulário de pesquisa. PDF e áudio não reiniciam a sessão nem prendem a aplicação em espera ilimitada. Erros distinguem falha anterior ao envio e resultado incerto, sem retry automático após contato com provedor. Gatilho salvo/enabled e evento de entrada compatível geram job; worker executa independente do navegador. Permissões, empresa, contato canônico, condição da etapa e centavos permanecem preservados.

Testes isolados de timeout, resposta lenta, upload, etapa/autorização/fila e componentes reais transformados; regressões anteriores e build completo; verificar publicação. Não enviar mensagens a clientes, executar bot real, mover lead real, criar venda, apagar arquivo ou reprocessar evento histórico para teste. Se não houver E2E autenticado, declarar limite exato. Atualizar o semáforo com o estado real e manter demais demandas pausadas nesta rodada.

## Rollback

Novos commits de reversão apenas para este bloco; sem force-push. Não apagar dados de pedidos, mensagens ou contatos. Não repetir pacotes de alteração de pedidos/segurança/índice de contatos anteriormente bloqueados por outro transporte.
