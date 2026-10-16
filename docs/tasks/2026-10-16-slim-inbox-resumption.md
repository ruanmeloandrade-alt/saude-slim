# Retomada Saúde Slim em 16/10/2026

Status: EM EXECUÇÃO, sem aprovação adicional pendente do usuário para o escopo já solicitado. Último commit confirmado na retomada: 36f45852977c68722bc0f3a861815cd30e54bf6f.

## Ambiente e limites

Somente ruanmeloandrade-alt/saude-slim; Supabase vyzvfcgpjjzvcjegzzza. Continuar a branch de correção existente e a branch operacional restauracao/sistema-completo-20261014. Não alterar DNS, infraestrutura, chaves, outros projetos, Lovable ou GitHub Actions.

A chamada apply_migration para slim_order_reviewed_edit_delete foi bloqueada pela ferramenta. A migração NÃO está instalada; não tentar contornar o bloqueio por outro endpoint ou transporte. Não ativar botões de edição/exclusão dependentes dela e não declarar essa frente concluída.

## Evidências da retomada

Build Railway d00ec90a-0216-412a-9a9c-495d78ef64f4 falhou: chave JSX extra gerada por apply-slim-global-history.mjs em SlimErpWorkspace.tsx. Corrigir a transformação e acrescentar checagem sintática antes de novo build. Os 28 testes SQL isolados passaram, mas isso não é deploy nem E2E autenticado.

Diagnóstico anterior confirmado por leitura: faltam inbox_labels, inbox_label_assignments, whatsapp_groups e bucket inbox-outgoing no banco independente. Composer desabilita escrita enquanto sendMut está pendente; gravação assume audio/webm; criação de etiqueta limpa campo antes da resposta; mídia ainda usa telefone em lugar do roteamento canônico usado por texto.

## Entrega deste bloco

1. Corrigir build da entrega anterior sem desfazer a lista/Pesquisar/Copiloto global.
2. Corrigir composer contínuo, retirar formulário, separar áudio de ditado para texto, preservar rascunhos e mostrar falhas de mídia.
3. Restaurar dependências próprias de etiquetas, grupos e mídia com RLS e sem enviar mensagens de teste a clientes. Migração do Inbox é independente da migração de pedidos bloqueada.
4. Corrigir leitura dos indicadores conforme mensagem lida/não lida e estados reais de Bot/IA.
5. Continuar identidade Cliente/Inbox e drawer do Funil e retirar fluxo de objetivos, conforme viabilidade e evidência.

## Validação

Checagens de sintaxe dos arquivos transformados, testes focados de estados e gravação, regressão dos contratos existentes, build e status pós-deploy. Não confundir teste sintético, simulação, HTTP ou build com uso autenticado, entrega ao WhatsApp ou recuperação de mensagens históricas. Não fazer pedidos, editar vendas nem acionar bots de clientes durante testes.

## Rollback

Novos commits de reversão apenas para os arquivos desta frente; sem force-push. Preservar pedidos, mensagens, documentos e rastreabilidade. Ao encerrar registrar exatamente entregue, bloqueado e pendente.
