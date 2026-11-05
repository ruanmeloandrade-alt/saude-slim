# WhatsApp: falha de gravação no webhook

Corrigir confirmação indevida quando o Supabase recusa a gravação da mensagem. Cada falha é contada, recebe código de erro sem conteúdo da mensagem e impede o processamento daquele item. O webhook preserva o processamento dos demais itens e retorna erro se algum item falhar. Publicar e inspecionar o estado real sem reiniciar ou parear novamente a sessão.
