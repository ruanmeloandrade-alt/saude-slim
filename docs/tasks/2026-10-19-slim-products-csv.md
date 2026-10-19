# Produtos do CSV no ERP

Pedido adicional do usuário: importar Produtos.csv, criar os catálogos e entregar os produtos completos junto com os bots corrigidos. Alvo: Saúde Slim independente ruanmeloandrade-alt/saude-slim, Supabase vyzvfcgpjjzvcjegzzza, workspace c49945db-1960-461a-9339-a43b8403bdd9. Publicação restauracao/sistema-completo-20261014.

Fonte C:/Users/User/Downloads/Produtos.csv, SHA-256 8d8b4530fe0faf898d2ee2f42b10ec903238342b4217744faf10026e652de71e, 78 linhas de produtos únicos. As 13 colunas serão preservadas. As categorias e códigos estão vazios na fonte. Unidade é unidade em todas as linhas. Há cinco estoques negativos e cinco estoques não informados. Não converter desconhecido em estoque zero confirmado nem apagar déficits. Preservar zeros de preço e de custo explícitos.

Não há produtos atuais nesta empresa; existe Catalogo principal. Organizar catálogos por linhas presentes nos nomes, sem atribuir dosagens, indicação clínica, imagens, fornecedores ou categorias não informados. Preservar o arquivo bruto e dados históricos de vendas/lucro como referência importada. Não criar vendas, pedidos, receitas ou movimentações retroativas.

Escopo necessário: campos próprios de custo, estoque mínimo, unidade e estoque conhecido; snapshot de origem; leitura e edição no cadastro; projeção de estoque tolerante a déficits e diferenciando valores não informados. Preservar checkout, pedidos, RLS e integrações. Importação transacional e idempotente com IDs determinísticos, sem sobrescrever registros preexistentes.

Status: em execução. A importação só entra depois da atualização dos consumidores de estoque para não deixar o ERP indisponível por saldo negativo.

