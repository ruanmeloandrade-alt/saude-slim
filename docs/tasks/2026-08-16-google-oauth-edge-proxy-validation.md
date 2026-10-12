# Google OAuth proxy — validação

- Revisão estática: fluxo `start -> Google -> callback -> exchange -> persistência` preserva o callback público já cadastrado no Google Cloud.
- Segurança: Client Secret permanece exclusivamente em Edge Function; GET público não retorna segredo; POSTs sensíveis exigem service role.
- Banco operacional: nenhum `provider = google` existia antes do smoke; integração só pode ficar verde após `refresh_token` real persistido.
- Validação de produção pendente porque a nova Edge Function ainda precisa ser publicada no projeto operacional Lovable Cloud.
