# Saúde Slim: aceite transacional isolado da regularização

Base: 53b3851. Branch fix/slim-legacy-acceptance-20261016. Destino operacional restauracao/sistema-completo-20261014. Exclusivamente Saúde Slim.

## Resultado obtido
Em 2026-10-16T10:18:02Z, o build a2a9f42c-8018-4ea2-9141-7445e37e71fb executou e aprovou 29/29 casos PostgreSQL isolados. O teste usa PGlite em memória, carrega as três migrations versionadas e verifica o SHA-256 de quatro corpos de funções contra metadados lidos do banco real. Não usa URL, chave, Supabase client ou dados do cliente.

Foram validados: quantidade numeric 3.000; 19,99 × 3 = 59,97; stock 10→7; snapshot compatível com o leitor real; repetição devolve um único pedido/baixa; pagamento pendente, centavo e zero; duas origens independentes; baixa ausente versus já contabilizada; cancelamento único; origem sem item, saldo insuficiente, quantidade fracionária, total divergente, origem arquivada, fingerprint alterado e parcelamento inválido; consentimento obrigatório; bloqueio de visualizador, vínculo expirado, usuário de outra empresa, anônimo e INSERT direto no ledger; preservação do snapshot após edição do catálogo/cancelamento; rollback dos dados sintéticos.

## Liberação delimitada
A readiness técnica muda para disponível após esse resultado, mantendo autenticação, identidade da empresa, papel de operador, aprovação explícita, dados de pagamento e declaração da situação do estoque. Nenhuma venda real é regularizada automaticamente. Os dois registros conhecidos com item precisam de informação de pagamento e confirmação de baixa pelo operador; o registro sem item não pode ser completado por suposição.

Corrigida também a projeção de estoque para stockMode=already_accounted: o registro reconhece a venda anterior sem exibir nova redução de saldo. O cancelamento continua mostrando apenas o estorno efetivo.

## Limites
Isso é um teste de integração PostgreSQL isolado com paridade de código, não a sonda produtiva que foi recusada anteriormente. Nenhuma operação recusada foi executada contra as tabelas do cliente via build. Não prova concorrência de duas conexões, todas as configurações Supabase ou navegador autenticado. A recusa anterior não é apagada nem transformada em PASS.

Dependência de teste fixa @electric-sql/pglite 0.5.10; sem alteração das versões de dependências já existentes. O teste roda antes da compilação a cada build. As verificações anteriores de bloqueio por readiness foram atualizadas para a nova condição de aceite, preservando os testes de aprovação e autorização. A publicação final ainda deve ser confirmada contra seu commit.

## Próxima frente
Envio opcional do PDF continua separado. Nenhum transporte de documento ou pacote anterior de segurança foi adicionado a este teste. Nova rodada de Inbox/Copiloto aguarda escopo/OK separado.