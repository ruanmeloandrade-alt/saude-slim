# Tracking simples da Saúde Slim

Pedido: substituir o tracking grande por reconhecimento do código no início da mensagem, aplicação da tag Meta e encaminhamento ao bot Pré-atendimento. Sem campos UTM adicionais nem encerramento sem encaminhamento. Também encaminhar ao Pré-atendimento quando não houver código Meta.

Alterar somente o grafo do SalesBot existente bde1f325-76fa-efd9-d055-ad093a4b9b0a, workspace c49945db-1960-461a-9339-a43b8403bdd9, Supabase vyzvfcgpjjzvcjegzzza. Snapshot atual: 83 blocos, revisão 6. O usuário ativou o tracking e o Pré-atendimento; preservar os estados e os gatilhos atuais. Não executar atendimento ou enviar mensagens de teste. Cópia anterior em work/tracking-before-simple.json, fora do repositório.

Aceite: três blocos nativos, uma condição com os códigos originais, uma ação de tag 🎯META ADS e um bloco Iniciar SalesBot apontando ao Pré-atendimento. Código C1 não corresponde a C10/C100. A saída sem código também segue ao atendimento, sem tag Meta. Conferir persistência e editor real após a operação. Nenhuma mudança de runtime ou novo deploy web necessária.

Concluído: RPC nativo salesbot_save_graph_v2 aplicado na revisão 6, gerando revisão 7 e removendo 80 blocos excedentes. Persistência confirmada com três blocos; estados ativos e gatilhos preservados. Pré-atendimento permanece na revisão 3 com 30 blocos. Nenhuma execução de SalesBot criada.

Validação: node scripts/test-slim-tracking-simple.mjs passou em 61 entradas, incluindo os 13 códigos originais, limites C1/C10/C100 e ausência de código. Ambos os caminhos chegam ao bot Pré-atendimento. Conferência visual no editor confirmou condição, tag 🎯META ADS e destino selecionado. Sem teste com contatos reais ou disparos.

Arquivos: scripts/fixtures/slim-tracking-simple.json (grafo), scripts/operations/slim-tracking-simple-20261019.sql (operação com controle de revisão), scripts/test-slim-tracking-simple.mjs (validação) e este registro. Nenhum código de runtime alterado; não exige deploy web.
