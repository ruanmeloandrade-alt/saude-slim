# Google OAuth — smoke pós-publicação

Status: **PENDENTE DE PUBLICAÇÃO**

1. Abrir `Integrações > Google Central`.
2. Confirmar `Conectar Conta Google` habilitado.
3. Clicar e confirmar redirecionamento para `accounts.google.com`.
4. Selecionar conta Google de teste do owner.
5. Aceitar os scopes solicitados.
6. Confirmar callback em `https://mkton.io/api/public/oauth/google/callback`.
7. Confirmar retorno à MKTOn com integração `google` conectada.
8. Confirmar persistência de `refresh_token` via vault e workspace correto.
9. Executar discovery mínimo por produto antes de marcar Google como verde.
