# Saúde Slim: IA de conversa individual por prompt

Estado: implementação independente em revisão/build, não homologada. Base 94d74b1, branch fix/slim-prompt-only-20261016. Somente repo ruanmeloandrade-alt/saude-slim, banco vyzvfcgpjjzvcjegzzza. A integração bloqueada da ficha do Funil NÃO faz parte deste código; ela permanece WIP em fix/slim-funnel-prompt-20261016, commit d6d84a5, sem publicar.

## Mudança solicitada

Retirar fluxo de objetivos dos agentes individuais, mantendo prompt, fontes, ações configuradas, dados e histórico. Criar agente abre modelos de prompt diretamente. A tela antiga de árvore não é montada. Agente antigo com modo objetivos exibe aviso de revisão; o primeiro salvamento precisa ser manual e ter prompt preenchido. Nenhum prompt é inventado e nenhuma árvore é transformada automaticamente em comandos.

O salvamento só aceita modo prompt, mantém metadata e settings anteriores num merge por nível, retém objective_tree apenas como arquivo histórico. A atualização é verificada por ID/empresa e operador. Não devolve sucesso quando nenhuma linha foi atualizada.

O carregador efetivo de conversation_ai_agents retira objective_tree da cópia usada na execução. Essa mesma cópia abastece turno de IA e rotinas de tracking/inatividade; o fluxo arquivado não fornece ações, encerramentos ou timers para essas rotinas. Prompt vazio é rejeitado antes da chamada ao provedor ou do transporte WhatsApp. A API de teste individual segue o contrato de prompt. Grupo/central de grupos tem configuração própria e não está sendo declarado migrado nesta entrega.

## Preservação e limites

Não apagar árvores nem históricos. Não alterar definições de SalesBots convencionais, estoque, pedidos, chaves, DNS ou infraestrutura. Nenhuma migração no banco. Consulta de metadados do banco foi bloqueada nesta sessão, sem resultados: não inventar quantos agentes antigos existem ou precisam de revisão.

22 testes puros executados localmente antes do envio ao GitHub. Gates de sintaxe, consumidores e regressões preservados no build. Só marcar publicado após build/deploy bem-sucedidos; não chamar testes de fonte de E2E autenticado ou resposta real da IA. Rollback por novos commits dos arquivos desta frente.
