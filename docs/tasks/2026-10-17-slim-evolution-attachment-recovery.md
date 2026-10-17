# Saúde Slim | Recuperação segura de arquivos WhatsApp

Escopo 17/10/2026: Saúde Slim exclusivamente, projeto Supabase vyzvfcgpjjzvcjegzzza, branch restauracao/sistema-completo-20261014. O Inbox possui 27 atividades com referência WhatsApp e metadados de mídia, porém sem URL persistida. O fluxo legado recuperava mídia sem timeout, persistindo base64 potencialmente grande em lead_activities e whatsapp_web_messages.

Implementação: download Evolution somente ao clicar Abrir mídia, sem retry/restart, prazo máximo de 30 s e limite de arquivo 16 MB com leitura de resposta em streaming limitada; MIME sanitizado. Upload de arquivo recuperado ao bucket privado inbox-outgoing via cliente autenticado, sujeito à política slim_inbox_media_insert (operator/workspace), não via bypass service_role. A atividade registra apenas media_storage_path e MIME, não data URL. Link assinado refeito a cada clique, incluindo URLs antigas do Storage que venceram, após verificar lead/workspace. Mensagens e arquivos antigos preservados.

Validação requerida: chamadas sintéticas do provedor, abort, tamanho/MIME, re-sign de Storage com escopo, AST/patch idempotente, regressões e build. Não enviar WhatsApp real nem mover leads; não alterar outros projetos. Não repetir migrações previamente recusadas.
