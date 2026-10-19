# Produtos do CSV no ERP

Pedido adicional do usuário: importar Produtos.csv, criar os catálogos e entregar os produtos completos junto com os bots corrigidos. Alvo: Saúde Slim independente ruanmeloandrade-alt/saude-slim, Supabase vyzvfcgpjjzvcjegzzza, workspace c49945db-1960-461a-9339-a43b8403bdd9. Publicação restauracao/sistema-completo-20261014.

Fonte C:/Users/User/Downloads/Produtos.csv, SHA-256 8d8b4530fe0faf898d2ee2f42b10ec903238342b4217744faf10026e652de71e, 78 linhas de produtos únicos. As 13 colunas serão preservadas. As categorias e códigos estão vazios na fonte. Unidade é unidade em todas as linhas. Há cinco estoques negativos e cinco estoques não informados. Não converter desconhecido em estoque zero confirmado nem apagar déficits. Preservar zeros de preço e de custo explícitos.

Não há produtos atuais nesta empresa; existe Catalogo principal. Organizar catálogos por linhas presentes nos nomes, sem atribuir dosagens, indicação clínica, imagens, fornecedores ou categorias não informados. Preservar o arquivo bruto e dados históricos de vendas/lucro como referência importada. Não criar vendas, pedidos, receitas ou movimentações retroativas.

Escopo necessário: campos próprios de custo, estoque mínimo, unidade e estoque conhecido; snapshot de origem; leitura e edição no cadastro; projeção de estoque tolerante a déficits e diferenciando valores não informados. Preservar checkout, pedidos, RLS e integrações. Importação transacional e idempotente com IDs determinísticos, sem sobrescrever registros preexistentes.

Status: concluído em produção em 2026-10-19. PR #4 integrado em c8ba20e04a7d304ee7d22bbacc542725e6346347. Railway b504020e-f6c7-470d-98fc-9c7fdde2bd04 SUCCESS às 17:32:26 UTC. Migração aditiva aplicada; depois do deploy, importação transacional executada com 78 produtos.

Conferência nativa: leitura de todos os 78 registros comparada ao manifesto, sem divergências; 13 colunas brutas e números normalizados preservados por produto. Sete catálogos: principal 44, TG 5, Tirzec 2, Lipoless 2, Retatrutida e Reta 11, Insumos 4, Landerlan 10. Cinco saldos negativos e cinco desconhecidos; total conhecido 451 unidades. Pedidos e movimentações permaneceram em zero. Valores zero explícitos da fonte preservados.

Validação: build completo PASS; 42 testes de estoque/recibo; quatro testes de parser; operação exata dos 78 registros em PGlite com reexecução idempotente e rollback por edição ou conflito de nome. Projeção do bundle compilado confirmou os totais e a leitura dos detalhes. Asset público efetivamente servido pelo domínio slimesaude.com retornou JavaScript HTTP 200 e contém histórico importado, custo e estoque não informado. Sem uso do Chrome nessa conclusão; não se trata de teste visual ou de disparo de automações.

