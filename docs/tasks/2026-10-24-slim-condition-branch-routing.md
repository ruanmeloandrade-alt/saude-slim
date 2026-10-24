# Condicional OU: saídas independentes

Relato acrescentado ao escopo enquanto a publicação dos campos personalizados (PR #12, commit 1bbb9cc) está em andamento. Ordem pedida pelo usuário: concluir a entrega corrente antes de executar o próximo ajuste; novos relatos devem ser acumulados, sem abandonar tarefas abertas.

Diagnóstico no código: computeFlow usa c.nextBlockId ?? b.nextBlockId para desenhar cada saída OU. disconnectSource remove apenas c.nextBlockId e o destino comum volta imediatamente. Runtime usa o mesmo fallback. Logo o cabo herdado não se solta. OU com apenas uma regra também usa o caminho comum, ignorando a saída da regra.

Próximo ajuste: permitir desconectar/reconectar cada regra, preservar os destinos das outras regras e o senão, validar persistência/reabertura e execução. Preservar condições E e os fluxos existentes. Sem Chrome/mouse e sem disparar bots reais em QA.

Implementação: ao desconectar uma regra OU, materializa os destinos herdados das outras regras e remove o destino comum, liberando apenas o cabo escolhido. OU usa saídas individuais mesmo com uma única regra restante, tanto no editor como no executor. Destinos E e senão preservados.

Validação: scripts/test-slim-condition-branches.mjs PASS executando funções reais do editor (desconectar, reconectar, desenho das portas) e o case real do executor com avaliação de condições. Cobre herança legada, caminhos distintos, desconexão persistente, uma regra OU e E/senão. Contrato de salvamento 8/8 PASS. npm run build completo PASS. Publicação da correção corrente de campos continua pending na Railway; esta entrega ainda não foi declarada em produção.

## Escopo acrescentado: auditoria dos blocos

Depois da condicional, ocultar Enviar DM e Comentário (redes sociais fora do escopo atual). Verificar mensagem, reação, mensagem interna e seu destino, todas as modalidades/limites das pausas, opções de Ação, Validação, Outra etapa, Iniciar bot, Agente IA, Distribuição e Encerrar bot. Usuário exige testes reais, sem Chrome. Usar dados de QA separados; não disparar mensagens a clientes. Número de WhatsApp próprio solicitado para validação de envio externo. Relatar funcionamento comprovado, defeitos e itens ainda não validados separadamente.
