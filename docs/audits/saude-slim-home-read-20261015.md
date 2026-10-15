# Saúde Slim: Home, histórico de vendas

Continuidade após a correção do cofre IA a81b6e0. O diagnóstico estrutural dos 16 itens do menu foi executado em produção durante o build da auditoria: 444 arquivos inspecionados, nenhuma rota operacional ausente. Isso não constitui homologação funcional integral.

## Bugs reproduzidos no código

1. getSaudeSlimSalesHistory e getSaudeSlimSalesProducts limitavam silenciosamente leituras a mil registros. A paginação da tabela operava sobre uma base já cortada.
2. statusOf avaliava um nome de etapa como ganho antes de respeitar lead.status='lost'. Uma venda explicitamente perdida podia aparecer ganha.

## Correção

Leituras paginadas de leads, etapas, funis, vínculos de compra e produtos. Ordenação estável por ID durante a coleta e retorno dos leads pela atualização mais recente. A próxima página começa após o número efetivamente recebido, mesmo se o servidor limitar cada resposta abaixo do tamanho solicitado. Falha de qualquer página não apresenta um histórico parcial como completo. Limite de segurança explícito evita loop ilimitado.

Resultado explícito won/lost tem precedência sobre o nome da etapa. A inferência legada por etapa foi mantida apenas para leads sem resultado explícito. Interface, filtros, campos e semântica de valor foram preservados. Não foram modificadas chaves, dependências, conexão WhatsApp nem o contrato de salvamento de bots.

## Validação

Sete regressões passaram localmente em Node 22.16: mais de mil registros; limite de página inferior no servidor; erro na segunda página; vazio versus resposta inválida; limite de segurança; resultado perdido/ganho explícito; inferência por etapa. São testes controlados do código real, sem inserir dados fictícios no banco. Os mesmos testes foram adicionados ao prebuild. Conferir deploy antes de declarar publicado.

## Próximo ponto do escopo

Dashboard detalhada (/painel). A auditoria encontrou dependências ausentes nesse painel e em Públicos/Disparo, Automações e Configurações. Pedidos/Fornecedores/Produtos/Estoque possuem as tabelas examinadas, mas presença não prova a operação integral. Há limitações herdadas no modelo de pedidos: vínculo único lead/produto/kind impede tratar compras repetidas como pedidos independentes; não foi alterado silenciosamente nesta correção de leitura.

A resposta real da OpenAI permanece dependente do cadastramento da chave pelo operador, pois a tentativa anterior não a persistiu. Não houve envio a clientes nem declaração de homologação WhatsApp IA.
