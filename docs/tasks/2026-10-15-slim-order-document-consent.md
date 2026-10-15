# Saúde Slim: documento do pedido e conferência histórica

Estado: em implementação. Base cb9869f, código funcional anterior bf04b2a. Somente ruanmeloandrade-alt/saude-slim, branch operacional restauracao/sistema-completo-20261014, Supabase vyzvfcgpjjzvcjegzzza. Trabalho fix/slim-erp-document-consent-20261015.

## Recorte autorizado

Concluir o envio opcional do PDF comercial associado ao pedido. Exibir cliente, número, documento e canal antes de qualquer envio. Preservar os novos pedidos, o download já publicado, histórico/estoque e salvamento manual/120s dos bots. Conferir registros anteriores sem refazer vendas ou ajustar estoque sem evidência.

## Revisão de implementação

O pacote anterior de transporte privilegiado não será reapresentado nem repartido. A implementação revisada usa exclusivamente a sessão autenticada do operador; não importa supabaseAdmin, não muda permissões globais e não grava documentos/estados por acesso direto irrestrito. Novas funções específicas de banco verificam empresa, operador, pedido, hash do PDF, telefone atual, canal conectado e aprovação explícita; reservam a tentativa antes de permitir a chamada externa. O arquivo sempre é regenerado no servidor a partir do snapshot e comparado com o hash aprovado. Nenhum URL ou arquivo externo indicado pelo cliente é aceito.

O transporte somente usa a credencial da sessão WhatsApp já pertencente à mesma empresa, pelo RPC autenticado existente. Nenhum segredo será lido pela auditoria, logado ou devolvido ao navegador. Tentativas repetidas/ambíguas consultam o resultado já reservado e não reenviam automaticamente. PDF comercial não será rotulado como nota fiscal autorizada.

## Histórico antigo

Consulta atual: duas compras com item/preço/quantidade registrados (8,50 e 7,39) e um registro de 101 sem item. Não inferir forma de pagamento, cliente canônico nem movimento manual de estoque. Preparar conferência rastreável dos dados e exibir inconsistências sem criar outra venda. A conciliação persistida depende de dados suficientes para cada registro.

## Aceite

Cadastro de documento único por pedido e hash validado; uma tentativa aprovada por vez; consulta de repetição não executa transporte; troca de empresa/telefone/arquivo/canal invalida aprovação; cancelado e opt-out impedem envio; falha de rede não vira sucesso ou repetição. Interfaces do checkout e histórico compartilham a mesma confirmação. Sondas de banco revertidas e testes locais sem mensagens a clientes. Build e publicação verificados antes de afirmar que entrou no site.

A nova rodada de Copiloto global, Inbox, áudio, etiquetas, grupos, mini-Inbox, endereço/frete e IA por prompt permanece sem iniciar. Atualizar docs/OPERATION_STATUS.md com resultados reais deste recorte e pendências.
