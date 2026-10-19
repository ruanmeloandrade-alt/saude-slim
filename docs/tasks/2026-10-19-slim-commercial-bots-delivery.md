# Saúde Slim | Conclusão dos bots comerciais e revisão do Cérebro

## Escopo autorizado

Entregar a configuração dos SalesBots baseada nos oito modelos Kommo recebidos, preservar os dois agentes Ana Júlia e as palavras proibidas, e conferir a edição/visualização de fontes e termos. Exclusivo à Saúde Slim, workspace c49945db-1960-461a-9339-a43b8403bdd9, Supabase vyzvfcgpjjzvcjegzzza.

Última instrução do usuário: criar os bots completos para que ele escolha onde entram e os ative. Todos os bots e agentes permanecem desligados, gatilhos vazios e nenhuma automação de etapa criada. Não executar conversas, testes com destinatários, campanhas nem mudar leads. Não alterar outros projetos ou código do app web em andamento pelo Codex.

## Base conferida

Produção GitHub 4f00863d9ead7a0de4aab182916d42304b4c4e3b. A edição de fontes e palavras já está implementada em BrainSourceEditors.tsx e integrada por apply-slim-brain-editor.mjs. Não duplicar essa correção. Banco consultado: quatro funis, dois agentes desativados, 26 expressões bloqueadas, campos operacionais existentes; catálogo de SalesBots ainda vazio na primeira leitura.

## Regras de adaptação

- Rastreamento silencioso identifica o token completo no início da mensagem, inclusive quando seguido da saudação. Manter os treze códigos genéricos do modelo, distinguindo C1 de C10. Usar campos de origem/UTM, nunca lead.price. Não enviar evento para a página Meta da operação usada como exemplo.
- Pré-atendimento: conhecer mais leva à qualificação inicial; preço/compra/pedido explícito de humano seguem ao atendimento humano.
- Resposta a retomada interrompe a cadência e passa pela Ana Júlia de qualificação curta, com exceção de descadastro, pedido de humano ou assistência de saúde.
- Pós-venda com agradecimento e onboarding único; recompra/acompanhamento depende de dados confirmados pelo operador, não de uma estimativa clínica do bot.
- Informações, documentos, links, preços, promoções e arquivos oficiais serão preenchidos pelo usuário. Não copiar URLs opacas, anexos ausentes, marcas/benefícios de terceiros, promessas de resultado nem orientação universal de dose dos modelos. Registrar essas adaptações e material pendente, sem apresentar anexo ausente como enviado.
- Layout em blocos por fase, com ramos claros, notas internas fora das mensagens e validação de todos os destinos.

## Validação e entrega

Conferir schema real do Builder/runtime, validar os grafos e a correspondência dos IDs antes da persistência, gravar somente novos bots no workspace autorizado e consultar o resultado independentemente. Registrar nomes, contagens, ligações bot/IA, ausência de gatilhos/execuções e limites operacionais. Preservar identidade, perfil, fonte e segurança existentes. Os registros de configuração não comprovam envio real. Não declarar conferência autenticada de tela sem navegador disponível.

Status inicial: em execução. Esta branch é operacional/documental e não exige novo deployment do produto.
