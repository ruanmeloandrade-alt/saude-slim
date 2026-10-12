# Configurações — troca imediata do e-mail de acesso

Status: 🟢 VERDE TÉCNICO / PRONTA PARA INTEGRAÇÃO

## Objetivo
Adicionar em `/configuracoes` uma opção para o próprio usuário autenticado trocar o e-mail usado no login da MKTOn.

## Requisitos do owner
- Não alterar nem remover funcionalidades existentes da plataforma.
- A opção deve existir somente no contexto autenticado de Configurações.
- Ao salvar, o novo e-mail substitui o anterior como e-mail de acesso da mesma conta.
- A alteração precisa ser persistida no Supabase Auth; não pode ser estado local do navegador.
- Não exigir nem enviar código/link de confirmação para concluir a troca.
- A senha atual e os demais dados/vínculos do usuário permanecem intactos.

## Decisões técnicas
- GitHub `main` continua sendo a fonte de verdade; implementação em branch/PR.
- Não usar Lovable para programação, prompt ou alteração do projeto.
- Não executar nenhuma ação no projeto Supabase legado `xmoiyffwmolwmjzeuqjf` disponível no conector desta sessão. O projeto canônico registrado no repositório é `wqriaxzymngkntccljjp`.
- Não alterar configuração global do Auth para desativar confirmações. A mudança é pontual, autenticada e executada no servidor com o cliente administrativo já existente.
- Usar `auth.admin.updateUserById` para alterar diretamente o e-mail do `context.userId`; a documentação atual do Supabase define que mudanças administrativas são aplicadas sem confirmation flow.
- Nunca expor `SUPABASE_SERVICE_ROLE_KEY` ao cliente.
- Não abrir a aba Segurança hoje restrita a super admin. A nova opção é adicionada à superfície de Configurações de forma independente, preservando as permissões atuais.
- Após sucesso, solicitar `supabase.auth.refreshSession()` no cliente para sincronizar os claims da sessão com o novo e-mail.
- A leitura do usuário atual no servidor usa `supabaseAdmin.auth.admin.getUserById(context.userId)`, porque o cliente criado pelo middleware não persiste sessão em storage. O navegador lê o e-mail atual de `supabase.auth.getSession()`.

## Segurança e integridade
- O servidor deriva o usuário exclusivamente da sessão autenticada (`requireSupabaseAuth`); o cliente não envia `userId`.
- Normalizar e validar o novo e-mail no servidor.
- Rejeitar e-mail vazio, inválido, igual ao atual ou já utilizado por outra conta.
- Alterar apenas o registro Auth do mesmo `userId`; não recriar usuário, workspace, memberships, perfil, senha, MFA ou permissões.
- Não registrar o e-mail completo em logs de aplicação.

## Implementação
- `src/lib/account-email.core.ts`: normalização, comparação e tradução segura de erros.
- `src/lib/account-email.functions.ts`: função autenticada de troca imediata no Supabase Auth.
- `src/components/settings/AccountEmailChangeControl.tsx`: UI `Trocar e-mail`, e-mail atual, novo e-mail e salvar.
- `src/routes/configuracoes.tsx`: montagem da nova ação sem alterar a implementação legada existente.
- `src/lib/account-email.core.test.ts`: cobertura do núcleo de validação.
- `.github/workflows/settings-account-ci.yml`: CI seletivo apenas para esta superfície.

## Critérios de aceite
- Usuário autenticado abre Configurações e encontra a ação `Trocar e-mail`.
- A tela mostra o e-mail de acesso atual e aceita um novo e-mail válido.
- `Salvar novo e-mail` executa a função de servidor autenticada.
- O novo e-mail fica confirmado e ativo imediatamente sem OTP/link de confirmação.
- O e-mail antigo deixa de autenticar aquela conta e o novo passa a ser o login da mesma identidade Supabase.
- A sessão atual é atualizada após a gravação, sem perder dados da conta.
- Erro de e-mail já cadastrado é tratado sem modificar a conta.
- Nenhuma outra área de Configurações sofre alteração funcional.

## Validação executada
- PR #208 comparada com a `main` atual: branch criada sobre o HEAD atual e diff restrito ao escopo.
- Revisão estrutural confirmou que nenhuma tela legada de Configurações, login, senha, WhatsApp, CRM ou migration foi reescrita.
- Documentação oficial atual do Supabase conferida: `auth.admin.updateUserById` aplica alteração administrativa diretamente, sem confirmation flow, e aceita `email_confirm`.
- Validação TypeScript direta das superfícies novas com TypeScript 5.8.3 e contratos mínimos equivalentes: PASS após correção do acesso ao usuário atual no servidor.
- Assertions diretas do núcleo de e-mail: normalização, comparação case-insensitive e tradução de erros de duplicidade/e-mail inválido: PASS.
- GitHub Actions `Settings Account CI` foi disparado novamente após a correção, porém o runner não iniciou nenhum step (`steps: []`, `runner_id: 0`). Registrar como **CI externo indisponível**, não como falha de código.
- O ambiente local desta sessão não consegue clonar o repositório privado para executar o build integral; a ausência desse build local não foi registrada como PASS.
- Não foi feita troca destrutiva em conta real de cliente apenas para teste, pois não há usuário de teste explicitamente destinado a isso nesta execução.

## Estado de integração
- Branch: `feat/settings-email-change`.
- PR: `#208`.
- Verde técnico por validação direta; CI externo indisponível por runner que não iniciou.
