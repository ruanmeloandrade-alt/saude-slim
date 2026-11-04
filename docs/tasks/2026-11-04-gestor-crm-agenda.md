# Gestor do CRM por funil

A versão em produção salva regras e oferece prévia individual. Esta frente completa a varredura por funil e a configuração de execução.

- Cada funil tem sua agenda com ativação, dias, horário e fuso, além de execução manual do funil inteiro.
- O prompt orienta a interpretação do histórico. O backend valida as permissões e os destinos selecionados no editor, incluindo bots e agentes explicitamente habilitados.
- O trabalho roda no servidor, com fila paginada, progresso, trilha de auditoria e proteção contra execução concorrente. O cron existente é o ponto de integração.
- Casos claros seguem a ação aprovada; dúvidas vão à revisão. Silêncio não encerra uma venda. Movimento comum não dispara bot implicitamente.
- Aceite: testar agenda em dias distintos, funis isolados, recuperação após interrupção, duplicação de gatilhos, mudanças concorrentes no histórico e varredura maior que uma página. Validar publicação e interface autenticada antes de liberar a rotina.
- Fora do escopo: integração WhatsApp e configuração dos agentes de atendimento.

## Estado

Branch isolada a partir de 4a410ab. O rascunho anterior executava a varredura no navegador com a lista do quadro, sem agenda nem retomada. A versão publicada não expõe escrita do Gestor. Nenhuma execução iniciada em produção nesta checagem.

Implementação desta etapa: perfis múltiplos por funil, clique esquerdo para enfileirar o padrão e clique direito para gerenciar perfis, selecionar etapas e definir agenda. A produção não tem pg_cron instalado; execução usa o mesmo padrão de worker persistente já empregado pelo Inbox no servidor Railway. Agenda usa horário de Brasília. SQL validado no PostgreSQL local para isolamento, lease, bot/agente ativos, movimento único e auditoria. Agenda validada com quatro casos. Fila criada em produção pelo Editor SQL após o conector negar acesso. Ativação de bots/agentes pelo Gestor continua fora desta publicação.
