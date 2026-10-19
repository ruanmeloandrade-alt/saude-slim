# Bots legíveis: regras simples e organização em fluxograma

Alvo confirmado: repositório independente ruanmeloandrade-alt/saude-slim, branch de publicação restauracao/sistema-completo-20261014, serviço Railway saude-slim-web. As referências herdadas a code-to-lovely-ui no AGENTS.md não mudam o alvo Saúde Slim expressamente solicitado nesta tarefa.

Pedido: retirar expressões regulares dos 19 SalesBots existentes e espaçar os blocos em fluxogramas legíveis. Preservar mensagens, ações, destinos, finalizações, estados de ativação e gatilhos. Não enviar mensagens nem executar bots.

Implementação: regras de igualdade e listas de frases em texto literal, com o mesmo matcher no executor real e no simulador. Editor mostra uma palavra/frase por linha em área de rolagem limitada, sem multiplicar os blocos. Igualdade exata preserva autorização versus recusa; resposta de encerramento compara a mensagem inteira e aceita pontuação final. A opção antiga continua compatível com grafos externos, mas os 19 bots desta empresa ficam sem regras regex.

Organização: sequência da esquerda para a direita, níveis por dependência, colunas com 260 px livres entre cartões e pelo menos 180 px entre cartões empilhados, considerando a altura de cada editor. IDs, tipos e conexões originais preservados; somente regras e posições mudam. Início alinhado ao primeiro bloco. Backup integral em scripts/fixtures/slim-all-bots-before-readable.json.

Validação direta:
- node --experimental-strip-types scripts/test-slim-all-bots-readable.mjs: PASS; 19 bots, 562 blocos, 294 regras convertidas, 16.126 comparações e 9.172 pares de retângulos sem sobreposição estimada.
- node scripts/test-slim-all-bots-postgres.mjs: PASS; RPC real copiado do projeto e executado em PGlite; aplicação de 19 grafos, preservação de flags/gatilhos e rollback integral por revisão obsoleta ou conflito no meio.
- npm run build: PASS, exit 0; preflight, regressões de release e bundles cliente/SSR/Nitro concluídos. Avisos preexistentes de depreciação e bundler não impediram a compilação. Fontes geradas pelo prebuild removidas do diff depois da validação, mantendo apenas os quatro consumidores alterados e o matcher novo.

Publicação: pendente da compilação, entrega da atualização do editor/executor e aplicação transacional no Supabase com controle de revisão de todos os 19 bots. A aplicação deve ocorrer depois da publicação do executor para que nenhuma regra nova seja interpretada por uma versão antiga.

Sem dependências novas, chaves, alterações de integrações, alterações de pipeline ou disparos. Arquivos modificados pelo prebuild são artefatos gerados; não pertencem ao diff entregue.
